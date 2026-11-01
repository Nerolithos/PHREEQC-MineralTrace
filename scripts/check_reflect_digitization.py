"""Read-only audit of frozen graph extraction. Optional dependencies: pypdf, Pillow. Never overwrites observations."""
from pathlib import Path
import csv,hashlib
from pypdf import PdfReader
project=Path(__file__).resolve().parent.parent
pdf=project/'data/sources/REFLECT-D23-2023.pdf'
page=PdfReader(pdf).pages[25]
image=next(x for x in page.images if x.name=='Image183.jpg').image.convert('RGB')
assert image.size==(1296,2033)
px=image.load();pts=set()
for y in range(70,250):
 for x in range(790,1230):
  r,g,b=px[x,y]
  if b>r+10 and r>g+20 and b>g+45 and r<170:pts.add((x,y))
centroids=[]
while pts:
 stack=[pts.pop()];component=[]
 while stack:
  p=stack.pop();component.append(p)
  for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
   n=(p[0]+dx,p[1]+dy)
   if n in pts:pts.remove(n);stack.append(n)
 if len(component)>=20:centroids.append((sum(x for x,y in component)/len(component),sum(y for x,y in component)/len(component)))
centroids.sort();rows=list(csv.DictReader((project/'data/validation/reflect-2023/observations.csv').open()))
assert len(centroids)==len(rows)==5
for (x,y),row in zip(centroids,rows):
 assert abs(x-float(row['marker_x_px']))<1e-6 and abs(y-float(row['marker_y_px']))<1e-6
 assert round((x-769.5)/514*60,2)==float(row['pco2_bar'])
 assert round((407.5-y)/400*3.5,3)==float(row['solubility_g_per_kg'])
print('PASS: five original measured markers reproduce the frozen observation CSV; no data overwritten.')
print('Source SHA-256:',hashlib.sha256(pdf.read_bytes()).hexdigest())
