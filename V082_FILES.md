# v0.8.2 file map

- `scripts/compare_studies.py`, `data/validation/v082/`: frozen-input cross-study schema, comparability, statistics, plots, scientific and reproduction audits.
- `src/validation/CrossStudy.jl`, `src/validation/ModelProfiles.jl`, `data/models/`: separate cross-study applicability context with unchanged strict gate.
- `src/discovery/DiscoverySimulation.jl`: optional read-only progress callback, no chemical model changes.
- `workbench/`: React/TypeScript/Vite source and locked dependencies.
- `scripts/workbench_server.py`, `scripts/workbench_worker.jl`, `scripts/start_workbench.command`: local HTTP/job supervision and fixed Julia API bridge.
- `data/validation/frozen-v081/`, `scripts/validate_holdout.jl`, `scripts/reproduce_frozen_holdout.jl`: immutable pre-prediction runtime and compatibility launchers.
- `test/cross_study.py`, `test/cross_study.jl`, `test/workbench_api.py`, existing test entry/freeze test: provenance, scientific separation and actual API/CLI equivalence checks.
- `README.md`, `README.zh-CN.md`, `docs/WORKBENCH.md`, `IMPLEMENTATION_V082.md`, `data/validation/V082_STATUS.md`: usage, scientific boundaries and explicit delivery scope.

Generated build/dependencies and live result archives remain ignored. No remote publishing is performed.
