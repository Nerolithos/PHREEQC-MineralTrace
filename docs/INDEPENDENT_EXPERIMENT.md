# v0.8.1 Independent-source experimental comparison

This patch tests the existing model against another laboratory's measurements. It adds no chemical process and performs no parameter fitting. **The external prediction comparison is complete; a strictly qualified database-calibration holdout is not certified.**

```sh
julia --project=. scripts/validate_holdout.jl results
```

Configure the engine/database as in README. This historical challenge additionally verifies exact pre-prediction code, data, database and executable hashes in [FREEZE.toml](../data/validation/holdout-ferreira-2025/FREEZE.toml). It uses the tested Julia 1.10.10 / PHREEQC 3.8.6-17100 build. A different executable/build or changed source requires a separately declared comparison; never edit the old receipt to make a run pass. Existing general-purpose scripts remain available with their established contracts.

The command writes standalone `report.html`, actual calculated `comparison.svg`, raw point/control values, error statistics and an archive with inputs, outputs, state dumps, database, code, protocol, primary-source transcript and reproduction script. In the export:

```sh
PHREEQC_EXECUTABLE=/absolute/path/to/phreeqc julia --project=. reproduce.jl
```

The same archive's analysis, CSV and SVG reproduce byte-for-byte. Keep the entire directory; an HTML copy alone is not a complete audit archive.

## Result and interpretation

[Five selected 25 °C measurements](../data/validation/holdout-ferreira-2025/observations.csv), from Ferreira et al. (2025), DOI [10.1021/acs.jced.4c00670](https://doi.org/10.1021/acs.jced.4c00670), produce **−1.246% to −10.404%** signed central prediction errors at 1.013–2.146 bar pCO2. The unchanged baseline's REFLECT errors were positive at different conditions, 24 °C and ~10–50 bar pCO2. This does not reproduce the same positive-bias direction, but does not isolate pressure, methodology or thermodynamic constants as the cause.

The first two errors are comparatively small; the higher-pressure points differ more. Published duplicate SD and standard estimated uncertainty are separately retained. No combined confidence interval, weighted acceptance, universal bias correction or profile qualification is inferred. No reported pH correlation is treated as measured pH; no missing DIC is invented.

The source is independent of REFLECT. Some related measurements existed in a 2022 thesis before later database revisions; complete database calibration lineage remains UNKNOWN. The source family is counted once. The entry is registered as `experimentally_challenged`, with calibration independence UNKNOWN, exact joint points and no supported path observable. Strict mode is unchanged.

## Review evidence

- [Full scientific comparison and limitations](../data/validation/v081/REPORT.md)
- [Source screening and qualification audit](../data/validation/holdout-ferreira-2025/SOURCE_AUDIT.md)
- [Frozen model, selection, uncertainty and controls](../data/validation/holdout-ferreira-2025/PROTOCOL.toml)
- [Primary-publisher retrieval transcript](../data/sources/FERREIRA-2025-PUBLISHER-TRANSCRIPT.txt): explicitly not an original publisher PDF hash; direct download returned 403.
- [Official database lineage metadata](../data/validation/lineage-v081/SOURCE.json), [block differences](../data/validation/lineage-v081/block-comparison.json); reproduce with `python3 scripts/audit_holdout_lineage.py`.
- [Independent reproduction audit](../data/validation/v081/REPRODUCTION_AUDIT.json)

The next useful evidence is matched-temperature/pressure Ca plus measured CO2/DIC, with raw filtration/dilution/recovery records, uncertainty and parameter-source history. Further mechanisms or a fitted correction are not the next step justified by these two datasets.
