# v0.8.1 — External experiment and holdout qualification

Date: 2026-11-09. Source version 0.8.1. No remote Release/tag or General publication is asserted.

**Second independent-source prediction comparison completed; strict database-calibration holdout qualification pending.** Five fixed 25 C means from another laboratory yield central errors −1.246% to −10.404% with the unchanged production model. No thermodynamic parameter or REFLECT datum was fitted or altered.

| Dimension | v0.8.1 result | Meaning |
| --- | --- | --- |
| Engine/adapter consistency | Existing official reference and process tests pass; new endpoint telemetry replay agrees | Implementation consistency, not empirical accuracy |
| Chemical accounting | All 40 endpoint/control calculations pass element/charge and phase-boundary checks | Declared numerical bookkeeping closes |
| Experimental comparison | All five central predictions below measured means; first two differences small, higher-pressure differences larger | REFLECT's positive direction is not repeated in this different low-pressure/25 C domain |
| Model applicability | New challenged endpoint evidence registered with calibration independence UNKNOWN; no strict profile promotion | External-source comparison does not establish fully out-of-calibration holdout or path support |

[Scientific report](v081/REPORT.md) · [Source/qualification audit](holdout-ferreira-2025/SOURCE_AUDIT.md) · [Frozen protocol](holdout-ferreira-2025/PROTOCOL.toml) · [Pre-prediction receipt](holdout-ferreira-2025/FREEZE.toml) · [Actual comparisons](v081/comparison.csv).

## Verification

- [Full real-engine regression](v081/test-output.txt) passes, preserving evidence graph, scans, titration, paths, discovery's 2/201/7 proxy classes, actual chronology uncertainty and official engine references.
- [Eight targeted checks](v081/freeze-test-output.txt) pass: exact freeze identities, conversions, source qualification, exact point evidence matching and tampering rejection before any engine execution.
- [Independent reproduction audit](v081/REPRODUCTION_AUDIT.json): exported code/data/database reproduces `analysis.json`, `comparison.csv` and `comparison.svg` byte-for-byte. All frozen files retain their pre-prediction hashes. Upper stock/reservoir controls change endpoints less than 1e-8 mmol/kg.
- [Lineage audit script](../../scripts/audit_holdout_lineage.py) reproduces the recorded normalized block comparison without modifying either database.
- Actual SVG was rendered and visually inspected; it displays published duplicate SD separately from reported standard uncertainty and uses only calculated predictions.
- Original REFLECT data, v0.7/v0.8 numerical reports, thermodynamic snapshots and comparison tolerances remain intact. Prior v0.8.0 implementation work is preserved.

## Unresolved limits

Database parameter-calibration independence is UNKNOWN: related measurements existed in 2022 and relevant aqueous parameters changed afterwards; no citation is not proof of nonuse. Primary publisher source is a preserved text retrieval transcript, not an original PDF-byte fingerprint. The related thesis is not counted as another independent dataset. No measured DIC/CO2 or independent endpoint pH is available in the selected subset, filtration cutoff and exact loadings/gas history are incomplete, and uncertainties are not combined without a covariance model.

The two experiments occupy different T/P domains and use different methods. Opposite residual directions do not establish pressure or any other single cause, nor validate the model generally. Next seek matched-condition raw Ca + CO2/DIC measurements and documented parameter lineage; do not fit a correction or expand mechanisms yet.
