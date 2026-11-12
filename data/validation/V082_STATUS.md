# v0.8.2 execution record — 2026-11-12

## Completed

- Unified provenance-bearing records for both five-point external studies, retaining original units, sources/SHA-256, exact transformations, source/model assumptions and unknown fields. REFLECT's two mass-basis alternatives do not double the observation count.
- Field-level comparability for descriptive and exact matched-condition purposes. No directly comparable pairs; 25 conditional descriptive cross-study pairs, with no matched T/P pairs. Separate statistics and residual-versus-pressure, concentration and temperature plots. No pool, fit or uncertainty-weighted acceptance.
- Actual locked database/official historical block audit retained; dates distinguished and full calibration independence UNKNOWN. New retrieval attempt failed; archived primary evidence was preserved rather than reconstructed.
- Cross-study registry entry and profile references; separate `evaluate_research_applicability` annotations preserve all base fields and strict qualification. The cross-study audit is typed `cross_study_analysis`, not an independent experiment or engine benchmark.
- React/TypeScript/Vite local-first study editor, TOML import, evidence-source editing, validated search, asynchronous actual Julia/PHREEQC execution, progress/cancellation, candidate filtering/detail inspection, experimental/model audit page and reproducible exports. The HTTP supervisor is Python standard library; scientific validation/execution uses the fixed Julia worker/public API.
- Full original Julia regression passed, including selected official engine references, conservation, discovery/robustness, strict-mode safeguards and freeze tamper rejection. Eight new Julia annotation assertions; eight Python scientific tests; real HTTP lifecycle/security/equivalence integration test; successful production frontend build.
- Actual browser end-to-end 210-candidate run, two compatible surrogate outcomes, real per-step inspection, full ZIP download and CRC check, responsive layout checks. Independent rerun of exported GUI archive is byte-identical. 27-candidate API/CLI test is also byte-identical.
- Exact v0.8.1 pre-prediction runtime preserved in `frozen-v081`; the existing holdout CLI delegates to it. Recomputed frozen JSON, CSV and SVG are identical to the original results. No receipt or experimental prediction was updated to accept newer code.
- English/Chinese README, workbench guide, implementation plan, scientific report and reproduction audit.

## Partially completed

- Evidence editor edits existing sourced event/edge records; arbitrary supported structures are available in advanced JSON mode, not a complete dedicated creation UI.
- Archive opening supports completed discovery results under the installation's scoped results folder. General uploaded-archive import and arbitrary file picking are not provided.
- Experimental/model pages show structured references and residuals; detailed trajectory SVGs and all original provenance are accessible through the established report/export pipeline rather than a second frontend plotting implementation.
- Browser testing was executed and recorded through the available browser automation. Repeatable API assertions are scripted; no browser CI runner or external CI service is configured.

## Not implemented

Native installer, bundled Julia/PHREEQC, Windows certification, dark theme, general specimen/coexistence/photo/fluid-inclusion evidence management, arbitrary ZIP import, persistent job scheduling, cloud accounts, public deployment, new process families, kinetics, fitting, ML or mineral-database expansion. No remote release, package publication, commit or push was made.

## Scientifically unresolved

REFLECT's mass denominator and pointwise propagated analytical uncertainty; complete initial trace chemistry and per-point loadings; sampling/recovery differences; independent measured DIC/pH; exact measurement dates; full calibration lineage; cause of the opposite signs. No pressure-causal explanation, generally validated model or actual crystallization order is claimed. No strict-mode qualification is granted.

## Evidence and reproduction

- [Scientific report](v082/REPORT.md), [structured analysis](v082/analysis.json), [unmodified input lock](v082/INPUT_LOCK.json).
- [Reproduction audit](v082/REPRODUCTION_AUDIT.json), [API audit](v082/API_AUDIT.json), [browser end-to-end](v082/BROWSER_E2E.md).
- [Julia regression](v082/test-output.txt), [science tests](v082/science-test-output.txt), [API tests](v082/api-test-output.txt), [build](v082/frontend-build.txt).
- [Local workbench guide](../../docs/WORKBENCH.md).

Run `python3 scripts/compare_studies.py results/cross-study-v082` then `python3 results/cross-study-v082/reproduce.py`. Start the workbench as documented. Reproduce a completed discovery archive using its own `reproduce.jl`, source and database. The declared equality checks apply to the tested macOS environment only.
