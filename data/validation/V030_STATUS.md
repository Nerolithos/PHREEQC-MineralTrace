# MineralTrace v0.3.0 — execution record, 2026-11-01

## Delivered behavior

Structured TOML evidence constraints, separate computation / chemical quality / model applicability / observation / final statuses, strict and exploratory modes, source/stage handling, sequential and leave-one-out contribution, grid-relative redundancy/conflict and disconnected included-grid components. No charge adjustment, ML, Web UI or inferred mineral chronology was added.

Legacy `status` still means raw SI compatibility. New `evaluation.final_status` is the final policy result; they must not be conflated. Legacy studies retain the disclosed exploratory / 0.1% default and all raw numerical outputs. New example configurations explicitly declare their policy and synthetic evidence.

## Executed tests

Actual environment: Julia 1.10.10, macOS ARM64; PHREEQC 3.8.6-17100; original bundled phreeqc.dat, SHA-256 `59373961d648dfbf68a40744060c1d64f57ecbec98f4f5fb89f3a1b4213ccd10`.

```sh
MINERALTRACE_INTEGRATION=1 julia --project=. test/runtests.jl
```

**531/531 passed; exit code 0.** [Full output](v030-test-output.txt). All 204 v0.2.0 checks remain in the suite; none were removed or loosened.

| Test set | Passed |
| --- | ---: |
| Existing DAG | 13 |
| Existing input/dependencies | 8 |
| Selected-output integrity | 8 |
| Existing study schema/SI logic | 19 |
| Equivalent arithmetic/new evidence schema | 18 |
| Quality modes/contribution/missing evidence | 29 |
| Existing real-engine execution/errors | 10 |
| Official Example 2 | 4 |
| Locked local engine regression | 5 |
| Existing Ca–F–C consistency | 59 |
| Existing scan/report/off-grid recovery | 66 |
| Tagged upstream reference/published parameter screening | 9 |
| Balanced/unbalanced real fluids, 42-point v0.2 regression, constraints/reporting | 271 |
| Existing timeout/nonzero-exit archives | 12 |

New logical evaluator fixtures are explicitly synthetic unit-test inputs, not PHREEQC results. Chemistry and regression integration tests execute actual PHREEQC. Structured source absence, stage mismatch, nonphysical/incorrect units, incompatible intervals, redundancy, leave-one-out, disconnected included cells and zero included points are exercised. Input and database fingerprint mismatches are rejected before reuse of a point's calculation.

Historical comparison remains a separate deliberate failing track:

```sh
julia --project=. scripts/benchmark.jl
```

Three historical table-11 failures remain, exit code 1; [log](v030-historical-output.txt). Tagged v3.8.6 Example 1 input/database match the locked distribution and its upstream rounded reference agrees within the unchanged 0.01 tolerance. The specific cause of the older manual table difference is still not isolated.

## Reports and numerical audit

Final exploratory demonstration: `results/study-sXitvn/report.html`; strict counterpart: `results/study-EsTIcJ/report.html`.

Both use the same 15 synthetic T–pH points and fluid inputs:

- 15 raw SI-compatible points; 14 chemical-diagnostic passes, one charge failure.
- Evidence/hypothesis filtering leaves six candidates; all are **included_conditional** under exploratory policy.
- Strict policy: zero included; the same six survivors remain **unverified**, with nine hard exclusions.
- No model profile is fully independently validated. These are not formation-temperature estimates, real measurements or natural geological conclusions.

The temperature and pH windows are explicitly supplied synthetic constraints. Reducing the grid with those windows is set filtering, not a new temperature measurement inferred by the software.

Contribution reports expose both SI/chemistry candidate and final-policy tracks. Strict final baseline is zero; candidate-track reductions are not mislabeled as strict final-domain reductions. Counts depend on axes, bounds and grid resolution and are not probabilities.

Actual commands:

```sh
julia --project=. scripts/mineraltrace.jl examples/evidence_constraints.toml results
julia --project=. scripts/mineraltrace.jl examples/evidence_constraints_strict.toml results
```

Independent reproduction was executed inside the exploratory exported folder with its archived package source, configuration and database. The reproduced **analysis.json is byte-identical**. Full `results.json` preserves different timestamps and runtime paths by design. All source/evidence hashes were checked; grid/constraint/evaluation/contribution CSVs and ten SVGs parsed successfully. SVG quality and final masks were rendered to PNG and visually checked. See [export audit](v030-export-audit.txt).

## Scientific validation and limits

[Chemical audit](CHEMICAL_QUALITY_AUDIT.md) identifies every original warning; [scientific validation](SCIENTIFIC_VALIDATION.md) separates engine regression, upstream reference, physical-chemical consistency and limited published-constant checks.

Published scalar log K checks pass but do not independently validate complete fluid compositions, activity corrections, all aqueous species or 25–80 °C. CaF+ is inactive in the locked database. Independent complete aqueous experiments and natural cases remain unvalidated. Missing source identifiers are not filled in, and current strict mode cannot self-certify a model profile.

All fixed/scanned chemistry, evidence definitions, raw inputs, diagnostics, source records, validation notes and software/database identifiers are archived. No concentration was silently modified and no unsupported temperature or chronology was produced.

Next milestone: register and independently reproduce a fully specified Ca–F–C experimental case, audit species/activity/temperature scope for a narrow validated profile, then permit that profile to satisfy the strict applicability gate. Preserve the current historical discrepancy and all existing regression tracks.
