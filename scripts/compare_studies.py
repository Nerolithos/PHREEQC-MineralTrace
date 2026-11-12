#!/usr/bin/env python3
"""Read-only cross-study audit of frozen predictions. No PHREEQC calls or fitting."""
import csv, hashlib, html, json, math, shutil, statistics, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
DB = '59373961d648dfbf68a40744060c1d64f57ecbec98f4f5fb89f3a1b4213ccd10'
GFW = 100.0911  # exact locked database CaCO3 formula weight; not a fitted constant
STATES = {'OBSERVED','SOURCE_REPORTED','DERIVED','ASSUMED','CALCULATED','UNKNOWN'}
CALIBRATION_STATES = {'INDEPENDENCE_CONFIRMED','POTENTIAL_OVERLAP','DEPENDENCE_CONFIRMED','UNKNOWN'}

def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def field(value, provenance, source, units=None, transformation=None):
    assert provenance in STATES
    return dict(value=value, provenance=provenance, source=source, units=units, transformation=transformation)
def convert(value, units):
    if units == 'kPa': return value / 100
    if units == 'atm': return value * 1.01325
    if units == 'bar': return value
    raise ValueError('Unsupported pressure unit')
def statistics_for(rows):
    e=[r['signed_error']['value'] for r in rows]; q=[r['relative_error']['value'] for r in rows]
    return dict(n=len(e), units=rows[0]['comparison_units']['value'],mean_signed_error=statistics.mean(e),mean_absolute_error=statistics.mean(map(abs,e)),root_mean_square_error=math.sqrt(statistics.mean(x*x for x in e)),mean_relative_error=statistics.mean(q),maximum_absolute_relative_error=max(map(abs,q)),residual_signs={k:sum((v>0 if k=='positive' else v<0 if k=='negative' else v==0) for v in e) for k in ['positive','negative','zero']},weighted_statistics=None,interpretation='Descriptive, per-study and mass-basis only; not a global validation score')

def observations(root=ROOT):
    locks=json.loads((root/'data/validation/v082/INPUT_LOCK.json').read_text())
    for p,h in locks.items():
        if sha(root/p)!=h: raise ValueError('Frozen comparison input changed: '+p)
    rows=[]
    for study,csvpath,source in [('REFLECT-2023','data/validation/v071/comparison.csv','data/sources/REFLECT-D23-2023.pdf'),('FERREIRA-2025','data/validation/v081/comparison.csv','data/sources/FERREIRA-2025-PUBLISHER-TRANSCRIPT.txt')]:
        for v in csv.DictReader((root/csvpath).read_text().splitlines()):
            reflect=study=='REFLECT-2023'
            if reflect and v['scenario']!='baseline': continue
            for basis in (['water_hypothesis','solution_hypothesis'] if reflect else ['water_reported']):
                src=source+(' p.22–26' if reflect else ' Table 3 and methods')
                original=float(v['observed_g_kg'] if reflect else v['observed_total_Ca_mmol_kg_water'])
                obs=original*1000/GFW if reflect else original
                pred=float(v['prediction_water_g_kg'] if basis=='water_hypothesis' else v['prediction_solution_g_kg']) * 1000/GFW if reflect else float(v['predicted_total_Ca_mmol_kg_water'])
                unit='mmol CaCO3-equivalent/kg '+('solution' if basis=='solution_hypothesis' else 'water')
                r=dict(study_id=study,point_id=v['point_id'] if reflect else v['id'],basis_scenario=basis,original_source_id='doi:10.48440/gfz.4.8.2023.001' if reflect else 'doi:10.1021/acs.jced.4c00670',source_file=source,source_file_sha256=sha(root/source),prediction_file=csvpath,prediction_sha256=sha(root/csvpath))
                r.update(temperature=field(24. if reflect else float(v['temperature_c']),'SOURCE_REPORTED',src,'degC'),pressure=field(float(v['pco2_bar']) if reflect else convert(float(v['pco2_kpa']),'kPa'),'DERIVED' if not reflect else 'SOURCE_REPORTED',src,'bar','p_bar = p_kPa / 100; input='+v.get('pco2_kpa','') if not reflect else None),pressure_original=field(float(v['pco2_bar']) if reflect else float(v['pco2_kpa']),'SOURCE_REPORTED',src,'bar' if reflect else 'kPa'),pressure_definition=field('CO2_partial_pressure','SOURCE_REPORTED',src),gas_boundary=field('regulated_CO2_supply','SOURCE_REPORTED',src),initial_composition=field('degassed deionised water; selected 0 wt% NaCl' if reflect else 'Type-1 deionized water; conductivity <1.5 microS/cm','SOURCE_REPORTED',src),initial_ion_analysis=field(None,'UNKNOWN',src),ionic_strength=field(None,'UNKNOWN',src,'mol/kg water'),mineral=field('Calcite','SOURCE_REPORTED',src),solid_loading=field(None,'UNKNOWN',src,'g per experimental point'),solid_loading_description=field('10–40 g source range, per-point unknown' if reflect else 'excess solid, per-point loading unknown','SOURCE_REPORTED',src),observable=field('total_Ca_as_CaCO3_endpoint','DERIVED',src,transformation='reported CaCO3 equivalent; 1 mol Ca : 1 mol CaCO3'),measurement_method=field('EDTA complexometry, mean of five titrations, 2 micrometre filtered sampling' if reflect else 'AAS, settled acidified aliquot, duplicate analyses; filtration cutoff unknown','SOURCE_REPORTED',src),original_measured_value=field(original,'DERIVED' if reflect else 'OBSERVED',src,'g/kg; denominator unresolved' if reflect else 'mmol/kg water','digitized Figure 22 marker, not raw worksheet' if reflect else None),observed=field(obs,'DERIVED' if reflect else 'OBSERVED',src,unit,dict(expression='g/kg * 1000 / 100.0911',input_g_per_kg=original,database_GFW_CaCO3_g_mol=GFW) if reflect else None),comparison_units=field(unit,'ASSUMED' if reflect else 'SOURCE_REPORTED',src),mass_normalization=field(None if reflect else 'kg_water','UNKNOWN' if reflect else 'SOURCE_REPORTED',src),assumed_mass_basis=field(basis,'ASSUMED' if reflect else 'SOURCE_REPORTED',src),measurement_uncertainty=field(None if reflect else dict(standard_u_mmol_kg=.15,duplicate_SD_mmol_kg=float(v['duplicate_sd_mmol_kg_water']),standard_u_temperature_K=.05,standard_u_pressure_kPa=2.7),'UNKNOWN' if reflect else 'SOURCE_REPORTED',src),uncertainty_note=field('Usually <1% analytical; no pointwise confidence/propagation' if reflect else 'Duplicate SD is not total uncertainty; do not combine blindly with u(m)','SOURCE_REPORTED',src),digitization_uncertainty=field(dict(bound_g_per_kg=.03,bound_mmol_per_kg=.03*1000/GFW) if reflect else None,'ASSUMED' if reflect else 'UNKNOWN','REFLECT extraction protocol' if reflect else 'Tabulated values; no digitization performed'),prediction=field(pred,'CALCULATED',csvpath,unit,'frozen g/kg * 1000 / 100.0911' if reflect else 'unchanged frozen mmol/kg water'),signed_error=field(pred-obs,'DERIVED',csvpath,unit,'prediction - observed'),relative_error=field((pred-obs)/obs,'DERIVED',csvpath,'fraction','(prediction - observed) / observed'),database_identity=field(DB,'CALCULATED','locked phreeqc.dat SHA-256'),model_profile=field('calcite-co2-water-386','ASSUMED','data/models/profiles.toml'),model_configuration=field('ion_association/native_PR/fixed_partial_pressure/pure_water_approximation','ASSUMED','frozen model protocols'),calibration_independence=field('UNKNOWN','UNKNOWN','data/validation/lineage-v081/SOURCE.json'),missing_metadata=['per-point solid loading','initial trace ion analysis','measured DIC','measured endpoint pH','full calibration lineage']+(['mass denominator','pointwise analytical uncertainty'] if reflect else ['aliquot filtration cutoff']))
                rows.append(r)
    return rows

def compare(a,b,purpose='descriptive'):
    if purpose not in ('descriptive','matched_condition'): raise ValueError('unknown comparison purpose')
    fields={}
    for k in ['temperature','pressure','pressure_definition','gas_boundary','initial_composition','mineral','observable','measurement_method','mass_normalization','measurement_uncertainty','model_configuration','database_identity','calibration_independence']:
        x,y=a[k]['value'],b[k]['value']
        if k=='calibration_independence' and any(v is not None and v not in CALIBRATION_STATES for v in (x,y)):
            raise ValueError('Unknown calibration-lineage state')
        if k in ('pressure','temperature'):
            def normalized(record):
                v,u=record['value'],record.get('units')
                if not isinstance(v,(int,float)) or isinstance(v,bool) or not math.isfinite(v):return None
                if k=='temperature':return v if u=='degC' else v-273.15 if u=='K' else None
                return convert(v,u) if u in ('bar','kPa','atm') else None
            x,y=normalized(a[k]),normalized(b[k])
        missing=x is None or y is None or x=='UNKNOWN' or y=='UNKNOWN'
        equal=x==y and not missing
        status='INSUFFICIENT_INFORMATION' if missing else 'DIRECTLY_COMPARABLE' if equal else 'CONDITIONALLY_COMPARABLE'
        note='Missing or unresolved values are not matches' if missing else 'Same declared field; not certification of physical equivalence' if equal else 'Different recorded conditions/operational definitions; descriptive only'
        if not missing and k in ('observable','mineral','pressure_definition','gas_boundary','database_identity','model_configuration') and not equal:
            status='NOT_COMPARABLE';note='Incompatible definition/configuration; no shared prediction comparison without explicit harmonization'
        if purpose=='matched_condition' and k in ('temperature','pressure') and not equal and not missing:
            status='NOT_COMPARABLE';note='No exact matched condition; no invented matching tolerance'
        fields[k]=dict(status=status,left=x,right=y,explanation=note)
    statuses=[v['status'] for v in fields.values()]
    hard=any(fields[k]['status']=='NOT_COMPARABLE' for k in fields)
    # Missing measurement method, gas or observable blocks even a descriptive measurement comparison.
    critical_unknown=any(fields[k]['status']=='INSUFFICIENT_INFORMATION' for k in ('observable','mineral','pressure_definition','gas_boundary','measurement_method','model_configuration','database_identity'))
    status='NOT_COMPARABLE' if hard else 'INSUFFICIENT_INFORMATION' if critical_unknown else 'DIRECTLY_COMPARABLE' if all(s=='DIRECTLY_COMPARABLE' for s in statuses) else 'CONDITIONALLY_COMPARABLE'
    return dict(left=a['point_id'],right=b['point_id'],purpose=purpose,status=status,fields=fields,limitations=['Descriptive sign comparison only; no pressure-causal attribution','Unknown mass basis and uncertainty prevent pooled quantitative validation','Calibration independence UNKNOWN; no experimental or strict promotion'])

def plot(rows,xkey,title,xlabel,path):
    groups=[('REFLECT-2023','water_hypothesis','#246e9c','REFLECT / kg water hypothesis'),('REFLECT-2023','solution_hypothesis','#917044','REFLECT / kg solution hypothesis'),('FERREIRA-2025','water_reported','#c34d43','Ferreira / kg water')]
    xs=[r[xkey]['value'] for r in rows];lo,hi=min(xs),max(xs);lo=min(0,lo);hi=hi if hi!=lo else lo+1
    svg=[f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 580"><rect width="100%" height="100%" fill="white"/><g font-family="sans-serif" fill="#213744"><text x="80" y="35" font-size="22">{html.escape(title)}</text>']
    X=lambda x:90+(x-lo)/(hi-lo)*810
    Y=lambda y:380-(y+15)/50*280
    for y in [-10,0,10,20,30]:svg.append(f'<path d="M90 {Y(y)} H910" stroke="#ddd"/><text x="70" y="{Y(y)+5}" text-anchor="end">{y}%</text>')
    for i in range(6):
        x=lo+(hi-lo)*i/5;svg.append(f'<text x="{X(x)}" y="410" text-anchor="middle">{x:.3g}</text>')
    for j,(study,basis,color,label) in enumerate(groups):
        for r in rows:
            if r['study_id']==study and r['basis_scenario']==basis:
                svg.append(f'<circle cx="{X(r[xkey]["value"])}" cy="{Y(100*r["relative_error"]["value"])}" r="6" fill="{color}"><title>{r["point_id"]} {basis}</title></circle>')
        svg.append(f'<circle cx="90" cy="{465+26*j}" r="5" fill="{color}"/><text x="105" y="{470+26*j}">{label}</text>')
    svg.extend([f'<text x="90" y="440">{html.escape(xlabel)} · vertical: signed relative error (%)</text>','<text x="90" y="565">Discrete frozen points; no regression, pooling, confidence bands or pressure-causal inference</text></g></svg>'])
    path.write_text(''.join(svg)+'\n')

def run(out,root=ROOT):
    out=Path(out);out.mkdir(parents=True,exist_ok=True);rows=observations(root)
    a=[r for r in rows if r['basis_scenario']=='water_hypothesis'];b=[r for r in rows if r['study_id']=='FERREIRA-2025']
    pairs=[compare(x,y) for x in a for y in b];matched=[compare(x,y,'matched_condition') for x in a for y in b]
    stats={basis:statistics_for([r for r in rows if r['basis_scenario']==basis]) for basis in ['water_hypothesis','solution_hypothesis','water_reported']}
    lineage=json.loads((root/'data/validation/lineage-v081/SOURCE.json').read_text())
    blocks=json.loads((root/'data/validation/lineage-v081/block-comparison.json').read_text())
    result=dict(schema_version=1,observations=rows,statistics=stats,descriptive_pairs=pairs,matched_condition_pairs=matched,directly_comparable_pairs=sum(p['status']=='DIRECTLY_COMPARABLE' for p in pairs),matched_condition_pairs_available=sum(p['status']=='DIRECTLY_COMPARABLE' for p in matched),calibration_lineage=dict(state='UNKNOWN',source_history=lineage,relevant_blocks=blocks,publication_date='Ferreira 2025-02-25; Penha thesis defended 2022-03-31 and public 2022-11-09',measurement_dates='UNKNOWN; publication/defense dates are not measurement dates',database_revision_date='2021-07-07 snapshot versus May-2024 production',evidence_of_parameter_estimation_use='UNKNOWN; absence of citation is not independence'),experimental_validation_granted=False,strict_qualification_changed=False,pooled_validation_score=None,conclusion='Opposite signs in unmatched domains. No directly comparable experimental pairs; no causal attribution to pressure, database or laboratory.')
    (out/'analysis.json').write_text(json.dumps(result,sort_keys=True,indent=2,ensure_ascii=False)+'\n')
    with (out/'observations.csv').open('w',newline='') as f:
        w=csv.writer(f);w.writerow(['study','point','basis','temperature_c','pco2_bar','observed','prediction','units','error','relative_error','source_sha256'])
        for r in rows:w.writerow([r['study_id'],r['point_id'],r['basis_scenario'],r['temperature']['value'],r['pressure']['value'],r['observed']['value'],r['prediction']['value'],r['comparison_units']['value'],r['signed_error']['value'],r['relative_error']['value'],r['source_file_sha256']])
    for key,title,label,name in [('pressure','Cross-study residuals · unmatched pressure domains','pCO2 (bar)','residual-pressure.svg'),('observed','Residuals versus reported concentration','CaCO3-equivalent mmol/kg (basis labeled separately)','residual-concentration.svg'),('temperature','Temperature is constant within each study','Temperature (degC); two study conditions, not a temperature trend','residual-temperature.svg')]:plot(rows,key,title,label,out/name)
    text='''# v0.8.2 — Cross-study discrepancy audit

No directly comparable pairs exist among these two five-point experimental series. All 25 water-basis cross-study pairs are conditionally comparable for descriptive purposes; none is a matched-condition test. REFLECT's two mass-basis scenarios are alternative interpretations of five observations, not ten independent measurements.

Both sources define CO2 partial pressure and describe regulated gas supply. REFLECT uses autoclave pressure minus vapor pressure; Ferreira tabulates pCO2. Matching this label does not recover exact gas history. Their pressure domains do not overlap (10.09–49.99 versus 1.013–2.146 bar), temperatures are 24 and 25 °C, analytical methods and sampling definitions differ, and initial trace chemistry is unknown. REFLECT's kg denominator remains unresolved.

Residual signs are positive for all five REFLECT observations on either declared mass basis and negative for all five Ferreira means. Within-series trends are descriptive only. Temperature is constant within each series; its two-study contrast is confounded, not a sensitivity experiment. No pooled RMSE, fitted trend, weighted acceptance, universal bias correction or pressure explanation is warranted.

## Separate descriptive statistics

'''
    for k,v in stats.items():text+=f'- {k}: n={v["n"]}, mean signed error={v["mean_signed_error"]:.6g}, MAE={v["mean_absolute_error"]:.6g}, RMSE={v["root_mean_square_error"]:.6g} {v["units"]}; mean relative error={100*v["mean_relative_error"]:.3f}%, max absolute relative error={100*v["maximum_absolute_relative_error"]:.3f}%.\n'
    text+='''
## Uncertainty and provenance

REFLECT: per-point experimental uncertainty UNKNOWN. The extraction bound ±0.03 g/kg is a digitization assumption, not an experimental confidence interval. Ferreira: duplicate SD and reported standard u(m)=0.15 mmol/kg, u(P)=2.7 kPa, u(T)=0.05 K remain distinct. No unreported covariance or combined interval is invented.

Original measured values/units are preserved. For REFLECT only, g/kg ×1000/100.0911 yields mmol CaCO3-equivalent/kg on each explicit assumed basis; the exact locked database formula weight is not a fit. Ferreira tabulated mmol/kg water is unchanged. Each record includes typed field provenance, source SHA, prediction SHA, transformation inputs and missing metadata.

## Calibration lineage

The actual locked species and phase definitions and official 2021 comparison are retained in analysis.json. Calcite and CO2(g) phase coefficients match the older snapshot; calcium bicarbonate association, some aqueous volume and CO2 activity parameters changed. Numeric-format changes alone are not thermodynamic revisions. Full source-to-parameter estimation records remain unavailable. Later database revision is not evidence of calibration use; absent citations do not establish nonuse. Measurement dates remain unknown and must not be substituted by publication dates. Both complete-model calibration-independence states remain UNKNOWN.

An attempted fresh retrieval of the DOI and historical raw database on 2026-11-12 failed through the available web service. This audit therefore uses the already archived original REFLECT PDF, publisher-text transcript, official database snapshot/history and prior source audits; it invents no new bibliographic history. See ../lineage-v081/SOURCE.json and the source audits in ../v071 and ../holdout-ferreira-2025.

## Applicability

Separate engine, conservation, experimental agreement, experimental independence, model applicability, proxy compatibility and actual chronology dimensions remain separate. Neither model nor strict mode is promoted. Cross-study references explain discrepant observations and unmatched conditions; they never extend discrete endpoints to a continuous validated region or certify a path, pH, DIC, kinetics or chronology.

Next discriminating evidence: matched 24–25 °C conditions spanning both pressure domains, Ca plus independently measured CO2/DIC, explicit mass denominator, aliquot recovery/filtration, per-point uncertainties and source-to-parameter lineage. No extra mechanism or parameter fitting is justified by these residual signs alone.

## Reproduction

Run `python3 scripts/compare_studies.py results/cross-study-reproduced`. No engine is called. INPUT_LOCK.json verifies the original predictions before analysis. Compare analysis.json, observations.csv and the three SVGs byte-for-byte. A complete result snapshots the exact frozen inputs, source audits and comparison code.
'''
    (out/'REPORT.md').write_text(text)
    (out/'report.html').write_text('<!doctype html><meta charset="utf-8"><title>MineralTrace cross-study audit</title><style>body{font:17px system-ui;max-width:1050px;margin:40px auto;padding:24px}pre{white-space:pre-wrap}img{width:100%}</style><pre>'+html.escape(text)+'</pre>'+''.join('<img alt="Descriptive residuals; no causal inference" src="'+n+'">' for n in ['residual-pressure.svg','residual-concentration.svg','residual-temperature.svg']))
    if out.resolve() != (root/'data/validation/v082').resolve():
        files=set(json.loads((root/'data/validation/v082/INPUT_LOCK.json').read_text())) | {
            'data/validation/v082/INPUT_LOCK.json','data/validation/lineage-v081/SOURCE.json',
            'data/validation/lineage-v081/block-comparison.json','data/validation/lineage-v081/official-db-history.json',
            'data/validation/lineage-v081/phreeqc-2021.dat','data/validation/v071/SOURCE_AUDIT.md',
            'data/validation/holdout-ferreira-2025/SOURCE_AUDIT.md',
            'data/sources/REFLECT-D23-2023.pdf','data/sources/FERREIRA-2025-PUBLISHER-TRANSCRIPT.txt',
            'scripts/compare_studies.py'}
        for name in sorted(files):
            target=out/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(root/name,target)
        (out/'reproduce.py').write_text("import subprocess, sys\nfrom pathlib import Path\np=Path(__file__).resolve().parent\nsubprocess.run([sys.executable,str(p/'scripts/compare_studies.py'),str(p/'reproduced')],check=True)\n")
        (out/'input-manifest.json').write_text(json.dumps({name:sha(out/name) for name in sorted(files)},sort_keys=True,indent=2)+'\n')
    return result
if __name__=='__main__':
    out=Path(sys.argv[1]) if len(sys.argv)>1 else ROOT/'results/cross-study'
    run(out);print(out/'report.html')
