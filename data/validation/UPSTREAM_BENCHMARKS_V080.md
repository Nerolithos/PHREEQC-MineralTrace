# Official PHREEQC reference benchmarks — v0.8.0

**Source type: engine_reference. Experimental support granted: false.** These tests assess upstream behavior and adapter invocation, not independently measured aqueous chemistry or natural mineral history.

## Versioned source and fixed protocol

Official [PHREEQC 3.8.6-17100 distribution](https://water.usgs.gov/water-resources/software/PHREEQC/phreeqc-3.8.6-17100.tar.gz). Original inputs are byte-preserved in [upstream-v080](upstream-v080/); [source archive/input SHA-256](upstream-v080/SOURCE.json). The exact official database is the pre-existing locked phreeqc.dat (`59373961d648dfbf68a40744060c1d64f57ecbec98f4f5fb89f3a1b4213ccd10`), never an automatically substituted database. Engine SHA-256 in this run: `c812189a98bc4667fcccfe28387924df3cc4b63fe714a943b5c41ae2df720f4a`.

Selected branches: Example 6A/6B (phase boundaries and prescribed cumulative reaction doses, no 6C kinetics); all Example 7 boundary branches; first 25 °C Example 22 fixed-volume branch only. Raw benchmark decks do not add these chemical systems, gases or temperatures to public discovery/endpoint APIs. Auxiliary experimental plotting files from the manual are not used as new validation data.

Each branch is run three ways: original official deck via direct CLI; the same branch with extra SELECTED_OUTPUT/USER_PUNCH via direct CLI; identical instrumented deck through MineralTrace. Instrumentation preserves original solver settings. The original selected outputs for Examples 6 and 7 are byte-identical after instrumentation; Example 22 original/instrumented printed pressure progression agrees. Instrumented selected outputs are byte-identical for direct versus adapter execution.

The initial instrumented experiment with `-high_precision true` changed unconstrained trace-redox pe in Example 6 because this option also tightens convergence settings. The final benchmark preserves original `-high_precision false`; this avoids a numerical-setting confound instead of loosening acceptance. No historical result or tolerance was rewritten.

## Recorded results

| Reference | Branch/result | Rows | Adapter vs direct | Locked reference |
| --- | --- | ---: | --- | --- |
| ex6 | 6A/6B only, no kinetics; {'incremental_path_rows': 14, 'phase_transfer_present': True, 'reaction_dose_progression': True} | 21 | byte-identical | agreement |
| ex7 | fixed partial, total pressure, and volume branches; {'fixed_partial_log_fugacity': -1.5001, 'fixed_partial_pressure_log_target': -1.5, 'fixed_total_pressure_atm': 1.1, 'fixed_volume_liters': 23.19} | 27 | byte-identical | agreement |
| ex22 | 25 C fixed-volume branch only; {'phi_min': 0.19101, 'pressure_fugacity_identity_checked': True, 'pressure_max_atm': 1452.2, 'pressure_min_atm': 0.031262} | 33 | byte-identical | agreement |

[Structured benchmark results](upstream-v080/benchmark-results.toml) include exact source/branch/instrumented input and reference hashes, engine banner and measured maximum differences. Independently generated version-matched selected reference tables are frozen in `ex6-reference.tsv`, `ex7-reference.tsv`, `ex22-reference.tsv`. They are not overwritten by the test script.

## Meanings and tolerances

- Engine reference: original version-matched inputs/database produce the expected branch behavior and locked reference values. Four-digit printed selected reference comparison uses predeclared atol=1e-7, rtol=2e-3; raw printed pressure comparison uses atol=0.01 atm, rtol=0.001. No precision-derived threshold is called an experimental uncertainty.
- Adapter agreement: exact input/database, same executable, selected output byte-identical; no numerical tolerance is needed for this comparison.
- Example 6B verifies prescribed reaction-dose progression and equilibrium solid stocks/transfers (official selected phase-transfer columns retained), not kinetic elapsed time or an invented crystallization order. It must not be confused with turning on `INCREMENTAL_REACTIONS` for every branch.
- Example 7 verifies fixed pCO2 initialization, fixed total gas pressure 1.1 atm where gas exists, and pressure evolution in fixed-volume 23.19 L gas. These are different physical boundary models.
- Example 22 verifies real high-pressure nonideality and the independent gas-pressure/fugacity identity `10^SI(CO2) ≈ PR_P × PR_PHI`. Its high pressures are upstream reference conditions, not an extension of the product endpoint contract or empirically certified range.
- Chemical conservation is separately checked for all 35 controlled REFLECT endpoints and existing process/path tests. This upstream table is not a claim that an independent experimental or complete mass audit was performed on every tutorial branch.
- Experimental agreement: not evaluated or granted by these engine examples. The embedded manual experimental curves are not converted to MineralTrace experimental evidence.

A future engine/database version must retain its exact fingerprint and any deviation from these fixed references. The script records `locked_reference_agreement` and the difference; it never rewrites the reference to force agreement. Changing databases for a matched benchmark is rejected. Historical Example 1 already establishes database/speciation version dependence under unchanged tolerances; that separate result is preserved.

## Reproduction

```sh
julia --project=. scripts/validate_upstream.jl results
# inside exported folder:
PHREEQC_EXECUTABLE=/absolute/path/to/phreeqc julia --project=. reproduce.jl
```

The export includes original/executed/instrumented decks, raw output, selected files, database and source/profile/evidence snapshots, executable/source identity and reproduction script. [Independent replay audit](v080/REPRODUCTION_AUDIT.json) confirms identical deterministic results. [Targeted checks](v080/upstream-test-output.txt) are separate from the existing full regression run.
