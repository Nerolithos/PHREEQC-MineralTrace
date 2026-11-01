# Scientific validation status — v0.3.0, 2026-11-01

## Version-matched reference obtained

The PHREEQC developer repository's [v3.8.6 release](https://github.com/phreeqc-dev/phreeqc3/releases/tag/v3.8.6) identifies 3.8.6-17100. Downloaded tagged [Example 1 output](https://raw.githubusercontent.com/phreeqc-dev/phreeqc3/v3.8.6/examples/ex1.out), [input](https://raw.githubusercontent.com/phreeqc-dev/phreeqc3/v3.8.6/examples/ex1) and [database](https://raw.githubusercontent.com/phreeqc-dev/phreeqc3/v3.8.6/database/phreeqc.dat).

The tagged input is byte-identical to the retained official release deck. The tagged database and local database have identical SHA-256 `59373961d648dfbf68a40744060c1d64f57ecbec98f4f5fb89f3a1b4213ccd10`. The tagged output is independently supplied by upstream, not generated from our adapter; retained under `upstream-v3.8.6/`, output SHA-256 `9cb70767838815ccb16030ceec94aaaa3a3d35a6c4f219deb3a90c6d889c2192`.

| Phase | Tagged upstream SI (rounded) | Local high-precision SI | Absolute difference |
| --- | ---: | ---: | ---: |
| Calcite | 0.79 | 0.7852558918818 | 0.0047441081182 |
| Gypsum | -0.80 | -0.8021685199263 | 0.0021685199263 |
| Anhydrite | -1.09 | -1.090041679578 | 0.000041679578 |

All pass the existing 0.01 rounding tolerance. This version-matched upstream comparison is separate from the locally captured engine-regression baseline. It supports adapter/engine consistency, not natural-deposit validation.

The historical manual's table 11 remains different: Calcite 0.68, Gypsum -0.64, Anhydrite -0.92. **Those failures remain visible and their tolerance remains unchanged.** A current matching reference does not identify the historical causal parameter or justify changing the historical answers. See EXAMPLE1_INVESTIGATION.md and ex1-discrepancies.csv.

## Independently documented parameter checks

Two primary publication records were checked. Numeric fields were transcribed from their abstracts, not invented or used as replacement database values:

- Nordstrom (2022), [USGS publication record](https://www.usgs.gov/publications/evaluation-internal-consistency-thermodynamic-network-involving-fluorite-cryolite-and), DOI [10.1180/mgm.2022.40](https://doi.org/10.1180/mgm.2022.40): fluorite infinite-dilution log Ksp at 25 °C and 1 bar, −10.57 ± 0.08. The current engine gives approximately −10.59968 at 25 °C and 1 atm, within that reported scalar uncertainty. The pressure mismatch is disclosed; no correction is invented.
- Plummer and Busenberg (1982), [USGS publication record](https://pubs.usgs.gov/publication/70011789), DOI [10.1016/0016-7037(82)90056-4](https://doi.org/10.1016/0016-7037(82)90056-4): calcite log K at 25 °C, −8.480 ± 0.020. Current engine effective log K is approximately −8.47996.

Reference values, reported uncertainty, provenance and limitations are in independent-reference-checks.toml; actual calculations and deltas are in independent-parameter-results.md. These are scalar consistency screens. No original experimental concentration/speciation table has been independently reconstructed. Shared thermodynamic lineage also limits independence. **No full independent Ca–F–C aqueous case or real-world formation inference has been validated.**

## Database and model audit

Locked phreeqc.dat contains active Calcite and Fluorite phase definitions with analytical temperature expressions; Ca, F and C(+4) master species; aqueous carbonate/bicarbonate/CO2, CaCO3 and CaHCO3 complexes; and HF/F speciation. CaF+ is commented out. No parameter was enabled, replaced or spliced from another database.

The model is ion-association, using species-specific WATEQ activity parameters where `-gamma` is supplied and Davies for charged species without them, as described by the official [SOLUTION_SPECIES documentation](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-50.htm). This is not a Pitzer or SIT validation. Temperature expressions establish computability, not universal calibration over 25–80 °C. Published calcite temperature studies do not validate the complete present mixed-fluid model or all fluoride species.

The allowed temperature/concentration limits are software exploration bounds, not certified validity intervals. Ionic-strength applicability, species completeness, higher-temperature accuracy and natural fluid compositions remain unverified. Thus model applicability stays unverified; users cannot self-certify it by a TOML flag. Missing required phases are explicitly invalid.

## Validation tracks

1. Historical manual comparison: known failure, retained.
2. Locked local engine regression: stability only.
3. Version-matched upstream Example 1 and existing Example 2 reference: engine/adapter comparison.
4. Ca–F–C SI identity, concentration/pH/temperature response and element conservation: internal physical-chemical consistency.
5. External published scalar constants: limited independent parameter screening.
6. Independent complete aqueous experiments and natural cases: **not completed**.

No reference values were fitted to the output and no scientific tolerances were enlarged to pass tests. Formation temperature and chronology are not inferred from mineral names.
