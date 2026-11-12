# v0.8.2 implementation plan

1. Preserve v0.8.1 frozen observations, predictions, protocol and numerical source. Build a separate comparison extension over locked CSVs, field-level provenance and comparability; retain separate REFLECT mass-basis alternatives.
2. Add descriptive residual exports and calibration-lineage audit using actual locked blocks and cited historical snapshots. No fitting, pooled score, inferred missing chemistry or strict promotion.
3. Integrate cross-study references as separate applicability annotations; leave existing dimensions and strict gate intact.
4. Build a React/TypeScript/Vite local workbench around the existing DiscoveryStudy API. Reuse schema validation, candidate generation, engine execution, report/export and reproduction. Prefer one complete discovery workflow.
5. Use an isolated local job service with loopback binding, origin/request protections, bounded validated inputs, fixed trusted engine configuration, one active worker and whole-process-group cancellation. Preserve completed archives.
6. Verify unit/conversion/comparability and API lifecycle/security, run actual PHREEQC through GUI/API and CLI, compare deterministic analyses, run regression, document unresolved science and UI limits. No remote publication.

Architecture decision: existing package has only standard-library dependencies and frozen source. Keep numerical source unchanged. A Python-standard-library loopback HTTP/job supervisor calls a fixed Julia worker which loads the public API; frontend contains no chemistry. This avoids implementing a bespoke HTTP parser in Julia or changing the frozen package dependency graph. Python is already used by repository audit scripts. All schema/chemistry validation remains authoritative in Julia.
