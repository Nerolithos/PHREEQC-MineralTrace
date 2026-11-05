# v0.7.1 change inventory

Scope: REFLECT five-point discrepancy attribution, no added chemical mechanism or parameter fit.

- `Project.toml`: source version 0.7.1.
- `scripts/attribute_calcite_bias.jl`: locked observations/databases; seven declared controls, actual PHREEQC, conservation and telemetry, raw archive, offline report, deterministic exports/reproduction.
- `test/v071_attribution.jl`, `test/runtests.jl`: conservation of constants/observations in diagnostic transforms and pressure/EOS boundaries; full local suite 1685 passes.
- `data/validation/v071/`: original-source audit, protocol, two original and two explicitly derived database snapshots, calculated CSV/JSON/SVG, applicability evidence register, reviewable attribution report and verification record.
- `README.md`, `README.zh-CN.md`, `docs/CALCITE_ENDPOINT.md`, `docs/RELEASING.md`, `IMPLEMENTATION.md`: current purpose, command, scientific status and release notes.
- `data/validation/EXAMPLE1_ATTRIBUTION_V070.md`: explicit root-cause status; numerical history/tolerances unchanged.

Original v0.7.0 observations, source protocol, experimental comparisons and regression tolerances remain unchanged. Exact run archives under ignored `results/` are local artifacts, not a remote release. No General registration, remote tag or GitHub Release is asserted by this source update.
