"""Deterministic HTTP integration test with actual Julia/PHREEQC, no mock chemistry."""
import copy, hashlib, importlib.util, io, json, os, subprocess, tempfile, threading, time, unittest, urllib.error, urllib.request, zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('service',ROOT/'scripts/workbench_server.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class Workbench(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.temp=tempfile.TemporaryDirectory();cls.service=m.Service(os.environ.get('MINERALTRACE_JULIA','julia'),cls.temp.name)
  cls.server=m.ThreadingHTTPServer(('127.0.0.1',0),m.Handler);cls.server.service=cls.service
  threading.Thread(target=cls.server.serve_forever,daemon=True).start();cls.base=f'http://127.0.0.1:{cls.server.server_port}/api/'
  import tomllib
  cls.study=tomllib.loads((ROOT/'examples/discovery.toml').read_text());cls.study['search']['max_depth']=1
 @classmethod
 def tearDownClass(cls):
  for ident,j in cls.service.jobs.items():
   if j['status'] not in m.TERMINAL:cls.service.cancel(ident)
  cls.server.shutdown();cls.server.server_close();cls.temp.cleanup()
 def call(self,path,body=None,headers=None):
  h={'Content-Type':'application/json','X-MineralTrace-Token':self.service.token};h.update(headers or {})
  req=urllib.request.Request(self.base+path,data=json.dumps(body).encode() if body is not None else None,headers=h)
  with urllib.request.urlopen(req,timeout=60) as r:
   data=r.read();return r.status,json.loads(data) if r.headers['Content-Type']=='application/json' else data
 def wait(self,ident):
  deadline=time.time()+300
  while time.time()<deadline:
   j=self.call('jobs/'+ident)[1]
   if j['status'] in m.TERMINAL:return j
   time.sleep(.2)
  self.fail('job exceeded test deadline')
 def test_workflow(self):
  self.assertEqual(self.call('health')[1]['version'],'0.8.2')
  for body in [{'study':None},{'study':{**self.study,'executable':'/bin/sh'}},{'study':{**self.study,'initial':{**self.study['initial'],'pH':None}}},{'study':{**self.study,'search':{**self.study['search'],'max_candidates':1}}}]:
   with self.assertRaises(urllib.error.HTTPError) as e:self.call('studies/validate',body)
   self.assertEqual(e.exception.code,400)
  for headers in [{'Origin':'https://untrusted.example'},{'Host':'attacker.example'},{'X-MineralTrace-Token':'wrong'}]:
   with self.assertRaises(urllib.error.HTTPError) as e:self.call('studies/validate',{'study':self.study},headers)
   self.assertEqual(e.exception.code,403)
  with self.assertRaises(urllib.error.HTTPError):self.call('studies/validate',{'study':self.study,'shell':'ignored?'})
  count=self.call('studies/validate',{'study':self.study})[1]['candidate_count'];self.assertGreater(count,0)
  first=self.call('jobs',{'study':self.study,'request_id':'cancel-test'})[1]
  self.assertEqual(self.call('jobs',{'study':self.study,'request_id':'cancel-test'})[1]['id'],first['id'])
  with self.assertRaises(urllib.error.HTTPError):self.call('jobs',{'study':self.study,'request_id':'concurrent'})
  # Wait until a real engine candidate completed before cancelling, demonstrating preservation.
  deadline=time.time()+60
  while time.time()<deadline:
   j=self.call('jobs/'+first['id'])[1]
   if j['completed']>=1:break
   time.sleep(.2)
  self.call('jobs/'+first['id']+'/cancel',{})
  self.assertEqual(self.wait(first['id'])['status'],'cancelled')
  partial=self.service.jobs[first['id']]['directory'];self.assertTrue(any(partial.rglob('input.pqi')))
  with self.assertRaises(urllib.error.HTTPError):self.call('jobs/'+first['id']+'/results')
  job=self.call('jobs',{'study':self.study,'request_id':'complete-test'})[1]
  terminal=self.wait(job['id']);self.assertEqual(terminal['status'],'completed',terminal)
  result=self.call('jobs/'+job['id']+'/results')[1];self.assertEqual(len(result['candidates']),count)
  self.assertTrue(all(c['screening']['formation_order_classification']=='undetermined' for c in result['candidates']))
  self.assertFalse(result['workbench']['research_applicability']['strict_qualified'])
  self.assertEqual(result['workbench']['research_applicability']['cross_study_context']['experimental_independence'],'UNKNOWN')
  aid=result['archive_id'];blob=self.call('archives/'+aid+'/download.zip')[1]
  with zipfile.ZipFile(io.BytesIO(blob)) as z:
   names=z.namelist();self.assertTrue(any(n.endswith('/reproduce.jl') for n in names));self.assertTrue(any(n.endswith('/database.dat') for n in names))
   analysis=z.read(next(n for n in names if n.endswith('/analysis.json') and n.count('/')==1))
  directory=self.service.jobs[job['id']]['directory'];out=Path(self.temp.name)/'cli'
  subprocess.run([self.service.julia,'--startup-file=no','--project='+str(ROOT),str(ROOT/'scripts/discover.jl'),str(directory/'study.toml'),str(out)],env=self.service.env,check=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=300)
  cli=next(out.glob('discovery-*/analysis.json'));self.assertEqual(analysis,cli.read_bytes())
  # Error propagation: failed trusted engine setup cannot be mislabeled a completed computation.
  old=self.service.env.get('PHREEQC_EXECUTABLE');self.service.env['PHREEQC_EXECUTABLE']='/nonexistent/phreeqc'
  failed=self.call('jobs',{'study':self.study,'request_id':'engine-failure'})[1]
  self.assertEqual(self.wait(failed['id'])['status'],'failed')
  self.assertTrue(self.call('jobs/'+failed['id'])[1]['error'])
  self.service.env['PHREEQC_EXECUTABLE']=old
  audit={'real_engine':True,'candidate_count':count,'CLI_UI_analysis_byte_identical':True,'analysis_sha256':hashlib.sha256(analysis).hexdigest(),'cancelled_partial_archive_preserved':True,'duplicate_request_idempotent':True,'concurrent_job_rejected':True,'invalid_requests_and_origins_rejected':True,'archive_zip_checked':True,'error_propagation_checked':True}
  (ROOT/'data/validation/v082/API_AUDIT.json').write_text(json.dumps(audit,indent=2)+'\n')
if __name__=='__main__':unittest.main()
