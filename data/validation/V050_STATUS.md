# MineralTrace v0.5.0 — Reactive Mineral Path Explorer

Execution date: 2026-11-01. The finite-path research workflow is implemented; complete independent experimental reaction-path validation remains unfinished. No geological history is confirmed by this release.

## Concrete delivered task

Run:

```sh
julia --project=. scripts/paths.jl examples/reactive_paths.toml results
```

Final artifact: `results/paths-Tz30LX/report.html`.

One explicitly sourced **SYNTHETIC / SIMULATED** initial fluid, two candidate paths and one independently supplied teaching edge F-I → C-I are compared. Both paths cool 80 → 60 → 40 °C and explicitly permit phase contact in different orders. No fluid parameter or event correspondence is inferred or invented.

- `fluorite_then_calcite`: conditionally compatible with the supplied user correspondences. Modeled Fluorite solid gain is about 1.8983e-4 mol at its contact operation; later Calcite gain is about 2.6508e-4 mol.
- `calcite_then_fluorite`: incompatible with the particular F-I → C-I constraint under its explicit correspondences. Both modeled reaction events occur, but their assigned operation indices reverse the supplied order.
- These labels test the specified hypotheses, not all possible fluids or alternative correspondences. Activation order is itself a declared assumption, not independently predicted chronology. Strict mode leaves unknown model applicability unresolved.

The example's 0.5% charge diagnostic is explicitly a synthetic teaching policy, not a universal water-quality criterion or a fit to natural data. Existing 0.1% legacy warnings are unchanged.

## Mineral and thermal semantics

Calcite/Fluorite phase stocks, target SI and precipitation-only/dissolution-only/bidirectional permissions are explicit. Positive solid gain is precipitation, negative is dissolution; aqueous formula transfer is the opposite sign. Zero initial stock cannot dissolve. Exhausted phases may remain below target SI. Every operation explicitly lists its active phases; other declared stocks are retained but isolated from the reacting water.

The system is element-inventory closed except for explicitly declared neutral HCl/NaOH additions. It is not thermally isolated: temperature is externally imposed, and no heat/enthalpy budget is calculated. No implicit gas exchange, fluid mixing, rock reservoir, carrier water, kinetic law or unlisted mineral activation occurs.

Each operation executes real PHREEQC, saves the complete solution through DUMP/SOLUTION_RAW and passes that state to the next calculation. Solid stocks use high-precision EQUI values. Every state and auxiliary input has an archived SHA-256; no pH/total-only reconstruction approximates the previous fluid.

Conservation and phase-direction permissions are hard constraints. An offending candidate stops; evidence fit cannot compensate. The budget includes aqueous and retained/active solid Ca/F/C/Na/Cl/H/O inventories and the explicit reagent atoms. H/O initial aqueous inventories come from the engine; other initial aqueous quantities are checked against user mol/kgw × water kg. This is numerical accounting, not proof of a complete measured initial fluid.

## Three evidence levels

1. Post-operation saturation opportunity: SI only; no first-SI-crossing chronology.
2. Modeled equilibrium event: actual signed stock change above a declared threshold greater than absolute numerical tolerance.
3. Independently supplied observed event: user source, event kind and explicit correspondence; never manufactured by the model.

Same-batch precipitation of two minerals leaves internal order undetermined. Missing event source, no correspondence, unmodeled event, opportunity-only correspondence and strict applicability uncertainty are retained rather than converted into a unique answer. Dissolution cannot be used as a surrogate for a formation event. The existing DAG reports cycles without removing conflicting edges.

## Verification executed

Julia 1.10.10/macOS ARM64; official PHREEQC 3.8.6-17100; database SHA-256 `59373961d648dfbf68a40744060c1d64f57ecbec98f4f5fb89f3a1b4213ccd10`.

```sh
MINERALTRACE_INTEGRATION=1 julia --project=. test/runtests.jl
```

985/985 checks passed, exit 0. Existing v0.4.0 checks remain intact; the new focused checks cover phase permissions, finite stock exhaustion, actual temperature/reagent paths, complete saved-state continuity, evidence levels, ambiguity, hard constraints and direct CLI comparison. The count is an engineering record, not the success criterion or scientific certification. Full output: v050-test-output.txt.

The representative five-state path was replayed independently through the direct CLI with that run's own solution dumps. Maximum difference over pH, temperature, aqueous Ca/F/C moles and both phase inventories was 0.0; see PATH_ENGINE_COMPARISON.md. This is engine consistency, not independent experimental validation.

The final two-path export contains ten calculated states, 20 mineral-step CSV records, 70 element-balance records and nine SVGs. CSV/XML parsing, source/evidence/input/state hashes and every state handoff were independently checked. Maximum total element residual was about 7.16e-12 mol; maximum net-charge change about 2.00e-16 eq, within declared numerical tolerances. SVGs were rendered and visually checked.

Independent reproduction inside the exported workspace produced **byte-identical analysis.json**. Full results.json intentionally retains different runtime provenance. See v050-export-audit.txt.

The separate historical Example 1 manual comparison was rerun: three known failures remain, exit 1; v050-historical-output.txt. No historical reference or tolerance was changed. Version-matched upstream and local regression tracks remain distinct.

## Real-source validation: completed and blocked portions

The original Brown–Roberson 1977 laboratory dataset was inspected at methods, measurement table and conclusion level. Actual Ca/F measurements and missing fields are registered, with source pages and PDF hash. The reported derived zero-strength log K −10.58 with analytical uncertainty ±0.17 was compared with the engine value −10.5996756161. Signed difference −0.0196756161 lies within that reported uncertainty.

This is limited parameter consistency against an experimental source, potentially sharing thermodynamic lineage, not full aqueous-path validation. The full closed-path benchmark is rejected because initial carbon, atmospheric gas exposure and minor-ion inventory cannot be reproduced without guessing. Unmeasured initial pH/carbon were not filled in, and source scatter ±0.01 was not substituted for full analytical uncertainty. See REACTIVE_PATH_VALIDATION.md, fluorite-experimental-case-v050.json and fluorite-experimental-comparison-v050.toml.

A fully independently reproduced experimental reaction pathway and a natural paragenetic case remain unvalidated. There is no certified complete model profile. The software's compatibility labels remain conditional on phase definitions, activity/species coverage, the exploratory temperature domain, user quality policy and actual evidence interpretation.

## Next priority

Obtain a fully specified equilibrium mineral–fluid experiment with complete initial inventory and gas boundary, independently measured observables and uncertainty, then validate that narrow profile before certifying applicability. Only afterward add a real specimen's sourced texture events and test rejection of genuine alternative paths. Do not use activation order, arbitrary pH adjustments or fitted missing concentrations as validation evidence. No Studio/Web UI, ML or broad mineral database was developed.
