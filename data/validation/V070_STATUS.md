# MineralTrace v0.7.0 — scientific credibility and robustness

Execution date: 2026-11-01. The version adds independent quantitative endpoint comparison, threshold/local parameter analysis, and a controlled explanation of the historical reference mismatch. **It does not establish a validated general mineral-fluid model or actual crystallization chronology.**

## Most important scientific finding

The 2023 REFLECT calcite measurements were quantitatively challenged with the pre-existing locked database and predeclared, non-fitted model parameters. All five 24 °C, pure-water measured markers were selected and frozen before predictions. Thirty-five endpoint scenarios cover primary predictions and individual stock, numerical gas-buffer, pressure and temperature controls.

Predictions systematically exceed the graph-derived observations: about **+15–29% per kg water** and **+13–25% per kg final solution**. Both possible graph normalizations remain visible. None of the five points was removed, no concentration or thermodynamic constant was fitted, and the discrepancy was not made into a passing calibration test.

Final [independent endpoint report](../../results/calcite-validation-n1l1wm/report.html); [quantitative observations, assumptions and limitations](EXPERIMENTAL_CASE_V070.md). Original CC-BY source, DOI, extraction coordinates and frozen protocol are included. Source PDF SHA-256: 7e80e09592286370000ca0dfccc4ff8cfc0f287690ba40e14e02e0bf8c436e70. Frozen observation CSV SHA-256: 2e8df44966f958f0959c4f252124e8a0b55c5b4b3e4889a5799a328a0d12d805.

The plotted g/kg denominator, exact per-point solid loading and raw per-point analytical uncertainty are not established. The reported 10–40 g loading range is tested at its edges, giving identical endpoint solubility while solid remains present. Numerical gas buffers 10 and 20 mol likewise give identical predictions; they represent regulated supply, not measured gas-cap inventories. These checks support a bounded endpoint comparison without guessing a per-run mass. They do not remove the remaining metadata limitations or fully reconstruct the laboratory run.

There is no measured pH or independently measured net solid mass change for this selected subset. Predicted pH and modeled dissolution are recorded but not called validated observables. No time-path, rate or mineral chronology validation is claimed. A general analytical precision statement (“usually below 1%”) is not substituted for point-specific uncertainty or a statistical acceptance band. Reading bounds and individual sensitivity controls are separate.

## Minimal boundary needed for this experiment

CalciteCO2Endpoint provides only pure-water approximation + calcite + regulated CO2 partial pressure. It uses native PHREEQC equilibrium reactions and Peng–Robinson treatment of CO2, preserving the distinction between pressure and fugacity. The solution-pressure vapor correction is explicitly declared as a model approximation. Each run checks Ca/C/H/O including reservoir transfer, net charge, retained solid, gas nonexhaustion and attained phase equilibrium.

The 24 °C experiment is computed at 24 °C, with ±0.1 °C controls. The endpoint API's bounded opt-in conditions do not expand the production discovery profile. Discovery remains no-gas, 1 atm, 25–80 °C exploratory chemistry; strict mode remains unverified. Pure-water charge neutralization is explicit and limited to the solute-free water model, not measured-ion adjustment.

## Detection and parameter robustness

Final [robustness report](../../results/discovery-qktTgC/robustness.html), [plan](../../examples/robustness.toml), [usage](../../docs/ROBUSTNESS.md).

| Detection threshold (mol per operation) | Compatible surrogate | Incompatible | Undetermined | Flips from original |
| --- | ---: | ---: | ---: | ---: |
| 1e-8 | 2 | 201 | 7 | 0 |
| 1e-7 | 2 | 201 | 7 | 0 |
| 1e-6 | 2 | 201 | 7 | 0 |
| 1e-4 | 0 | 201 | 9 | 2 |

The same verified raw PHREEQC states are reclassified; detection thresholds do not change chemistry, pH or input concentrations. Original discovery results remain unchanged. All thresholds exceed numerical accounting tolerance and the original threshold is explicitly included.

One-at-a-time perturbations cover initial pH, Ca, F, temperature and second NaOH dose around the explicitly selected environmental anchor. Other conditions, inventories and accessibility remain fixed; no compensating ions are inserted. Seven new physical candidates are required beyond the 210 discovered candidates, for 217 total. All 838 states and 621 previous-dump handoffs pass the independent audit. Failures, if present, would remain unknown and archived rather than being dropped.

The example shows reaction/classification changes under pH, Ca and dose perturbations; F and temperature perturbations keep the qualitative pattern while changing reaction amounts above the declared reporting scale. Charge-review flags and reaction-signature changes are separate fields; a classification change is not automatically attributed to a different precipitation mechanism. Range-dependent net-amount spans are not intrinsic importance scores or global identifiability estimates.

The pH × second-dose projection fixes all other chemical input and environmental sequence. It displays 10 actual computed points and explicitly marks two uncomputed Cartesian combinations; the continuum between dots is also uncomputed. There is no interpolated phase boundary, shaded continuous feasible region, probability or unique history. Every candidate's actual formation chronology remains undetermined.

## Historical Example 1 attribution

[Controlled database attribution](EXAMPLE1_ATTRIBUTION_V070.md) and [all machine results](EXAMPLE1_ATTRIBUTION_V070.json) retain the original 0.01 SI tolerance and modern production database.

Using the same current executable/input with the unmodified official 2012-11-14 database gives Calcite 0.675419492902, Gypsum -0.6382460173182, Anhydrite -0.924585371458: all three reproduce the rounded manual within tolerance. The exact manual authors' binary/database commit is not invented; this is a compatible historical snapshot and controlled causal test.

Sodium bicarbonate/carbonate association changes localize the major calcite shift; sulfate-complex changes account for most sulfate-mineral shifts. With all historical aqueous-species data and current mineral phases, all three manual values again fall within tolerance. Diagnostic hybrids exist only in the attribution workspace and are not released as scientific database profiles.

This resolves the previous unspecified cross-version mismatch at the database/speciation level. Original modern-versus-historical comparisons still show their three differences and exit 1; their values/tolerance were not altered. Matched historical reproduction and locked modern regression are separate passing tests. Experimental accuracy is a third, distinct question.

## Engineering evidence and reproduction

Full suite: **1675/1675 pass**, preserving the previous 1631 tests. New checks cover explicit gas boundaries, native direct CLI replay, inventory closure, matched historical reference, cached-state integrity, threshold classification, OAT and uncomputed cells. [Full log](v070-test-output.txt). Original unmatched historical benchmark: 10 pass, 3 fail, exit 1 as expected; [retained log](v070-historical-output.txt).

Both final source archives match the current Julia implementation verbatim. Independent exported-source reproductions are byte-identical:

- Robustness: original analysis.json, robustness-analysis.json, threshold/parameter CSVs and sampled-plane SVG.
- Endpoint: analysis.json, comparison.csv and comparison.svg.

[Export audit](v070-export-audit.json) records hashes, paths and per-state accounting. Reproductions require the supplied engine binary; they use archived source/database/configuration rather than developer /tmp database paths. Byte identity applies to this tested binary/environment and is not a portable scientific-accuracy guarantee.

## Scope and remaining work

| Requirement | Result |
| --- | --- |
| Original independent observations and source | Five measured endpoints, DOI, CC-BY PDF, frozen extraction and read-only audit |
| Initial conditions without fitted missing values | Pure-water recipe, source-reported water and stock bounds, regulated pressure; unsupported exact metadata retained as unknown |
| Predeclared parameters and non-fitted comparison | Locked database and fixed scenario protocol, all points retained, signed/relative errors |
| Quantitative experimental test | Completed bounded endpoint challenge; systematic overprediction exposed |
| Fully qualified experimental/process model | **Not established**; source metadata and residual model discrepancy remain |
| Threshold and parameter robustness | Completed finite threshold reclassification and local OAT with discrete-only plane |
| Historical failure attribution | Controlled official snapshots plus diagnostic interventions; no production rebaseline |
| README and operating guidance | Updated value, commands, results and scientific limitations |

Next scientific work should obtain exact mass-basis/raw analytical metadata or a more completely specified low-pressure dataset and isolate the residual error with independently justified model comparisons. The current result does not justify parameter tuning to these five points or a scientific-success badge. Specimen input, general gas-path discovery, mixing, kinetics, new minerals, ML and GUI were deferred. No remote tag, package registration or Release was published.
