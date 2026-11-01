# Independent experimental endpoint comparison — v0.7.0

A quantitative comparison with independently measured calcite solubility has now been performed. It exposes systematic overprediction; **it is not a passing full-profile validation** and does not validate a chemical time path, kinetics, pH or actual mineral formation sequence.

## Original observations and selection

Tjelta et al., REFLECT Deliverable D2.3 (2023), DOI [10.48440/gfz.4.8.2023.001](https://doi.org/10.48440/gfz.4.8.2023.001), original CC-BY-4.0 [PDF](../sources/REFLECT-D23-2023.pdf). Methods on pages 22–23 and the complete Figure 22 on page 26 were visually checked. All five purple 24 °C measured markers in the pure-water pressure panel were selected before predictions; dotted lines and other studies' points were not used. The native embedded raster and calibrated axes are recorded in the [source/protocol register](../sources/REFLECT-D23-2023.json). A [read-only extraction audit](../../scripts/check_reflect_digitization.py) reproduces the frozen [observation CSV](reflect-2023/observations.csv).

The solvent recipe is degassed deionised water, with 800 g initial solvent and excess commercial calcite. The report gives initial solid loadings of 10–40 g, not each point's exact loading. CO₂ pressure was bottle-regulated; temperature control is ±0.1 °C, sensor accuracy ±0.2 bar. Equilibrium was assumed after impedance changes below 1% for 12 h and subsequent consistency aliquots. EDTA analyses quantify total dissolved calcium, reported in the graph as CaCO₃-equivalent g/kg. They do not measure free-ion activity. General analytical uncertainty is described as usually below 1%, not a point-specific confidence interval.

No measured endpoint pH, independent net weight loss or per-point uncertainty is supplied for this subset. These fields remain absent/null. Graph extraction bounds (±0.5 bar, ±0.03 g/kg) are separate conservative numerical reading bounds, not measurement standard deviations. Pressure coordinates are digitized from the measured markers themselves rather than assumed to equal nominal legend pressure groups.

## Frozen model choices

The unmodified, previously locked PHREEQC 3.8.6-17100 phreeqc.dat is used; no solubility constant, activity parameter, concentration or pCO₂ was fitted to these observations. Native EQUILIBRIUM_PHASES maintains the specified CO₂ **partial pressure**, applying PHREEQC's Peng–Robinson correction; partial pressure is not silently substituted for fugacity. A nonexhausted numerical CO₂ inventory represents a regulated external reservoir, not a measured headspace volume.

The narrow CalciteCO2Endpoint API is limited to an explicit pure-water approximation and opt-in unvalidated conditions. Neutralization of solute-free model water is explicit in the input; it is not correction of measured ion concentrations. The main discovery model remains unchanged: no gas exchange, 1 atm, 25–80 °C exploratory range. A 24 °C, elevated-pressure experiment is never silently evaluated at 25 °C or used to certify that discovery profile.

The primary 10 g solid load is one edge of the reported range; 40 g is tested as a control, not guessed as the actual per-run mass. The 10 mol gas reservoir is a numerical buffer and is tested at 20 mol. A declared approximate 24 °C water-vapor correction of 0.03 bar relates solution pressure to pCO₂. Every calculation checks retained calcite, nonexhausted gas, Ca/C/H/O inventory including gas transfer and net charge. Stock/reservoir controls give unchanged predicted endpoint solubility to displayed precision.

## Quantitative result

| pCO₂ (bar, digitized) | Measured CaCO₃ equivalent (g/kg) | Model kg-water | Error % | Model kg-solution | Error % |
| --- | ---: | ---: | ---: | ---: | ---: |
| 10.09 | 1.882 | 2.163967 | 14.982 | 2.126052 | 12.968 |
| 23.2 | 2.267 | 2.925411 | 29.043 | 2.826516 | 24.681 |
| 31.56 | 2.53 | 3.242630 | 28.167 | 3.105619 | 22.752 |
| 39.85 | 2.758 | 3.486818 | 26.426 | 3.314797 | 20.188 |
| 49.99 | 2.879 | 3.717225 | 29.115 | 3.507718 | 21.838 |

Both possible graph mass normalizations are retained: current kg water versus final kg solution from PHREEQC density/volume. The graph does not explicitly settle that basis; choosing the better-fitting normalization is not allowed. Predictions overestimate the digitized observations by roughly 15–29% on the water basis and 13–25% on the solution basis.

Separate controls bracket pCO₂ by ±0.7 bar (extraction bound plus sensor accuracy) and T by ±0.1 °C, as well as solid and numerical-buffer inventories. They are individual controls, not a joint statistical confidence envelope. The remaining differences exceed the extraction reading scale and are not removed by stock/reservoir controls. No point-specific sigma, goodness-of-fit probability or invented acceptance band is reported.

Possible residual causes include activity/complexation and mineral thermodynamic data, gas/solution idealizations, mass normalization and experimental/sample handling effects. Their quantitative causal allocation has **not** been established; model tuning or blaming the measurements is not justified by this comparison alone.

## Validation levels and precise limits

- Direct CLI replay and exported-source reproduction assess engine/reproducibility separately from experimental accuracy.
- Element and charge closure are numerical checks, including explicitly counted CO₂ exchange.
- The five independent endpoints provide a non-fitted quantitative model challenge. The comparison is completed even though predictions disagree.
- Exact per-run reconstruction remains limited by per-point stock metadata, graph mass basis and missing raw analytical uncertainty. This bounded challenge is **not** full experimental qualification of the process model or a complete initial-to-final time-path benchmark.
- No kinetics, flow, mixing, specimen chronology, broad mineral/temperature/pressure validation or parameter calibration was added. The older limited log K comparisons remain distinct.

Run `julia --project=. scripts/validate_calcite_endpoint.jl results` with the configured engine/database. The output contains every primary/control calculation, both mass bases, signed errors, balances, original source/protocol, deterministic analysis and archived-source reproduction. Read it as a scientific result exposing model limits, not as a success badge.
