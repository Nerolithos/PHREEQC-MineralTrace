import copy, importlib.util, json, tempfile, unittest
from pathlib import Path
spec=importlib.util.spec_from_file_location('compare',Path(__file__).resolve().parents[1]/'scripts/compare_studies.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class CrossStudy(unittest.TestCase):
 def setUp(self):
  self.rows=m.observations();self.a=self.rows[0];self.b=self.rows[-1]
 def test_units(self):
  self.assertAlmostEqual(m.convert(101.3,'kPa'),1.013);self.assertAlmostEqual(m.convert(1,'atm'),1.01325)
  self.assertAlmostEqual(self.a['observed']['value'],1.882*1000/100.0911)
  self.assertEqual(self.a['original_measured_value']['value'],1.882)
  with self.assertRaises(ValueError):m.convert(1,'psi')
 def test_unmatched(self):
  self.assertEqual(m.compare(self.a,self.b)['status'],'CONDITIONALLY_COMPARABLE')
  self.assertEqual(m.compare(self.a,self.b,'matched_condition')['status'],'NOT_COMPARABLE')
 def test_normalized_field_comparison(self):
  b=copy.deepcopy(self.a);b['pressure']['value']*=100;b['pressure']['units']='kPa'
  b['temperature']['value']+=273.15;b['temperature']['units']='K'
  c=m.compare(self.a,b);self.assertEqual(c['fields']['pressure']['status'],'DIRECTLY_COMPARABLE');self.assertEqual(c['fields']['temperature']['status'],'DIRECTLY_COMPARABLE')
  b['pressure']['units']='unknown';self.assertEqual(m.compare(self.a,b)['fields']['pressure']['status'],'INSUFFICIENT_INFORMATION')
 def test_missing_definition(self):
  b=copy.deepcopy(self.b);b['pressure_definition']['value']=None
  self.assertEqual(m.compare(self.a,b)['status'],'INSUFFICIENT_INFORMATION')
 def test_incompatible(self):
  for k,v in [('gas_boundary','closed_headspace'),('pressure_definition','total_pressure'),('observable','free_Ca2_activity'),('database_identity','other')]:
   b=copy.deepcopy(self.b);b[k]['value']=v
   self.assertEqual(m.compare(self.a,b)['status'],'NOT_COMPARABLE',k)
 def test_unknown_lineage(self):
  c=m.compare(self.a,self.b);self.assertEqual(c['fields']['calibration_independence']['status'],'INSUFFICIENT_INFORMATION')
  self.assertEqual(c['fields']['mass_normalization']['status'],'INSUFFICIENT_INFORMATION')
 def test_signs_and_no_pool(self):
  with tempfile.TemporaryDirectory() as d:
   a=m.run(d);self.assertIsNone(a['pooled_validation_score']);self.assertFalse(a['strict_qualification_changed']);self.assertFalse(a['experimental_validation_granted'])
   self.assertEqual(a['statistics']['water_hypothesis']['residual_signs']['positive'],5)
   self.assertEqual(a['statistics']['water_reported']['residual_signs']['negative'],5)
   self.assertEqual(a['directly_comparable_pairs'],0)
 def test_reproduction(self):
  with tempfile.TemporaryDirectory() as a,tempfile.TemporaryDirectory() as b:
   m.run(a);m.run(b)
   for f in ['analysis.json','observations.csv','REPORT.md','report.html','residual-pressure.svg','residual-concentration.svg','residual-temperature.svg']:self.assertEqual((Path(a)/f).read_bytes(),(Path(b)/f).read_bytes())
if __name__=='__main__':unittest.main()
