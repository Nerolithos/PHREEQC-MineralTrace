# Scientific Model Validation & Applicability — v0.8.0

MineralTrace screens mechanisms conditional on declared chemistry and evidence. A successful engine call is not a statement of empirical accuracy, model applicability or geological history. This release adds scientific model/evidence management; it adds no mineral family, mixing, kinetics or web interface.

## Run and reproduce

Configure `PHREEQC_EXECUTABLE` and the locked official `PHREEQC_DATABASE` as in README. The official `pitzer.dat` must be alongside the latter; the baseline is never automatically replaced.

```sh
julia --project=. scripts/validate_scientific_models.jl results
julia --project=. scripts/validate_upstream.jl results
julia --project=. scripts/discover.jl examples/discovery.toml results
```

The first command writes standalone `report.html`, real point plots, both mass-basis comparisons, signed errors and unweighted descriptive metrics, gas/pressure/species telemetry, profile matches, raw inputs/output/dumps, source documents, database/profile/protocol/software snapshots and `reproduce.jl`. Keep the entire folder. In either scientific or upstream export:

```sh
PHREEQC_EXECUTABLE=/absolute/path/to/phreeqc julia --project=. reproduce.jl
```

No weighted statistical acceptance is calculated: per-point experimental uncertainty is UNKNOWN. Missing experimental, digitization, boundary and numerical uncertainty remain separate; model discrepancy is not an invented aggregate confidence interval.

## Model and evidence schemas

[Profiles](../data/models/profiles.toml) and [evidence](../data/models/evidence.toml) use TOML, loaded by `load_model_profiles()` / `load_evidence_registry()`. The registry verifies source files and SHA-256 fingerprints. Profiles include system/components/phases, required species, exact database identity, activity/gas/boundary, declared T/P/I review bounds, requested observables, nonordinal statuses, references, known discrepancies and unresolved limitations. Unknown schema fields or unsupported status claims are rejected.

Statuses `engine_verified`, `chemically_consistent`, `experimentally_supported`, `experimentally_challenged`, `applicability_unverified` and `out_of_scope` are not an ordered score. A profile may have several statuses. Current profiles have **no experimentally supported path observable**. Their interval bounds are declared review/execution envelopes, not independently established validity ranges; especially the ionic-strength review bound does not certify Debye–Hückel accuracy.

Evidence distinguishes independent experiments, official engine references and synthetic regressions. Each record has source identifier/type/hash/persistent ID, observable, joint experimental points, model assumptions, comparison method/numerical finding, limitations and conclusion. REFLECT was not fitted in this work; full database parameter-calibration lineage is UNKNOWN. Only independently qualified support records can support the corresponding observable. Engine examples can never grant experimental status.

```julia
using MineralTrace
registry = load_evidence_registry()
profiles = load_model_profiles(; registry)
study = load_discovery("examples/discovery.toml")
preflight = evaluate_applicability(profiles["discovery-cafc-386"], study,
                                   PHREEQCConfig(); registry)
result = discover_paths(study; profile_id="discovery-cafc-386")
```

For arbitrary explicit model queries, call `evaluate_applicability(profile, query; registry, database_audit=...)` with components, minerals, temperature_c, pressure_bar, ionic_strength_mol_kgw, boundary, gas_model, activity_model, database_sha256 and observable. The REFLECT point match also requires pco2_bar. Temperatures/pressures/ionic strengths may be scalar or vectors for a path; unknown values remain unknown. Missing initial ionic strength is never guessed from concentration totals; actual PHREEQC `MU` is used after execution.

Outputs are `applicable_documented_scope`, `outside_documented_scope`, `unknown_evidence` or `experimentally_challenged`, with matched/unmatched/unknown conditions and exact reference IDs. Outside scope is a documentation mismatch, not physical impossibility. Five measured joint conditions are not converted into a continuous interval or arbitrary Cartesian combinations. A request for pH, path, kinetics or chronology cannot inherit total-Ca endpoint evidence.

## Discovery integration and strict mode

Each candidate gains separate `model_applicability` metadata and report/export entries: profile ID, match status, conditions, challenged/supported observables, unsupported extrapolations and reference IDs. `model-profile.toml`, `database-audit.json`, `model-applicability.json` and the archived evidence registry preserve the basis of the annotation. Database fingerprint mismatches are explicit. The existing chemistry, proxy screening, conservation and `formation_order_classification` are not overwritten.

Strict mode retains its existing undetermined applicability gate. No present profile can qualify it. The evaluator's `strict_qualified` requires independent support for the **equilibrium path** observable, not merely profile existence, an engine example or a matching endpoint. This release does not loosen the old gate even if a user writes a positive flag in a file.

Mineral inventories are sourced model boundary assumptions; they are not assumed measured deposit tonnages. Actual nucleation, crystallization time and chronology remain undetermined. Positive SI is a saturation opportunity; an equilibrium solid increment is a model reaction, not independently observed formation.

## Audit coverage and limitations

`audit_database` examines named PHASES/SOLUTION_SPECIES blocks, required coverage, temperature coefficients, volume parameters, activity family and CO2 critical properties. For fixed partial pressure, the native gas target is log10(p/atm), not log fugacity. Availability of critical parameters is distinguished from their actual numerical effect, checked from aqueous activity and phase log K. `phi=f/p` is inferred for EQUILIBRIUM_PHASES; GAS_PHASE `PR_P`/`PR_PHI` are used only in the upstream gas benchmarks.

This is a deliberately narrow structural audit. INCLUDE$ dependencies are not expanded and therefore make coverage incomplete. Coefficient presence does not prove a physically appropriate temperature/pressure correction; species presence does not prove complete chemistry. Unrecognized activity conventions, species sets or calibration lineage remain unverified. Pitzer lacks some explicit ion pairs used in the baseline and has different interaction conventions: the inherited whole-profile control is not an isolated activity-model test or a certified substitute. Ideal-gas and 1-atm aqueous-pressure controls are labeled limiting diagnostics, not accepted high-pressure reconstructions. Finite-gas REFLECT alternatives cannot be calculated without inventing operational headspace/valve data.

## Primary references studied

- [USGS input manual](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3.htm), [limitations](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-2.htm): database consistency and careful species/data selection require review, not certification by engine success.
- [SOLUTION](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-48.htm), [PHASES](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-36.htm), [EQUILIBRIUM_PHASES](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-13.htm), [GAS_PHASE](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-17.htm): explicit inventory, phase permissions, activity conventions, total versus partial pressure and finite-volume boundary distinctions.
- [REACTION](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-41.htm), [REACTION_PRESSURE](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-42.htm), [REACTION_TEMPERATURE](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-43.htm): real stoichiometric reaction and externally imposed T/P, not independent pH overwrites or kinetic time.
- [SELECTED_OUTPUT](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-45.htm), [USER_PUNCH](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-60.htm), [SAVE](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-44.htm), [USE](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-57.htm), [DUMP](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-12.htm): output observables and complete-state preservation. High-precision output also changes convergence settings; official benchmarks preserve upstream settings.
- Official [Example 6](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-68.htm), [7](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-69.htm), [22](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-84.htm): reaction paths, distinct gas boundaries and nonideal high-pressure gases. Version-matched source branches are vendored with fingerprints; these are engine references, not new experimental validations.
- Lu et al. (2022), [DOI 10.1016/j.earscirev.2021.103888](https://doi.org/10.1016/j.earscirev.2021.103888): database species, activity convention, T/P coverage, consistency and traceability differ. Publisher abstract/overview studied; full publisher/NSF manuscript retrieval was unavailable in this session, so no unseen table-specific claims are made.

The original REFLECT PDF was reread for metadata, not replaced by prior generated reports. See [metadata audit](../data/validation/REFLECT_METADATA_AUDIT_V080.md), [discrepancy report](../data/validation/REFLECT_DISCREPANCY_V080.md) and [upstream benchmarks](../data/validation/UPSTREAM_BENCHMARKS_V080.md).
