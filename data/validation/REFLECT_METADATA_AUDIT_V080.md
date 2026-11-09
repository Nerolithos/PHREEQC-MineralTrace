# REFLECT metadata audit — v0.8.0

Original source: REFLECT D2.3, DOI [10.48440/gfz.4.8.2023.001](https://doi.org/10.48440/gfz.4.8.2023.001). Original PDF pp.22–23,25–26 reread; frozen five-marker data unchanged. Source SHA-256: `7e80e09592286370000ca0dfccc4ff8cfc0f287690ba40e14e02e0bf8c436e70`. [Machine-readable fields](REFLECT_METADATA_AUDIT_V080.json).

| Field | Value / unit | Exact source location | Kind / transcription confidence | Interpretation |
| --- | --- | --- | --- | --- |
| pressure_definition | absolute autoclave pressure minus water vapor pressure / bar | p.22, §3.2.3.1 paragraph 1 | reported / high | pCO2, not gauge pressure, total pressure or fugacity |
| selected_pco2 | [10.09, 23.2, 31.56, 39.85, 49.99] / bar | p.26, Fig.22 top-right pure-water panel, five purple markers | derived / digitization_bound_separate | Frozen digitization; not nominal exact pressure |
| temperature | 24.0 / degC | p.26, Fig.22 legend and purple markers | reported / high | Selected endpoint temperature |
| water_initial | 800 / g solvent | p.22, §3.2.3.1 paragraph 1 | reported / high | 0 wt% panel modeled as initially 0.8 kg pure water |
| aqueous_recipe | degassed deionised water; no added NaCl / recipe | p.22, §3.2.2 and Fig.22 p.26 | reported / high | Trace concentrations not quantified |
| trace_chemistry | UNKNOWN / mol/kgw | p.22, §3.2.2 | unknown / high | No invented trace concentrations |
| solubility_axis | g/kg calcite solubility / g/kg | p.26, Fig.22 ordinate | reported / high | Total Ca titration converted to CaCO3 equivalent; explicit worksheet not supplied |
| mass_denominator | UNKNOWN / kg | p.26, Fig.22 ordinate and methods pp.22–23 | unknown / high | Water versus final solution not explicit; preserve both |
| calcite_initial_range | [10, 40] / g | p.22, §3.2.3.1 paragraph 1 | reported / high | Range, not measured per-point assignment |
| calcite_per_point | UNKNOWN / g | p.22, §3.2.3.1 paragraph 1 | unknown / high | 10 g is declared stock control, not recovered measured loading |
| calcite_material | predominantly ultra-pure Merck, 10 micrometre / material | p.22, §3.2.2 | reported / high | Do not transfer Iceland spar preparation to Merck powder |
| reactor_capacity | 900 / mL | p.22, §3.2.3.1 paragraph 1 | reported / high | Nominal vessel capacity is not measured operational headspace |
| gas_control | CO2 bottle; reducing and metering valves; gas cap flushed 15–20 min / boundary | p.23, Fig.19 and paragraph 1 | reported / high | Supports regulated pCO2 approximation; valve history during each endpoint not supplied |
| operational_headspace | UNKNOWN / L | p.23, Fig.19 and sampling paragraphs | unknown / high | Do not infer 0.1 L from nominal vessel minus solvent |
| gas_purity | UNKNOWN / mole fraction | p.23, paragraph 1 | unknown / high | CO2 feed and air flush reported; exact impurities not given |
| analytical_observable | EDTA-derived dissolved calcium / total Ca | p.22, §3.2.3.1 last sentences | reported / high | Not free-Ca activity, not total inorganic carbon |
| analysis | EDTA complexometry at pH 10, Eriochrome Black T, mean five titrations / method | p.22, §3.2.3.1 last sentences | reported / high | pH 10 is analytical titration condition, not in situ fluid pH |
| analytical_uncertainty | usually below 1% / percent | p.22, §3.2.3.1 last sentence | reported / high | No pointwise confidence level or sigma |
| pointwise_uncertainty | UNKNOWN / g/kg | p.22, §3.2.3.1 last sentence | unknown / high | No uncertainty-weighted acceptance statistic |
| pressure_sensor_accuracy | 0.2 / bar | p.23, paragraph 1 | reported / high | Separate from digitization ±0.5 bar |
| temperature_control | 0.1 / degC | p.23, paragraph 1 | reported / high | Control accuracy, not pointwise experimental distribution |
| equilibrium_criterion | impedance change <1% for 12 h; 1–3 consistency aliquots at 4 h intervals up to 24 h / criterion | p.23, paragraph 2 | reported / high | Operational evidence, not guaranteed thermodynamic equilibrium |
| duration_per_point | UNKNOWN / h | p.23, paragraph 2; p.25 kinetic experiment opening | unknown / high | 4–6 days belongs to kinetic-start description, not every Fig.22 point |
| sampling | at system P/T; 2 micrometre filter; ~10 mL flush; weighed bidistilled water to avoid precipitation on pressure release / procedure | p.23, paragraphs 2–3 | reported / high | Pointwise dilution masses/worksheets absent |
| measured_endpoint_pH | UNKNOWN / pH | p.22, EDTA pH 10 is not endpoint pH | unknown / high | Calculated pH must never be labeled OBSERVED |
| measured_DIC | UNKNOWN / mol/kgw | p.22, EDTA measurement description | unknown / high | No total inorganic carbon measurement recovered |
| measured_net_solid_loss | UNKNOWN / g | p.22, range of starting stocks only | unknown / high | Stoichiometric model dissolution is calculated, not independently weighed |

Confidence refers to transcription, not scientific accuracy or probability of the interpretation. UNKNOWN does not mean zero. OBSERVED is reserved for experimental measurements; ASSUMED for modeling choices; CALCULATED for engine quantities; INFERRED for regulated-reservoir interpretation; UNDETERMINED for missing facts.

## Observable contract and conversions

`nCa = TOTMOLE("Ca")` includes aqueous calcium species; `LA("Ca+2")` is logarithmic free-ion activity and cannot be compared directly to EDTA total Ca. `GFW("CaCO3")` and `GFW("Ca")` are taken from each exact database, not fitted. `g/kg water = nCa × GFW(CaCO3) / mass_H2O`; `g/kg final solution = nCa × GFW(CaCO3) / (RHO × SOLN_VOL)`. `mg Ca/L = nCa × GFW(Ca) × 1000 / SOLN_VOL`. CaCO3:Ca molar ratio is 1:1. Actual formula weights and water/solution masses are archived per calculation. Baseline and Pitzer both emit GFW(CaCO3)=100.0911 g/mol and GFW(Ca)=40.08 g/mol; no formula-weight change contributes to the observed profile difference. Initial water mass and final mass of water are not interchangeable.

Model net calcite loss is stock minus final solid moles, not an independently measured weight loss. Calcite SI≈0 establishes equilibrium of the declared model, not experimental attainment. Calculated pH, DIC, CO2 activity, free Ca activity and solid loss have no matching measured values in this subset. The original report calls the analytical quantity Ca2+ concentration; EDTA complexometry does not establish an in-situ free-ion activity measurement.

## Boundary hypotheses

Fixed partial pressure is a supported approximation from bottle regulation and flushing. It is not fixed total pressure GAS_PHASE or fixed-volume finite gas. Valve timing, actual headspace composition and volume are unknown, so no finite-gas alternative can be quantitatively reconstructed without assumptions. No arbitrary headspace is introduced to improve residuals.
