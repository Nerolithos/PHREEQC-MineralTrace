"""Controlled attribution only: hybrid databases are diagnostic interventions, never production profiles."""
from pathlib import Path
import os,sys,tempfile,subprocess,hashlib,json,re,shutil
project=Path(__file__).resolve().parent.parent
engine=Path(os.environ['PHREEQC_EXECUTABLE']).resolve();current=Path(os.environ['PHREEQC_DATABASE']).resolve()
oldpath=project/'data/validation/historical-2012/phreeqc.dat';midpath=project/'data/validation/historical-2013/phreeqc.dat'
root=project/'results';root.mkdir(exist_ok=True);out=Path(tempfile.mkdtemp(prefix='ex1-attribution-',dir=root))
def read(p):return p.read_bytes().decode('utf8',errors='replace')
def section(text):
 start=text.index('\nSOLUTION_SPECIES\n')+1;end=text.index('\nPHASES\n',start)+1
 return start,end,text[start:end]
def blocks(text):
 _,_,s=section(text);lines=s.splitlines(keepends=True);starts=[i for i,l in enumerate(lines) if '=' in l and l and not l[0].isspace() and not l.startswith('#')]
 result={}
 for i,j in enumerate(starts):
  end=starts[i+1] if i+1<len(starts) else len(lines);result[' '.join(lines[j].split())]=''.join(lines[j:end])
 return result
def replace_blocks(base,source,names):
 a,b,s=section(base);dest=blocks(base);src=blocks(source)
 for name in names:
  if name in src and name in dest:s=s.replace(dest[name],src[name],1)
 return base[:a]+s+base[b:]
cur=read(current);old=read(oldpath);mid=read(midpath);oldblocks=blocks(old)
carbonates=['Na+ + CO3-2 = NaCO3-','Na+ + HCO3- = NaHCO3']
sulfates=[key for key in oldblocks if 'SO4' in key and '=' in key and '+' in key.split('=')[0] and 'e-' not in key]
a,b,oldsection=section(old);ca,cb,_=section(cur)
cases=[('current',current,None),('unmodified_2012',oldpath,None),('unmodified_2013',midpath,None),('current_2012_NaCO3',None,replace_blocks(cur,old,carbonates[:1])),('current_2012_NaHCO3',None,replace_blocks(cur,old,carbonates[1:])),('current_2012_Na_carbonates',None,replace_blocks(cur,old,carbonates)),('2013_2012_Na_carbonates',None,replace_blocks(mid,old,carbonates)),('current_2012_sulfate_complexes',None,replace_blocks(cur,old,sulfates)),('current_2012_carbonate_sulfate',None,replace_blocks(cur,old,carbonates+sulfates)),('current_all_2012_aqueous_species',None,cur[:ca]+oldsection+cur[cb:])]
selection='''SELECTED_OUTPUT
 -file selected.tsv
 -reset false
 -high_precision true
 -saturation_indices Calcite Gypsum Anhydrite
USER_PUNCH
 -headings la_Ca la_CO3 la_SO4 la_water lk_Calcite lk_Gypsum lk_Anhydrite
 -start
 10 PUNCH LA("Ca+2"), LA("CO3-2"), LA("SO4-2"), LA("H2O"), LK_PHASE("Calcite"), LK_PHASE("Gypsum"), LK_PHASE("Anhydrite")
 -end
END'''
input_=re.sub(r'(?m)^END\s*$',selection,(project/'data/validation/usgs-ex1.pqi').read_text(),count=1)
results=[]
for name,path,text in cases:
 d=out/name;d.mkdir();(d/'input.pqi').write_text(input_)
 if path:shutil.copyfile(path,d/'database.dat')
 else:(d/'database.dat').write_text(text)
 with (d/'console.log').open('w') as f:subprocess.run([str(engine),'input.pqi','output.pqo','database.dat'],cwd=d,stdout=f,stderr=f,check=True,timeout=60)
 lines=(d/'selected.tsv').read_text().strip().splitlines();row={k:float(v) for k,v in zip(lines[0].split(),lines[1].split())}
 results.append({'case':name,'kind':'unmodified official database' if path else 'diagnostic hybrid, not a usable scientific profile','values':row,'database_sha256':hashlib.sha256((d/'database.dat').read_bytes()).hexdigest(),'input_sha256':hashlib.sha256((d/'input.pqi').read_bytes()).hexdigest(),'archive':str(d)})
expected={'Calcite':0.68,'Gypsum':-0.64,'Anhydrite':-0.92}
matched=next(x for x in results if x['case']=='unmodified_2012')
assert all(abs(matched['values']['si_'+p]-v)<=0.01 for p,v in expected.items())
payload={'scope':'controlled database attribution with identical current binary/input, not experimental validation','engine_sha256':hashlib.sha256(engine.read_bytes()).hexdigest(),'manual_values':expected,'original_tolerance':0.01,'Na_carbonate_interventions':carbonates,'sulfate_interventions':sulfates,'missing_current_reactions':[k for k in carbonates+sulfates if k not in blocks(cur)],'results':results}
(out/'attribution.json').write_text(json.dumps(payload,indent=2)+'\n')
shutil.copyfile(out/'attribution.json',project/'data/validation/EXAMPLE1_ATTRIBUTION_V070.json')
print(out)
for r in results:print(r['case'],{p:r['values']['si_'+p] for p in expected})
