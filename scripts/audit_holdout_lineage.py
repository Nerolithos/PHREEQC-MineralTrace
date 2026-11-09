# Database source comparison only; formatting differences are not causal parameter changes.
from pathlib import Path
import re,json,hashlib

def parse(path):
 text=Path(path).read_text(errors='replace'); section='';blocks={};cur=None
 for raw in text.splitlines():
  line=raw.split('#')[0].strip()
  if not line:continue
  if re.match(r'^[A-Z_]+$',line) and line in ['SOLUTION_MASTER_SPECIES','SOLUTION_SPECIES','PHASES','PITZER','SIT','EXCHANGE_MASTER_SPECIES','EXCHANGE_SPECIES','SURFACE_MASTER_SPECIES','SURFACE_SPECIES','RATES','END','GAS_BINARY_PARAMETERS','NAMED_EXPRESSIONS']:
   section=line;cur=None;continue
  if section=='SOLUTION_SPECIES' and '=' in line:
   rhs=line.split('=')[1].split();name=rhs[1] if re.match(r'^[-+]?\d+(\.\d+)?$',rhs[0]) else rhs[0]
   cur=('species',name);blocks[cur]=[re.sub(r'\s+',' ',line)]
  elif section=='PHASES' and re.match(r'^[A-Za-z][^\s=]*$',line):
   cur=('phase',line);blocks[cur]=[]
  elif cur:
   for item in line.split(';'):
    item=item.strip()
    if '=' in item or re.match(r'^-?(log_k|logk|delta_h|analytic\w*|gamma|Vm|T_c|P_c|Omega)\b',item,re.I):
     item=re.sub(r'^-','',item);item=re.sub(r'^analytical_expression\b','analytic',item,flags=re.I);item=re.sub(r'^analytical\b','analytic',item,flags=re.I)
     blocks[cur].append(re.sub(r'\s+',' ',item))
 return blocks
import argparse
cli=argparse.ArgumentParser(description="Read-only normalized block comparison; not a calibration-independence certificate")
cli.add_argument('--historical',default='data/validation/lineage-v081/phreeqc-2021.dat')
cli.add_argument('--current',default='data/validation/v071/databases/phreeqc.dat')
cli.add_argument('--output',default='results/lineage-v081-block-comparison.json')
args=cli.parse_args()
old=parse(args.historical);now=parse(args.current)
keys=[('species',n) for n in ['H+','H2O','OH-','Ca+2','CO3-2','HCO3-','CO2','(CO2)2','CaOH+','CaCO3','CaHCO3+','O2','H2','CH4']]+[('phase',n) for n in ['Calcite','CO2(g)']]
result=[]
for key in keys:
 a,b=old.get(key),now.get(key)
 r=dict(kind=key[0],name=key[1],historical=a,current=b,exact_normalized_match=a==b and a is not None);result.append(r)
 print(key,r['exact_normalized_match'])
 if a!=b:print('OLD',a,'NEW',b)
dest=Path(args.output);dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(json.dumps(result,indent=2)+'\n')
