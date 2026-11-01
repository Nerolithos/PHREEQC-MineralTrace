# README redesign notes

Reviewed 2026-11-01. The references below were inspected for information structure and scientific-software presentation. These are design references, not dependencies or endorsements. The project prose is original; no logos, adoption claims or status badges were copied.

| Reference | Observed pattern | Application to MineralTrace |
| --- | --- | --- |
| [Reaktoro README](https://github.com/reaktoro/reaktoro/blob/main/README.md) | A short purpose statement, capability list and a clear handoff to documentation | Keep the landing page about the mineralogical question; send full schemas and archived investigations to guides |
| [Cantera README](https://github.com/Cantera/cantera/blob/main/README.rst) | Task-oriented capabilities, installation guidance and several documentation starting points | Put runnable CLI commands and task-to-guide navigation on the page; make the external PHREEQC dependency explicit |
| [pymatgen README](https://github.com/materialsproject/pymatgen/blob/main/README.md) | Centered visual identity/status links, a concise description, reasons to use the project and contribution/citation routes | Use a restrained centered header and factual badges, explain research value, and provide an issue/research-use route |
| [ModelingToolkit README](https://github.com/SciML/ModelingToolkit.jl/blob/master/README.md) | Documentation links, executable examples and figures that demonstrate the code's output | Pair a runnable study with a genuine calculated preview and a small API example |

These projects were selected for chemical-system modeling, materials research and Julia scientific computing. Star counts change and are not used as a quality or correctness score.

## Content and presentation decisions

- English `README.md` and complete `README.zh-CN.md`, with reciprocal language links and the same commands, numerical findings and limitations. Detailed guides remain explicitly identified as Chinese.
- A six-badge row: source version, Julia requirement, PHREEQC engine, TOML configuration, research-preview status and code license. Values were checked against Project.toml, source/configuration files and LICENSE.
- [Shields static badges](https://shields.io/badges/static-badge) describe those facts. They are not build results, registry availability or scientific certification. Each of the six badge URLs was fetched and parsed as SVG during this update.
- An actual SVG from the v0.7.0 synthetic robustness run, copied without editing its data. Its [provenance](assets/readme/README.md) records the generating command, hashes, assumptions and the meaning of uncomputed space. No ignored local HTML path is presented as a public online demo.
- Keep the three scientific outcomes and the separate engine/chemical/experimental validation levels visible. Retain the measured-endpoint discrepancy and unverified applicability; do not market the model as a chronology predictor.
- Move lengthy historical and interface detail behind links, while preserving entry points for discovery, robustness, experimental comparison, explicit paths, titration and scanning.
- Do not add CI/coverage badges, package-download statistics, a publication DOI or a release badge until the corresponding record or infrastructure exists. The source-version badge is deliberately linked to Project.toml rather than an uncreated tag.

## Update discipline

On every significant software update, revise both languages together: value proposition, source version, commands, scope, validation evidence and preview provenance. Local test counts must remain explicitly versioned local evidence. Update or regenerate the figure if its input/calculation changes; never redraw data for a more attractive conclusion.
