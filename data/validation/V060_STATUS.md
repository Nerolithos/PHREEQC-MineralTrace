# MineralTrace v0.6.0 — bounded constraint-driven mechanism screening

Execution date: 2026-11-01. The automatic finite-path workflow is implemented and exercised end to end. **Full independent experimental reaction-path validation remains incomplete.** No actual crystallization chronology is confirmed.

## Delivered research task

```sh
julia --project=. scripts/discover.jl examples/discovery.toml results
```

Final report: [results/discovery-uhvHwF/report.html](../../results/discovery-uhvHwF/report.html).
Independent exported-source reproduction: [results/discovery-uhvHwF/reproduced/discovery-Aui0VU/report.html](../../results/discovery-uhvHwF/reproduced/discovery-Aui0VU/report.html).

All fluid, event, source-label and search assumptions in this example are **SYNTHETIC / SIMULATED**. It is not a natural specimen. No user-provided phase activation order or per-path event bindings are required. Both phases are simultaneously accessible during common initial equilibration and every environmental reaction operation; generation does not depend on the direction of the evidence edge.

The declared grammar includes equilibrium-only control, strictly monotonic cooling, HCl and NaOH formula increments and combinations up to depth two. Every legal discrete prefix is retained. Budgets, cumulative dose and all generated recipes are checked before engine execution; exceeded budgets reject the study instead of returning a biased partial best set. No hidden gas, mixing, carrier water, rate law or heat balance was introduced.

## Actual calculated outcomes

210 unique chemical candidates, 810 calculated states, 600 archived state handoffs. All aqueous + solid atom inventories, net-charge conservation and phase-direction tests pass their declared numerical tolerances. Maximum element residual across all elements/states is 1.000017846308765e-10 mol and maximum charge change is 3.460003551031265e-14 eq. Individual combined absolute/relative element tolerances are retained; these numbers are not experimental accuracy estimates.

Conditional equilibrium-surrogate screening: **2 compatible, 201 incompatible, 7 undetermined**. Both proxy-compatible examples sample initial pH 2.1:

| Candidate | Initial sampled coordinates | Environmental operations, dose in mol | First above-threshold post-baseline proxy positions |
| --- | --- | --- | --- |
| `candidate-d17c7a16ff0df250` | {'pH': 2.1} | NaOH 0.009 → NaOH 0.009 | {'C-I': 3, 'F-I': 2} |
| `candidate-d3bccf8a05fa3671` | {'pH': 2.1} | NaOH 0.009 → NaOH 0.005 | {'C-I': 3, 'F-I': 2} |

The first increment of 0.009 mol NaOH produces approximately 4.387184405303e-5 mol Fluorite at pH 3.278459250135. The second increment produces Calcite while both phases remain accessible. The two pathways are distinct dose hypotheses, not a unique answer or two independently confirmed histories.

Every candidate explicitly retains actual formation order = **undetermined**. First significant equilibrium solid gain is a disclosed screening surrogate, not nucleation time. An incompatible surrogate rejects only that finite model test; it cannot by itself refute the observed geological sequence. Initial-equilibration reactions, same-batch reactions, repeated mineral stages and missing sources remain unresolved. No observation or temporal edge is generated from SI or phase gain.

## Nonuniqueness and sensitivity

- Four qualitative response groups identify different paths with the same detected precipitation/dissolution/baseline/relative-proxy-order pattern. Equal group labels do not imply equal pH, reaction amounts or final inventories; full numerical trajectories are retained.
- Baseline: 60 paths, 1 conditional compatible / 58 incompatible / 1 undetermined.
- Resolution: same bounds, added temperature/dose/initial-pH samples; 210 paths, 2 / 201 / 7. No new qualitative group appears. This is not a continuum-convergence proof.
- Narrower initial-pH range, unchanged baseline environmental samples: 30 paths, 0 / 29 / 1. One qualitative response group is lost; the compatible pattern depends on the original range.
- Identical chemical candidates shared by grids are computed once by exact identity, including initial recipe, solid permissions/inventory, boundary and environmental sequence. Counts are not posterior probabilities or evidence strength.

Nominal measurements remain unchanged in the input archive. Generated range samples are labeled Assumption and retain the nominal source; unmeasured concentrations are not passed off as measured. The explicit 5% hypothetical-fluid charge diagnostic in this teaching example is not a universal analytical standard. No ion is adjusted. Legacy 0.1% semantics remain intact.

## Validation, kept separate

1. **Engine consistency:** a discovered candidate was replayed through direct PHREEQC CLI with the direct run's own solution dumps. Maximum difference over pH/T/charge, seven element totals and both phase stocks = 0.0. See [direct comparison](DISCOVERY_ENGINE_COMPARISON.md).
2. **Chemical consistency:** all 210 example candidates pass mass/charge/permissions; all 600 previous-dump handoffs, raw input/state/database/source/evidence hashes were independently checked. SVG XML and CSV record counts were parsed. See [export audit](v060-export-audit.json).
3. **Experimental comparison:** new calcite sources were screened, but none was used to invent a supported full-path benchmark. The promising closed titration uses KCl, finite titrant water and surface exchange; raw tables could not be visually verified from the publisher download in this run. The finite-headspace dissolution source does not match the no-gas boundary. Full experimental path validation remains unfinished; see [case review](EXPERIMENTAL_CASE_V060.md).

The final exported-source reproduction is byte-identical for analysis.json, candidates.csv, sensitivity.json, response-groups.json and generated-candidates.toml. Analysis SHA-256: `b24abc5ae54b3bd1daf46064cc957582b925e873a768faa3fcb677272db0ed11`. This establishes reproducibility in the tested engine environment, not independent experimental truth.

Full Julia suite: **1631/1631 passing**, including the existing 985 tests. New tests cover evidence-independent generation, budgets/stoichiometric bounds, invariant accessibility, missing/repeated evidence, proxy vs actual chronology, range/resolution comparisons, real state handoffs and direct CLI. See [full output](v060-test-output.txt).

Historical Example 1 benchmark separately retains its original three failures and exit code 1. No tolerance or historical value was relaxed; see [historical output](v060-historical-output.txt). Species/activity completeness and the 25–80 °C scope remain unverified. Strict discovery cannot certify a compatible model as independently validated.

## Acceptance mapping and remaining scope

| Requested outcome | Delivered status |
| --- | --- |
| No hand ordering of mineral reactions | Automatic environmental grammar, fixed all-phase access, no event bindings |
| Multiple legal chemical paths | 210 real computed candidates, no pH overwrites or phase toggles |
| Nonunique outcomes recognized | All candidates retained and four explicitly qualitative response groups |
| Chemistry vs artificial accessibility distinguished | No accessibility variation permitted in discovery; manual v0.5 scenarios remain a separate workflow |
| Compatible / incompatible / unknown | All three occur in actual calculations, with conditional-surrogate scope and actual chronology always unknown |
| Range and discretization checks | Separate baseline/resolution/range grids with sample and response differences |
| No unique geological-history claim | Explicit in schema outputs, CLI, standalone report, README and usage reference |
| Independent experimental path benchmark | **Not complete**; new source screening and unsupported conditions documented |

README now leads with the v0.6.0 user task, verified command, example findings, data configuration, reproducibility and scientific limitations. [Detailed usage](../../docs/DISCOVERY.md) and the version-file manifest are supplied. No package registration, remote tag or Release was published. Specimen formats, fluid inclusions, mixing, CO2 exchange, kinetics, expanded minerals, ML and new UI were deferred.
