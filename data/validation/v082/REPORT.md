# v0.8.2 — Cross-study discrepancy audit

No directly comparable pairs exist among these two five-point experimental series. All 25 water-basis cross-study pairs are conditionally comparable for descriptive purposes; none is a matched-condition test. REFLECT's two mass-basis scenarios are alternative interpretations of five observations, not ten independent measurements.

Both sources define CO2 partial pressure and describe regulated gas supply. REFLECT uses autoclave pressure minus vapor pressure; Ferreira tabulates pCO2. Matching this label does not recover exact gas history. Their pressure domains do not overlap (10.09–49.99 versus 1.013–2.146 bar), temperatures are 24 and 25 °C, analytical methods and sampling definitions differ, and initial trace chemistry is unknown. REFLECT's kg denominator remains unresolved.

Residual signs are positive for all five REFLECT observations on either declared mass basis and negative for all five Ferreira means. Within-series trends are descriptive only. Temperature is constant within each series; its two-study contrast is confounded, not a sensitivity experiment. No pooled RMSE, fitted trend, weighted acceptance, universal bias correction or pressure explanation is warranted.

## Separate descriptive statistics

- water_hypothesis: n=5, mean signed error=6.43424, MAE=6.43424, RMSE=6.70902 mmol CaCO3-equivalent/kg water; mean relative error=25.547%, max absolute relative error=29.115%.
- solution_hypothesis: n=5, mean signed error=5.12473, MAE=5.12473, RMSE=5.30415 mmol CaCO3-equivalent/kg solution; mean relative error=20.485%, max absolute relative error=24.681%.
- water_reported: n=5, mean signed error=-0.682692, MAE=0.682692, RMSE=0.849584 mmol CaCO3-equivalent/kg water; mean relative error=-5.634%, max absolute relative error=10.404%.

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
