# Independent experimental case review — v0.4.0

Registered original source: Plummer and Busenberg (1999), USGS Open-File Report 99-247, DOI [10.3133/ofr99247](https://doi.org/10.3133/ofr99247), [original PDF](../sources/USGS-OFR99-247.pdf). Methods and Table 1 were extracted and visually checked. Full provenance, units, measured/calculated classification and missing fields are in `experimental-case-v040.json`.

Table 1 experiment 69 reports Ca 2.66 mmol/kg water and crystal mass gain 0.735 mg at 34 °C, 22 minutes, with area 5.56 cm² and 0.102% CO2 gas. The table pH 8.52 is explicitly **calculated**, not an independent measurement. Individual weight reproducibility is reported within 2 µg; uncertainty of mass gain is not supplied and remains null.

**Decision: unsuitable for the supported closed acid–base titration comparison.** The measured response is gas-contact crystal growth, not a dose–pH curve. Stepwise titrant additions, independently measured pH and a complete starting ionic/carbon inventory are not established for the implemented process. Gas exchange and crystal-growth kinetics are not modelled. No missing carbon concentration, measured pH or rate law was fitted or invented.

No quantitative prediction-versus-measurement comparison was performed. Public measurements exist; this is a mismatch of supported observable/boundary and verified inputs, not a claim that public data do not exist. No sufficient independently measured titration case was established in the selected sources this sprint. The earlier 1982 abstract-level log K screening is not experimental process validation either.

Before using this case, implement and validate its open gas boundary and growth kinetics, obtain the necessary starting inventory and uncertainty information, and audit the activity/species model at 34 °C. Alternatively obtain an openly documented titration curve with explicit ionic totals, initial measured pH, temperature, molar increments and carrier-water specification.
