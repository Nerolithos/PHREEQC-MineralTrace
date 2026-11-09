# v0.8.0 scientific validation and applicability — execution record

Date: 2026-11-09. Source version: 0.8.0. **Not a general experimentally validated model.** No remote tag/Release or registry publication is implied.

## Implemented and checked

| Acceptance item | Evidence / result |
| --- | --- |
| REFLECT systematic investigation | [Discrepancy report](REFLECT_DISCREPANCY_V080.md): seven declared controls × five unchanged observations; no parameter fitting |
| Metadata gaps explicit | [Structured original-source audit](REFLECT_METADATA_AUDIT_V080.json), source pages/locations, units, interpretation, provenance type and transcription confidence; missing denominator/per-point uncertainty/loading/headspace remain UNKNOWN |
| Pressure/fugacity semantics | Exact bar/atm conversion, pCO2 versus aqueous P, CO2 critical properties, inferred f/p, activities/log K/SI/Ca/DIC and official PR pressure–fugacity identity |
| Database applicability assessed | Structural coverage plus species/temperature/volume/gas fields; constant consistency/empirical range/calibration lineage not certified |
| Justified alternatives or missing inputs | Same-constant charged-ion activity diagnostic; disclosed whole-Pitzer legacy control; limiting ideal-gas/1-atm cases not accepted reconstructions; finite-gas reconstruction blocked by missing operational information |
| Profiles and registry | [Profiles](../models/profiles.toml), [evidence](../models/evidence.toml), runtime evaluators and source fingerprint checks; engine references cannot grant experimental support |
| Discovery annotations | Original 210 candidates keep 2 compatible / 201 incompatible / 7 undetermined proxy classes; actual order stays undetermined. Separate applicability remains unknown; no strict qualification |
| Official references | [Example 6A/B, 7 and 25 C Example 22](UPSTREAM_BENCHMARKS_V080.md), exact official source and selected references; direct/adapter agreement |
| Existing science preserved | Frozen observations hash unchanged; all 35 v0.7.1 predictions retained within 1e-10 g/kg; historical source tables/databases and comparison tolerances not altered |
| No unqualified certification | No current path profile is experimentally supported or strict-qualified; improvement under Pitzer is exploratory, not a validation pass |

## Verification

- [Full regression log](v080/test-output.txt): all existing engineering, evidence-graph, scan, titration, manual path, discovery, conservation, historical database and failure/archive tests pass. This run also exercised the new evaluator and candidate annotations.
- [Current candidate annotation checks](v080/annotation-test-output.txt): nine focused assertions, full actual 210-candidate example, unchanged classes and actual-order uncertainty, actual P/I telemetry, separate profile files/report.
- [Profile tests](../../test/model_profiles.jl): 31 assertions in the full log cover unit conversion, challenged/unknown/out-of-scope conditions, joint-point versus continuum evidence, missing thermodynamic species/gas properties, database/evidence fingerprint mismatch, and engine-versus-experiment independence. Unknown pointwise uncertainty never becomes a weighted acceptance statistic.
- [Official reference checks](v080/upstream-test-output.txt): seven targeted assertions pass; frozen reference comparisons do not update their own expected values.
- [Independent archival reproduction](v080/REPRODUCTION_AUDIT.json): scientific validation, upstream references and discovery `analysis.json` byte-identical under each export's own code/database/evidence snapshot. Scientific CSV and SVG also byte-identical. External PHREEQC executable supplied explicitly, exact executable hash retained.
- Real calculation [CSV](v080/comparison.csv), [SVG](v080/comparison.svg) and [JSON](v080/analysis.json). SVG rendered and visually inspected; no invented measurements, interpolation boundary or fitted curve.

The earlier full annotation run also checked each candidate individually; the maintained test groups its regression assertions to keep test-count growth from becoming the measure of scientific success. The execution log is retained as run, not edited to present a different count.

## Unresolved scientific limitations

1. REFLECT baseline high bias remains; one kg normalization change cannot remove it. No unique cause is assigned to log K, PR, aqueous activity or experimental handling.
2. Exact mass denominator, per-point analytical/dilution/loading information and operational gas history remain incomplete. Operational equilibrium evidence is not a thermodynamic proof.
3. Pitzer whole-profile changes cannot isolate an activity-equation effect; species/convention differences are exposed. Actual Ca and CaCO3 formula weights are identical between these profiles, so masses do not explain that difference.
4. Database calibration lineage, species completeness, consistency and empirical T/P/I domains remain incompletely qualified. Structural coefficient presence is not empirical support.
5. Five 24 °C points do not validate a continuous pressure range, another observable, a full reaction path, rates, nucleation or actual crystallization order. A second independently held-out quantitative experiment remains outstanding.
6. Discovery remains simplified Ca–F–C–O–H/Na/Cl, no gas/mixing/kinetics, externally imposed temperature and assumption-based phase inventories. No current profile loosens strict mode.

## Next justified milestone

Obtain a public, fully defined low-temperature high-pCO2 Ca + CO2/DIC endpoint series with pointwise uncertainty and a clear mass basis, and audit whether it was used to estimate database parameters. Freeze its protocol before predictions. Use that independent holdout to test the profile/speciation hypotheses highlighted here, rather than fit constants to the existing five points or add mechanisms/minerals/UI.
