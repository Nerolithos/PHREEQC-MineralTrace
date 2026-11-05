# v0.7.1 REFLECT discrepancy attribution protocol

Scope: the five frozen 24 °C Figure 22 pure-water measured points, unchanged SHA-256 `2e8df44966f958f0959c4f252124e8a0b55c5b4b3e4889a5799a328a0d12d805`. Existing v0.7.0 observations, protocol and results are historical records and are not rebased. No log K, species concentration or measured datum is fitted. Model choices below are diagnostics, not a search for a preferred fit. No new discovery mechanism is enabled.

Each point is evaluated under seven choices, with all other declared inputs fixed:

1. Locked unmodified USGS 3.8.6-17100 phreeqc.dat, native Peng–Robinson CO2; 0.8 kg initial water, 10 g calcite, 10 mol numerical CO2 buffer, 24 °C, aqueous total P = pCO2 + 0.03 bar.
2. Same database except removal of CO2(g)'s three critical/EOS properties: ideal-gas limiting diagnostic. Henry-law, carbonate and calcite constants untouched. This deliberately omits high-pressure gas nonideality; not an accurate high-pressure alternative.
3. Same database except omission of explicit `-gamma` lines for H+, OH-, Ca+2, HCO3-, CO3-2, CaHCO3+, CaOH+: PHREEQC's default Davies equation for these charged species. Neutral-species activity and all equilibrium constants retained. Only species actually having explicit gamma lines change; list is exported. This is a dilute-ion sensitivity comparison, not a validated high-pressure profile.
4. Unmodified USGS 3.8.6-17100 pitzer.dat, native PR. Whole-profile comparison changes interaction parameters, species set, constants and formula weights together. It cannot isolate an activity-model cause. Sources and applicability limitations must accompany any apparent improvement.
5. Same gas pCO2, aqueous total pressure increased by 0.2 bar. Conservative one-sided pressure sensor stress, not a statistical uncertainty interval; arbitrary large pressure changes or independent negative vapor pressure are not physically justified.
6. Same gas pCO2, omit only the approximate 0.03 bar aqueous vapor-pressure contribution.
7. Same gas pCO2, force aqueous pressure to 1 atm. Explicitly nonphysical decoupling limit to measure sensitivity to solution pressure corrections; never an accepted experimental reconstruction.

Output: each measured value, predictions on both kg-water and kg-final-solution bases, signed fractional discrepancy `(prediction-observation)/observation`, percentage prediction change relative to that point's baseline, inferred CO2 fugacity coefficient, actual PHREEQC solution pressure, ionic strength, selected activity coefficients, pressure-adjusted phase constants, element/charge residuals, nonexhausted phase checks, raw decks and database/executable/source hashes. These are deterministic sensitivities, not confidence intervals or fitted validation scores. No best model or ranking is assigned.

Engine check: instrumented baseline must reproduce the existing endpoint API at 1e-9 g/kg and explicitly attain requested solution pressure. Chemical check: Ca/C/H/O including remaining calcite and numerical CO2 reservoir; absolute/relative tolerance as v0.7.0, charge change below 1e-9 eq. Experimental comparison: retain discrepancies and all missing per-point uncertainty; do not use software-test acceptance as empirical validation.

References: [PHREEQC EQUILIBRIUM_PHASES](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-13.htm), [SOLUTION_SPECIES](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-50.htm), [high-pressure gas Example 22](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-84.htm), [database distribution](https://github.com/phreeqc-dev/phreeqc3/tree/master/database). Exact snapshots, not a moving branch, define each run.
