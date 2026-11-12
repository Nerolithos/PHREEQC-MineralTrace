# Local research workbench — v0.8.2

The React + TypeScript interface drives the existing Julia `DiscoveryStudy` / `discover_paths` / `report` APIs. It is a local research preview, not a geological-history identification service. No account, cloud database, remote execution or telemetry is required.

## Install once

Requirements: Julia 1.10+, PHREEQC 3 CLI and its database, Python 3.11+ (standard library only), Node.js 20.19+ and npm for the interface build. The tested environment uses Julia 1.10.10, PHREEQC 3.8.6-17100, Python 3.12.5 and Node 20.20.2 on macOS ARM64. Windows and Linux have not been verified for this release.

From the repository root:

```sh
npm ci --prefix workbench
npm run build --prefix workbench
export MINERALTRACE_JULIA=/absolute/path/to/julia
export PHREEQC_EXECUTABLE=/absolute/path/to/phreeqc
export PHREEQC_DATABASE=/absolute/path/to/phreeqc.dat
python3 scripts/workbench_server.py
```

Open http://127.0.0.1:8765. `scripts/start_workbench.command` is a macOS launcher after building; it uses the trusted launch environment (Finder-launched processes may not inherit shell variables). If Julia and PHREEQC are not discoverable, launch from a configured terminal. This release does not include a bundled installer or native file-picker for engine configuration. Once launched, no TOML editing or Julia commands are needed for the supported research workflow.

The service is Python standard-library HTTP/job supervision with a fixed Julia worker. This is an intentional deviation from a Julia HTTP framework: no extra Julia dependency graph, bespoke HTTP parser or rewrite of scientific logic. `scripts/workbench_worker.jl` performs authoritative schema validation and runs the public API. All displayed chemistry comes from Julia/PHREEQC; no frontend speciation or conservation implementation exists.

## Study → Run → Results → Export

1. **Overview:** create from the visibly synthetic example, import an existing discovery TOML, or open a completed archive from this installation's `results` root. Import validates the complete schema; unsupported evidence is not dropped.
2. **Study:** edit initial fluid pH/pe/temperature/water and all declared totals in mol/kg water. Select Calcite/Fluorite, inventories and reaction permissions. All declared phases remain accessible throughout every path. No charge repair is applied.
3. **Search:** choose equilibrium, cooling, HCl and/or NaOH; edit explicit candidate/depth/reagent budgets and reaction threshold. All three baseline/resolution/range grids remain visible and must satisfy existing nesting/range rules. Empty or unapplied sample edits block submission. The local workbench permits at most 400 distinct candidates (CLI retains its original 2000 limit).
4. **Evidence:** edit source, provenance, event descriptions and interpreted relative relationships. Example sources explicitly say synthetic. Selecting Observation does not create a measurement; only use it with real sourced observations. Advanced mode exposes the complete supported schema as editable JSON and validates before applying. New arbitrary event schemas, specimen management and standalone photo/coexistence/fluid-inclusion measurement editors are not implemented.
5. **Validate:** Julia constructs the existing study and enumerates candidates without an engine calculation. Every preset is explicit; no missing measured concentration becomes an example default. Numeric unknowns are rejected rather than changed to zero.
6. **Run:** an asynchronous worker reports actual completed/total candidate counts. The UI remains navigable. No guessed ETA is shown. One job at a time; repeated request IDs are idempotent. Cancellation kills the worker process group, retains partial raw work and does not publish a partial run as a completed archive.
7. **Candidates:** filter compatible surrogate/incompatible/undetermined, sort, inspect operations and each candidate's pH, temperature, solid increments, charge diagnostics, full accounting, evidence checks and applicability. Raw JSON is expandable. Step number is not time. No continuous feasible-region interpolation or probability is inferred from sampled counts.
8. **Validation:** experimental challenges, engine references and model profiles are separate. The chart shows frozen residuals and units; uncertainty is preserved in source records, not turned into invented error bars. REFLECT's denominator alternatives are five points interpreted two ways, not ten independent experiments.
9. **Export:** download the complete ZIP, original configuration, CSV/JSON, provenance and reproduction script, or open the established scientific HTML report. All SVG trajectory plots are in that report and ZIP. Keep the complete folder; a CSV alone is not the reproducibility record.

Archive opening is scoped to completed discovery folders already present under the fixed results root or this service's own jobs. Arbitrary directory selection and uploaded ZIP extraction/execution are intentionally unsupported. Job progress is session-local; after a server restart, completed archives can be reopened, but old in-memory job IDs are not resumed.

## Scientific semantics

- OBSERVATION: sourced measurements or recorded textures.
- ASSUMPTION: initial scenarios, phase permissions, environmental grammar and numerical boundary idealizations.
- CALCULATION: PHREEQC states, transfers and conservation diagnostics.
- INFERENCE: conditional evidence screening under a declared equilibrium-increment rule.
- UNKNOWN: missing metadata, unsupported observables and real crystallization chronology.

An equilibrium precipitation or dissolution increment is a model response under declared conditions. It is not a measured crystallization event or a geological age. Within documented profile conditions is not equivalent to experimentally validated. Official engine-reference agreement is not experimental agreement. Actual mineral chronology remains undetermined, including green/compatible candidates.

## API, resource limits and trust boundary

GET: `/api/health`, `/api/examples`, `/api/archives`, `/api/archives/{id}`, `/api/jobs/{id}`, `/api/jobs/{id}/results`, `/api/validation/comparisons`, `/api/models/profiles`.

POST: `/api/studies/validate` (`{study}`), `/api/studies/import` (`{toml}`), `/api/jobs` (`{study,request_id}`), `/api/jobs/{id}/cancel` (`{}`). Responses use structured errors. The source example and Julia schema define the supported study object; TypeScript uses the same returned structure.

The service binds only `127.0.0.1`; Host and Origin checks reject cross-origin requests, mutations require a per-session header token, and no cross-origin permissions are enabled. Executable/database paths are trusted administrator environment configuration, never browser inputs. No arbitrary commands or unrestricted filesystem reads are exposed. Archive paths are opaque scoped IDs; path traversal and symlink escapes are refused. This is a local tool, not an authenticated public server; do not proxy it onto a network.

Limits: 128 KiB requests, 400 candidates, one active job, 100 jobs per session, 30 s per engine step, 30 min per job, 25 MB individual file responses, 150 MB uncompressed ZIP export. Complete raw archives can be large; browser ZIP creation may take minutes for the full example. Export locally from the result directory if the size limit is exceeded. Process-group cancellation currently targets POSIX/macOS; native Windows support is not claimed.

## Reproduction and tests

The existing CLI still works:

```sh
julia --project=. scripts/discover.jl examples/discovery.toml results
```

In an exported discovery folder:

```sh
PHREEQC_EXECUTABLE=/absolute/path/to/phreeqc julia --project=. reproduce.jl
```

The frozen Ferreira protocol has its exact v0.8.1 runtime in `data/validation/frozen-v081`. The existing `scripts/validate_holdout.jl` CLI delegates to that runtime; its original script, source and receipt remain byte-identical inside the snapshot. No freeze receipt is rebaselined to v0.8.2. Direct `validate_holdout()` calls against a changed runtime still correctly refuse drift.

```sh
python3 test/cross_study.py
python3 test/workbench_api.py  # actual Julia + PHREEQC configured in environment
MINERALTRACE_INTEGRATION=1 julia --project=. test/runtests.jl
```

The API test checks invalid schemas/unknown values, forbidden paths, origin/token checks, candidate limits, duplicate submission, concurrency, real cancellation with preserved partial work, completion, error propagation, ZIP export and exact CLI/API analysis equality. Browser end-to-end checks and responsive screenshots are recorded in [v0.8.2 browser audit](../data/validation/v082/BROWSER_E2E.md). Equality is tested on this environment, not claimed across platforms.
