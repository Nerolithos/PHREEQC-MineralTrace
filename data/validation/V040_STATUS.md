# MineralTrace v0.4.0 execution record — 2026-11-01

## Delivered process and semantics

A reproducible acid–base process now uses actual PHREEQC REACTION with INCREMENTAL_REACTIONS true. HCl and NaOH transfer neutral chemical formulas in explicitly declared incremental mol amounts. Only initial pH is specified; later pH and species are solved. No independent per-step pH overwrite, silent concentration adjustment, unknown titrant volume/dilution, mineral precipitation/dissolution, gas exchange or kinetic rate law is introduced.

Monitored Calcite and Fluorite SI are not mineral reaction extents. Supersaturation is not identified as precipitation, and no mineral formation temperature or chronology is inferred.

Charge diagnostics distinguish declared analytical, partial-inventory, hypothetical and computed-process meanings. Output contains signed eq, eq/kgw, meq/kgw and percent error. The default 0.1% is an explicit configurable diagnostic policy, not a universal water-quality standard or proof of physical impossibility. Legacy raw warnings and numbers remain unchanged. See CHARGE_BALANCE_SEMANTICS.md.

## Three validation levels

1. **Engine validation:** identical process decks executed through the adapter and independently through the CLI. All selected-output columns agree over the seven acid-titration states (atol 1e-11, rtol 1e-11). See TITRATION_ENGINE_COMPARISON.md. This validates wrapper/engine agreement, not the database against nature.
2. **Chemical consistency:** independently count atoms added as HCl or NaOH. Ca/F/C/Na/Cl baseline inventories are checked against declared mol/kgw × initial kg water. H/O initial inventories come from the engine, then all added H/O atoms are independently counted; water is included. Net equivalents must remain equal to the initial residual for neutral additions. Actual water mass is used at each step. These are numerical consistency checks, not experimental uncertainty or complete initial-fluid validation.
3. **Experimental comparison:** **not completed**. One original public Calcite growth experiment was checked and registered, including actual measured composition and observable, conditions, units, uncertainty omissions and source DOI. Its observable/boundary and available inputs do not support the current closed titration model. No measured titration curve with sufficient verified inputs was established in the selected sources. Missing inputs were not invented; calculated source pH was not treated as measured data. See EXPERIMENTAL_CASE_V040.md and experimental-case-v040.json.

The documented absence of a suitable supported comparison meets the explicit fallback in acceptance criterion 5; it does not establish empirical validation. Earlier scalar log K screens do not substitute for an experiment.

## Actual runs

Environment: Julia 1.10.10/macOS ARM64, PHREEQC 3.8.6-17100, original phreeqc.dat SHA-256 `59373961d648dfbf68a40744060c1d64f57ecbec98f4f5fb89f3a1b4213ccd10`. Runtime tools remain in /tmp, not a permanent system installation.

```sh
julia --project=. scripts/titrate.jl examples/acid_titration.toml results
julia --project=. scripts/titrate.jl examples/base_titration.toml results
```

Final acid report: `results/process-oqxUw8/report.html`. Six HCl additions totaling 0.0012 mol; calculated pH evolves from 8.0 to 3.795004512959. Final base report: `results/process-DCemyJ/report.html`. Five NaOH additions; calculated pH evolves from 8.0 to 9.7059201977. Both are explicitly SYNTHETIC / SIMULATED assumed fluids, not laboratory measurements.

All seven element checks and net-charge conservation pass. For the acid example maximum absolute element residuals are: Ca 0, F about 1.0e-16, C about 3.0e-15, Na 0, Cl about 2.2e-19, H about 1.4e-14 and O 0 mol. Maximum net-charge change is about 2.8e-15 eq. These small accounting residuals do not certify the thermodynamic model. Initial nonzero charge was preserved, not neutralized.

Inside the exported acid directory, `PHREEQC_EXECUTABLE=/absolute/path/to/phreeqc julia --project=. reproduce.jl` was actually executed. Reproduced `analysis.json` is byte-identical. CSV row/column integrity, six SVG XML files per report, raw input/database hashes and all source/evidence hashes were independently checked. Figures were rendered and visually checked. See v040-export-audit.txt.

Each export contains full initial and reagent TOML, PHREEQC deck, raw process output, selected values, atom/charge accounting, rounded aqueous-species charge contributions, six SVGs, standalone HTML, CSV/JSON, source/database snapshots and reproduction script. Failed engine runs retain their original input/output and errors; no default results replace failure. Accounting failures are retained and yield a nonzero CLI exit.

## Tests

```sh
MINERALTRACE_INTEGRATION=1 julia --project=. test/runtests.jl
```

**914/914 passed; exit 0.** Full output: v040-test-output.txt. Existing 531 checks remain; none were removed or weakened. New tests comprise 28 charge-semantics/process-schema checks and 355 real-engine process/CLI/accounting checks, including:

- Actual acid/base directions and nonuniform incremental doses checked through independent Na/Cl inventories.
- Half-kilogram initial water and zero-dose controls, guarding molality/mole confusion and state advancement.
- Every H/O/Ca/F/C/Na/Cl balance and preservation of initial net charge.
- Full direct CLI selected-output comparison.
- Tampered numerical unit fixtures fail conservation checks; those fixtures are never exported as chemical calculations.
- Wrong units, bare H+, negative or nonfinite doses and unknown carrier-water model rejected.
- Genuine missing-phase calculation fails and retains an archive.
- Existing parameter scans, evidence constraints, 42-point legacy regression, DAG and cycle/conflict tests remain operational.

The separate historical Example 1 manual track was rerun and still has **three deliberate failures**, exit 1; see v040-historical-output.txt. Its tolerance remains unchanged. Version-matched upstream reference and locked local regression remain separate passing tracks.

## Remaining limitations and next priority

No full experimental titration validation, calibrated activity/species scope, aqueous titrant carrier water, gas transfer, precipitation/dissolution or kinetics is supported. CaF+ remains inactive in the locked database; 25–80 °C is an explicit exploratory software range, not a certified model domain.

Next priority is an openly reproducible titration dataset with initial ionic/carbon inventory, measured initial and stepwise pH, temperature, doses, carrier water and uncertainty. Implement required physical boundary conditions before quantitative comparison. Do not fit undocumented initial composition to a published answer and call it independent validation.
