# Example 1 controlled database attribution — v0.7.0

The previous cross-version mismatch is now attributed to **database aqueous-speciation/association changes**, rather than adapter parsing or an unidentified calculation failure. The same current executable and identical seawater input, with an unmodified official 2012-11-14 database, reproduce all three manual values within the original 0.01 SI tolerance. No measured concentrations or tolerance were changed.

This does not prove that this exact Git commit was the manual authors' file: that original binary/database pair remains unidentified. It does establish that a historically available database is sufficient to recover the documented values, and controlled database interventions localize the dominant differences.

| Controlled case | Calcite SI | Gypsum SI | Anhydrite SI |
| --- | ---: | ---: | ---: |
| current | 0.785255891882 | -0.802168519926 | -1.090041679578 |
| unmodified_2012 | 0.675419492902 | -0.638246017318 | -0.924585371458 |
| unmodified_2013 | 0.753902568816 | -0.638734640505 | -0.925070110134 |
| current_2012_NaCO3 | 0.785255891882 | -0.802168519926 | -1.090041679578 |
| current_2012_NaHCO3 | 0.698148520692 | -0.801743532774 | -1.089621057951 |
| current_2012_Na_carbonates | 0.698148520692 | -0.801743532774 | -1.089621057951 |
| 2013_2012_Na_carbonates | 0.675419492902 | -0.638246017318 | -0.924585371458 |
| current_2012_sulfate_complexes | 0.776086874295 | -0.642557354087 | -0.930360329289 |
| current_2012_carbonate_sulfate | 0.687087881085 | -0.642250994703 | -0.930058523542 |
| current_all_2012_aqueous_species | 0.675554273391 | -0.636780927624 | -0.924585371458 |

## Isolated findings

- The current NaHCO3 aqueous association block replaced by its 2012 block changes Calcite SI from 0.785255891882 to 0.698148520693, while moving the two sulfate SIs by only about 0.0004. This is a controlled association/activity intervention, not evidence to retune the database.
- The two sodium-carbonate blocks in the 2013 database replaced by their 2012 forms reproduce the full unmodified 2012 result. The 2012 NaHCO3 association log K is 0.4; the later form is -0.25. The NaCO3 block also differs in that interval. The current database lacks that explicit NaCO3 block; its individually named current-NaCO3 intervention is therefore a documented **no-op**, not a claimed causal effect.
- Replacing the current sulfate-complex group with the 2012 group moves Gypsum from -0.802168519926 to -0.642557354087 and Anhydrite from -1.090041679578 to -0.930360329289. Interaction with the remaining aqueous parameters accounts for the small residual; no single sulfate constant is asserted to explain the entire shift.
- Replacing the whole aqueous-species section while retaining current mineral phases gives 0.675554273391, -0.636780927624, -0.924585371458: all inside the original manual tolerance. This shows that mineral-phase log K changes alone are not the dominant source.

## Three reference meanings remain separate

1. **Historical reproduction:** explicitly named 2012 snapshot, current binary, original 0.01 tolerance — passes.
2. **Current regression:** original locked 3.8.6-17100 database and current-engine values — unchanged and passing.
3. **Unmatched historical table versus modern database:** still shows the original three differences; the legacy benchmark remains visibly failing. This is now an explained cross-profile comparison, not an unexplained exception or a failed adapter calculation.

Diagnostic hybrid databases are archived only inside the attribution workspace. They are interventions to explain the mismatch, **not approved or released model profiles**. Original snapshots are byte-preserved; production phreeqc.dat is never edited or mixed. Run `python3 scripts/attribute_example1.py` with the configured PHREEQC executable and database to regenerate the controls.

Machine values, input/database/executable hashes and raw workspace paths: [attribution JSON](EXAMPLE1_ATTRIBUTION_V070.json). Official source URLs, timestamps and checksums: [source register](../sources/PHREEQC-HISTORICAL-V070.json). The causal allocation of small remaining nonlinear interactions is not unique; no exact historical engine provenance is invented. These are engine/model-reference checks, not experimental validation.
