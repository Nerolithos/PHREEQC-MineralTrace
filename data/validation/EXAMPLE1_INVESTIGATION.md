# Example 1 discrepancy investigation — 2026-11-01

## Reproduced comparison

Official historical reference: [USGS Example 1, table 11](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-63.htm).

| Phase | Historical SI | Direct current CLI SI | Signed Δ | Absolute Δ | Relative absolute Δ / abs(reference) | Adapter minus direct CLI |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Anhydrite | -0.92 | -1.090041679578 | -0.17004167957799987 | 0.17004167957799987 | 0.18482791258478246 | 0.0 |
| Calcite | 0.68 | 0.7852558918818 | 0.10525589188179996 | 0.10525589188179996 | 0.15478807629676464 | 0.0 |
| Gypsum | -0.64 | -0.8021685199263 | -0.1621685199263 | 0.1621685199263 | 0.2533883123848437 | 0.0 |

Relative SI error is listed as requested, but SI is logarithmic; it is not a concentration error or statistical uncertainty.

## Checks actually performed

- Official release 3.8.6-17100 example deck is retained byte-for-byte in usgs-ex1.pqi. Input temperature 25 °C, pH 8.22, pe 8.451, density 1.023, ppm units and redox coupling agree with the documented deck on inspection. No charge adjustment was added.
- Only SELECTED_OUTPUT was inserted before END; output columns are explicitly si_Calcite, si_Gypsum and si_Anhydrite, not molality or log activity.
- This script ran the executable directly, then independently split SELECTED_OUTPUT; it also ran the same deck through the adapter. The last column above measures their difference.
- Historical table is rounded to 0.01 SI units. Original tolerance 0.01 remains unchanged; the observed differences exceed rounding precision.
- Current database SHA-256: 59373961d648dfbf68a40744060c1d64f57ecbec98f4f5fb89f3a1b4213ccd10. Direct input SHA-256: 4f43d280814e0d0a33a61ab20aabc4167f978661bbba9a2386d9661740a90d83. Engine banner and full output are in the raw archives.
- Current raw SI table (SI, log IAP, log K):

```
  Anhydrite        -1.09     -5.37   -4.28  CaSO4
  Calcite           0.79     -7.69   -8.48  CaCO3
  Gypsum           -0.80     -5.38   -4.58  CaSO4:2H2O
```

The historical table lists Calcite log K -8.48, Gypsum -4.58, Anhydrite -4.28. Current raw output contains effective log K and log IAP values differing from the historical table; temperature expressions and aqueous activity parameters are plausible contributors. **The exact causal parameter has not been isolated.** The exact database snapshot and executable behind the historical web table have not been obtained, so a version mismatch is a hypothesis, not an established explanation.

## Separate validation tracks

1. Historical Reference Test: scripts/benchmark.jl retains the original values and fails visibly when outside 0.01; no tolerances were broadened.
2. Current Engine Regression Test: ex1-current-engine.toml was captured directly from this locked binary/database. Adapter output is checked against it, with exact database and input hashes. A changed binary hash is disclosed; a changed database hash fails the locked test. This checks stability and adapter behavior, not independent scientific truth.
3. Ca–F–C tests independently check element balances, SI identity using engine-reported activities/log K, concentration/pH trends and temperature response. They are consistency tests, not experimental calibration.

Direct raw archive: results/example1-direct-ASVFWK. Adapter raw archive: results/run-EidYlm. Both remain available in results locally.

The investigation is bounded to this release and the documented historical values. Remaining task: obtain an explicitly matched historical engine/database reference, then isolate changes without mixing databases.
