# v0.5.0 validation scope

Engine comparison and closed-system atom/charge checks are distinct from experimental and natural-history validation. See PATH_ENGINE_COMPARISON.md and the recorded raw calculations.

The primary Brown and Roberson (1977) study was downloaded and inspected, including methods, Table 5 and conclusions. Source: [USGS original journal](https://pubs.usgs.gov/journal/1977/vol5issue4/report.pdf), article pp. 509–517. DOI was not verified and remains null. Registered data are in fluorite-experimental-case-v050.json.

Ontario solution 1 at 1118 days reports Ca 8.3 and F 7.25 mg/L; bicarbonate is only <5 mg/L. Conditions include 25.0 ±0.5 °C, initially no added perchlorate for this bottle, and about 0.5 g fluorite in 200 mL. Atmospheric CO2 was not excluded; initial carbon and gas history are not specified sufficiently for the supported closed path. No exact carbon value or initial pH was invented.

A numerical comparison was completed for the source's experimentally derived zero-ionic-strength equilibrium parameter: reported fluorite log10 K = −10.58, analytical uncertainty ±0.17; engine effective log K at 25 °C = −10.5996756161, signed difference −0.0196756161. This falls inside the reported analytical uncertainty. The ±0.01 scatter value is explicitly not the full analytical uncertainty. See fluorite-experimental-comparison-v050.toml and scripts/validate_fluorite_case.jl.

This is limited parameter agreement with an original experimental source, possibly sharing thermodynamic lineage with the database. It is not a blind independent test of a complete aqueous reaction path. The bulk closed-path benchmark is **rejected** because carbon/gas boundary and minor-ion inventory cannot be faithfully reproduced. The measured Ca and F values were not treated as guessed initial conditions or used to fit the model. Complete independent process and natural-deposit validation remain unfinished.

The two-path demonstration is entirely SYNTHETIC / SIMULATED. Fluid totals, initial solids, phase permissions, temperatures, event assignments and the 0.5% diagnostic policy are declared assumptions, not measurements. Its activation order intentionally differs between candidates. The model checks actual reaction occurrence and consistency with the supplied event mapping; it does not independently discover chronology.

A compatible label is conditional on the supplied path, source records, numerical checks and equilibrium assumptions. All model applicability remains unverified. Strict mode therefore retains unknown applicability rather than certifying the candidate. SI opportunity, equilibrium transfer and independent observation are never merged.
