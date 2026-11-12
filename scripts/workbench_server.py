#!/usr/bin/env python3
"""Loopback-only HTTP supervisor. Chemistry/schema validation always runs in Julia."""
import argparse, hashlib, io, json, mimetypes, os, re, secrets, signal, subprocess, threading, time, tomllib, uuid, zipfile
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit, unquote
ROOT=Path(__file__).resolve().parents[1]
MAX_BODY=131072
TERMINAL={'completed','failed','cancelled','timed_out'}

def toml_text(d):
    def key(k):return json.dumps(k,ensure_ascii=False)
    def val(v):
        if isinstance(v,str):return json.dumps(v,ensure_ascii=False)
        if isinstance(v,bool):return str(v).lower()
        if isinstance(v,(float,int)) and not isinstance(v,bool):
            import math
            if not math.isfinite(v):raise ValueError('Nonfinite number')
            return repr(v)
        if isinstance(v,list) and not any(isinstance(x,dict) for x in v):return '['+', '.join(val(x) for x in v)+']'
        raise ValueError('Unsupported TOML value; unknown/null values cannot become chemical defaults')
    lines=[]
    def walk(obj,prefix=(),header=None):
        if header:lines.append(header)
        for k,v in obj.items():
            if not isinstance(v,dict) and not (isinstance(v,list) and v and isinstance(v[0],dict)):lines.append(key(k)+' = '+val(v))
        for k,v in obj.items():
            p=prefix+(k,);name='.'.join(map(key,p))
            if isinstance(v,dict):walk(v,p,'['+name+']')
            elif isinstance(v,list) and v and isinstance(v[0],dict):
                for x in v:walk(x,p,'[['+name+']]')
    if not isinstance(d,dict):raise ValueError('study must be an object')
    walk(d);return '\n'.join(lines)+'\n'

class Service:
    def __init__(self,julia,root):
        self.julia=julia;self.root=Path(root).resolve();self.root.mkdir(parents=True,exist_ok=True)
        self.jobs={};self.lock=threading.RLock();self.token=secrets.token_urlsafe(32)
        self.env=os.environ.copy();self.env['JULIA_NUM_THREADS']='1'
        self.engine=self.env.get('PHREEQC_EXECUTABLE');self.database=self.env.get('PHREEQC_DATABASE')
    def command(self,mode,inp,out):return [self.julia,'--startup-file=no','--project='+str(ROOT),str(ROOT/'scripts/workbench_worker.jl'),mode,str(inp),str(out)]
    def validate(self,study=None,text=None):
        if not self.lock.acquire(blocking=False):raise ValueError('Service busy; retry after active request')
        try:
            # Limit concurrently launched validation processes; all request data stay in scoped job storage.
            active=sum(j['status'] not in TERMINAL for j in self.jobs.values())
            if active:raise ValueError('A job is active; wait or cancel before validating another study')
            if text is not None:
                if not isinstance(text,str):raise ValueError('toml must be text')
                study=tomllib.loads(text)
            text=toml_text(study)
            if len(text.encode())>MAX_BODY:raise ValueError('Configuration too large')
            if len(json.dumps(study))>MAX_BODY:raise ValueError('Configuration too large')
            # Fail obvious recursive payload attacks before spawning Julia.
            def depth(v,n=0):
                if n>10:raise ValueError('Configuration nesting exceeds limit')
                if isinstance(v,dict):
                    if len(v)>100:raise ValueError('Too many configuration fields')
                    for k,x in v.items():
                        if k in ('executable','database','shell','command','engine_path','active_phases'):raise ValueError('Unsupported trusted-path or phase-activation field')
                        depth(x,n+1)
                if isinstance(v,list):
                    if len(v)>100:raise ValueError('Too many configuration items')
                    for x in v:depth(x,n+1)
            depth(study)
            import tempfile
            with tempfile.TemporaryDirectory(dir=self.root,prefix='validate-') as td:
                inp=Path(td)/'study.toml';out=Path(td)/'validation.json';inp.write_text(text)
                p=subprocess.run(self.command('validate',inp,out),env=self.env,capture_output=True,timeout=45)
                if not out.exists():raise ValueError('Julia validation failed: '+p.stderr.decode(errors='replace')[-1200:])
                result=json.loads(out.read_text())
                if p.returncode or 'error' in result:raise ValueError(result.get('error',{}).get('message','Validation failed'))
                return result,text
        finally:self.lock.release()
    def start(self,study,key):
        with self.lock:
            for j in self.jobs.values():
                if j['request_id']==key:return self.public(j)
            if len(self.jobs)>=100:raise ValueError('Session job limit reached; restart service after saving archives')
            result,text=self.validate(study)
            ident=uuid.uuid4().hex;directory=self.root/ident;directory.mkdir()
            (directory/'study.toml').write_text(text)
            j=dict(id=ident,request_id=key,status='queued',completed=0,total=result['candidate_count'],error=None,created=time.time(),directory=directory,cancel=False)
            self.jobs[ident]=j
            threading.Thread(target=self.run,args=(j,),daemon=True).start();return self.public(j)
    def run(self,j):
        try:
            with self.lock:
                if j['cancel']:j['status']='cancelled';return
                j['status']='running';log=(j['directory']/'worker.log').open('wb')
                p=subprocess.Popen(self.command('run',j['directory']/'study.toml',j['directory']/'result.json'),env=self.env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True);j['process']=p
            try:p.wait(timeout=1800)
            except subprocess.TimeoutExpired:
                os.killpg(p.pid,signal.SIGTERM);p.wait(timeout=10);j['status']='timed_out';j['error']='30 minute job limit exceeded'
            log.close()
            with self.lock:
                if j['cancel']:j['status']='cancelled'
                elif j['status']!='timed_out':
                    out=j['directory']/'result.json';result=json.loads(out.read_text()) if out.exists() else {}
                    j['status']='completed' if p.returncode==0 and 'error' not in result else 'failed'
                    j['error']=result.get('error',{}).get('message') if result else 'Worker failed; inspect exported log'
                self.update(j)
        except Exception as e:j['status']='failed';j['error']=str(e)
    def update(self,j):
        p=j['directory']/'progress.json'
        if p.exists():
            try:
                d=json.loads(p.read_text());j['completed']=d['completed'];j['total']=d['total'];j['archive']=d['archive']
            except (ValueError,KeyError):pass
    def public(self,j):
        self.update(j);return {k:v for k,v in j.items() if k not in ('directory','process','cancel','request_id')}
    def cancel(self,ident):
        with self.lock:
            j=self.jobs[ident]
            if j['status'] not in TERMINAL:
                j['cancel']=True;j['status']='cancelling';p=j.get('process')
                if p and p.poll() is None:
                    os.killpg(p.pid,signal.SIGTERM)
                    def force():
                        try:p.wait(timeout=5)
                        except subprocess.TimeoutExpired:
                            try:os.killpg(p.pid,signal.SIGKILL)
                            except ProcessLookupError:pass
                    threading.Thread(target=force,daemon=True).start()
            return self.public(j)
    def archives(self):
        archives={}
        # Only completed MineralTrace discovery archives in the fixed results root or this service's own jobs.
        for parent in [ROOT/'results',*self.root.iterdir()]:
            if not parent.is_dir():continue
            for p in parent.glob('discovery-*'):
                if p.is_dir() and not p.is_symlink() and (p/'analysis.json').is_file() and (p/'report.html').is_file():
                    ident=hashlib.sha256(str(p.resolve()).encode()).hexdigest()[:24];archives[ident]=p.resolve()
        return archives
    def archive(self,ident):
        paths=self.archives()
        if ident not in paths:raise KeyError('Unknown completed archive')
        return paths[ident]
    def result(self,ident):
        j=self.jobs[ident]
        if j['status']!='completed':raise ValueError('Only completed job results can be opened')
        d=json.loads((j['directory']/'result.json').read_text());p=j['directory']/d['archive']
        aid=next(k for k,v in self.archives().items() if v==p.resolve())
        result=json.loads((p/'analysis.json').read_text());result['archive_id']=aid;result['workbench']=d
        return result

class Handler(BaseHTTPRequestHandler):
    server_version='MineralTraceLocal/0.8.2'
    def log_message(self,*args):pass
    def send(self,code,data,kind='application/json',extra=None):
        raw=json.dumps(data,allow_nan=False).encode() if kind=='application/json' else data
        self.send_response(code);self.send_header('Content-Type',kind);self.send_header('Content-Length',str(len(raw)))
        self.send_header('X-Content-Type-Options','nosniff');self.send_header('Cache-Control','no-store')
        self.send_header('Referrer-Policy','no-referrer');self.send_header('X-Frame-Options','DENY')
        if extra:
            for k,v in extra.items():self.send_header(k,v)
        self.end_headers();self.wfile.write(raw)
    def guarded(self):
        host=self.headers.get('Host','');expected=f'127.0.0.1:{self.server.server_port}'
        if host!=expected:raise PermissionError('Loopback Host required')
        origin=self.headers.get('Origin')
        if origin and origin!='http://'+expected:raise PermissionError('Cross-origin request rejected')
        self.connection.settimeout(15)
    def do_POST(self):self.dispatch(True)
    def do_GET(self):self.dispatch(False)
    def dispatch(self,post):
        try:
            self.guarded();path=unquote(urlsplit(self.path).path);s=self.server.service
            if post:
                if self.headers.get('X-MineralTrace-Token')!=s.token:raise PermissionError('Missing local session token')
                if self.headers.get('Content-Type','').split(';')[0]!='application/json':raise ValueError('JSON body required')
                length=int(self.headers.get('Content-Length','0'))
                if not 0<length<=MAX_BODY:raise ValueError('Request must be 1–131072 bytes')
                body=json.loads(self.rfile.read(length))
                if not isinstance(body,dict):raise ValueError('Request object required')
                if path=='/api/studies/validate':
                    if set(body)!={'study'}:raise ValueError('Only study field allowed')
                    return self.send(200,s.validate(body['study'])[0])
                if path=='/api/studies/import':
                    if set(body)!={'toml'}:raise ValueError('Only toml field allowed')
                    return self.send(200,s.validate(text=body['toml'])[0])
                if path=='/api/jobs':
                    if set(body)!={'study','request_id'} or not isinstance(body['request_id'],str) or not 1<=len(body['request_id'])<=100:raise ValueError('study and bounded request_id required')
                    return self.send(202,s.start(body['study'],body['request_id']))
                m=re.fullmatch('/api/jobs/([a-f0-9]{32})/cancel',path)
                if m:
                    if body!={}:raise ValueError('Empty cancellation object required')
                    return self.send(200,s.cancel(m[1]))
                raise KeyError('Unknown operation')
            if path=='/api/health':return self.send(200,dict(status='ok',version='0.8.2',token=s.token,engine_configured=bool(s.engine and s.database),limits=dict(candidates=400,concurrent_jobs=1,job_seconds=1800,engine_step_seconds=30,request_bytes=MAX_BODY)))
            if path=='/api/examples':return self.send(200,dict(study=tomllib.loads((ROOT/'examples/discovery.toml').read_text())))
            if path=='/api/validation/comparisons':return self.send(200,json.loads((ROOT/'data/validation/v082/analysis.json').read_text()))
            if path=='/api/models/profiles':return self.send(200,dict(profiles=tomllib.loads((ROOT/'data/models/profiles.toml').read_text()),evidence=tomllib.loads((ROOT/'data/models/evidence.toml').read_text())))
            if path=='/api/archives':return self.send(200,[dict(id=k,name=v.name) for k,v in s.archives().items()])
            m=re.fullmatch('/api/jobs/([a-f0-9]{32})(/results)?',path)
            if m:return self.send(200,s.result(m[1]) if m[2] else s.public(s.jobs[m[1]]))
            m=re.fullmatch('/api/archives/([a-f0-9]{24})(?:/(.*))?',path)
            if m:
                p=s.archive(m[1]);name=m[2]
                if not name:
                    d=json.loads((p/'analysis.json').read_text());d['archive_id']=m[1];return self.send(200,d)
                if name=='download.zip':
                    buf=io.BytesIO();size=0
                    with zipfile.ZipFile(buf,'w',zipfile.ZIP_DEFLATED) as z:
                        for f in p.rglob('*'):
                            if f.is_symlink():continue
                            if f.is_file():
                                size+=f.stat().st_size
                                if size>150_000_000:raise ValueError('Archive exceeds 150 MB export limit; use local folder')
                                z.write(f,str(Path(p.name)/f.relative_to(p)))
                    return self.send(200,buf.getvalue(),'application/zip',{'Content-Disposition':f'attachment; filename="{p.name}.zip"'})
                # A completed archive is readable only under this scoped path, with no symlink escape.
                f=(p/name).resolve()
                if not f.is_relative_to(p) or not f.is_file() or f.stat().st_size>25_000_000:raise KeyError('Archive file unavailable')
                suffix=f.suffix.lower();kind=mimetypes.guess_type(str(f))[0] or 'application/octet-stream'
                # HTML is generated by the established engine report with escaped text.
                return self.send(200,f.read_bytes(),kind,{'Content-Disposition':'attachment'} if suffix not in ('.html','.svg','.css','.js') else None)
            # Built static frontend only; arbitrary repository reads are forbidden.
            dist=(ROOT/'workbench/dist').resolve();name=path.lstrip('/') or 'index.html';f=(dist/name).resolve()
            if not f.is_relative_to(dist) or not f.is_file():raise KeyError('Build workbench first or unknown path')
            return self.send(200,f.read_bytes(),mimetypes.guess_type(str(f))[0] or 'application/octet-stream')
        except PermissionError as e:self.send(403,dict(error=dict(code='FORBIDDEN',message=str(e))))
        except KeyError as e:self.send(404,dict(error=dict(code='NOT_FOUND',message=str(e))))
        except (ValueError,TypeError,RecursionError,subprocess.TimeoutExpired) as e:self.send(400,dict(error=dict(code='INVALID_REQUEST',message=str(e))))
        except (BrokenPipeError,ConnectionResetError):pass
        except Exception as e:self.send(500,dict(error=dict(code='INTERNAL_ERROR',message=str(e))))

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--port',type=int,default=8765);p.add_argument('--julia',default=os.environ.get('MINERALTRACE_JULIA','julia'));p.add_argument('--results',default=str(ROOT/'results/workbench'))
    a=p.parse_args();service=Service(a.julia,a.results);server=ThreadingHTTPServer(('127.0.0.1',a.port),Handler);server.service=service
    print(f'MineralTrace v0.8.2 local workbench: http://127.0.0.1:{server.server_port}',flush=True)
    try:server.serve_forever()
    except KeyboardInterrupt:pass
    finally:
        for ident,j in service.jobs.items():
            if j['status'] not in TERMINAL:service.cancel(ident)
        server.server_close()
if __name__=='__main__':main()
