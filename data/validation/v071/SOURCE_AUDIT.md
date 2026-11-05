# REFLECT original-source audit — 2026-11-04

Source: Tjelta et al., REFLECT D2.3, DOI [10.48440/gfz.4.8.2023.001](https://doi.org/10.48440/gfz.4.8.2023.001), [original project PDF](https://www.reflect-h2020.eu/wp-content/uploads/2023/04/REFLECT_D2.3_mineral_solubility.pdf). The unchanged [local source](../../sources/REFLECT-D23-2023.pdf), SHA-256 `7e80e09592286370000ca0dfccc4ff8cfc0f287690ba40e14e02e0bf8c436e70`, is the authority. PDF page numbers match printed pages. This audit supersedes no original data file.

| Question | Original definition / finding | Status |
| --- | --- | --- |
| Pressure | p.22 §3.2.3.1 defines pCO2 as autoclave absolute pressure minus water vapor pressure at the particular T. p.23: CO2 bottle, regulated valves, air flushed for 15–20 min; sensors ±0.2 bar. | Resolved definition; not gauge pressure, total pressure or fugacity. Exact per-point gas composition/calibration not supplied. |
| Initial chemistry | p.22 §3.2.2: degassed deionised water and high-purity NaCl for saline preparations; Fig.22 panel selected is 0 wt% NaCl. 800 g solvent, 10–40 g calcite, predominantly Merck 10 μm powder. | Pure-water model is an approximation; per-point trace chemistry and solid loading unavailable. |
| Measured quantity | p.22: EDTA complexometry at pH 10, Eriochrome Black T endpoint, mean five titrations. This is calcium quantified by titration, not a measurement of free-Ca activity. Fig.22 reports calcite solubility in g/kg. | Compare total dissolved Ca converted stoichiometrically to CaCO3 equivalent. No explicit full dilution/conversion calculation or kg-denominator definition recovered. Retain both normalizations. |
| Equilibrium | p.23: electrical impedance varies less than 1% over 12 h; filtered 2 μm aliquots at system P/T; 1–3 further aliquots at 4 h intervals up to 24 h. | Operational equilibrium evidence. Not a thermodynamic proof or per-point approach-from-both-directions test. |
| Sampling | p.23: flushed ~10 mL discarded, collected into weighed bidistilled water below 100 °C to avoid depressurization precipitation; multiple P/T conditions may share a vessel charge. | Sample dilution and recovery are material, not modeled explicitly; pointwise worksheets unavailable. Do not assert sampling bias occurred. |
| Duration | p.25 says kinetic experiments start approximately 4–6 days after adjustment to pT conditions. | Do not assign that duration to each Fig.22 equilibrium point; they are separate procedures. |
| Uncertainty | p.22 usually <1% analytical uncertainty; p.23 ±0.1 °C control, ±0.2 bar pressure accuracy. | No per-point confidence level or full propagation. ±0.03 g/kg extraction bounds are not experimental uncertainty. |
| Mass basis | Fig.22 p.26 axis g/kg; surrounding methods do not explicitly distinguish kg solvent from kg final solution. | Unresolved; denominator change alone is tested, not assumed to fix the bias. |

The finite solid and numerical gas inventories are bookkeeping devices checked for nonexhaustion. Their endpoint insensitivity does not prove the exact experimental loading, headspace or depletion history has been reproduced. No evidence in these pages licenses fitting calcite log K or declaring incomplete equilibrium as the explanation.

## Second independent dataset screening

| Original source | What was found | Decision for v0.7.1 |
| --- | --- | --- |
| Plummer & Busenberg (1982), DOI [10.1016/0016-7037(82)90056-4](https://doi.org/10.1016/0016-7037(82)90056-4), publisher original article/abstract | ~350 measurements 0–90 °C, Ca-total/pCO2, and fitted calcite/carbonate constants. Full per-run tables were not recovered from the accessible publisher preview. These constants underpin common PHREEQC carbonate profiles. | Candidate data, not a completed independent validation: input tables missing here and database calibration lineage must be audited to avoid calling in-sample calibration data a holdout. Do not invent values from its fitted equations. |
| Ellis (1963), DOI [10.2475/ajs.261.3.259](https://doi.org/10.2475/ajs.261.3.259), [original open paper](https://ajsonline.org/article/58982-the-solubility-of-calcite-in-sodium-chloride-solutions-at-high-temperatures.pdf) | Original table explicitly uses mmol CaCO3 / 1000 g H2O and pCO2=12 atm; high-temperature NaCl experiments. | Identified usable future candidate for solvent-basis comparison, but outside current 23–80 °C pure-water endpoint contract and potentially shares carbonate-constant lineage. No extrapolated run or cross-experiment conclusion in this patch. |

No second held-out quantitative experimental comparison is claimed. To answer whether the bias is cross-experiment systematic requires an independently sourced, fully defined low-temperature high-pCO2 endpoint series and a calibration-lineage audit, not merely a second plot of REFLECT or reuse of thermodynamic fitted curves.
