# Fluorite–Calcite benchmark suite — 2026-11-01

All fixtures are SYNTHETIC / SIMULATED. These are internal consistency and behavior tests, not measured equilibrium data or validation of natural deposits.

- Fluoride totals 8e-5, 1.6e-4, 3.2e-4 mol/kgw → Fluorite SI: [-0.7712674694817, -0.1700123993785, 0.4304519149967]. Monotonic only for this fixture; not a universal linear law.

- pH 6, 7.5, 9 → Calcite SI: [-2.482988805169, -0.527594481943, 0.9349686709498]; CO3/HCO3 molality ratios: [5.695818704921894e-5, 0.0018136697007257601, 0.05734627122079923].

- Temperatures 25, 50, 80 °C → [log K Fluorite, log K Calcite]: [[-10.5996756161, -8.479964655643], [-10.36809636803, -8.736028538078], [-10.21250935007, -9.212839343282]]. Response verified, external accuracy and full applicability not established.

- SI identity verified against engine-reported log activities and LK_PHASE at every probe; speciation-only Ca/C totals retained. Probe inputs are unadjusted; warning presence checked against the declared 0.1% threshold at each point.

- precipitation: final phase mol [Calcite, Fluorite] = [0.003835645659742, 0.0009421851856844]; total-inventory residuals [Ca,F,C] mol = [-6.47051856539349e-16, 4.336808689942018e-18, -1.7017637299332478e-15]. Aqueous molality × actual water mass plus phase inventories; no assumption of fixed water after reaction.

- dissolution: final phase mol [Calcite, Fluorite] = [0.009891556062191, 0.009784857168148]; total-inventory residuals [Ca,F,C] mol = [-3.5041414214731503e-16, -4.128641872824801e-16, -8.153200337090993e-17]. Aqueous molality × actual water mass plus phase inventories; no assumption of fixed water after reaction.

- Database SHA-256: 59373961d648dfbf68a40744060c1d64f57ecbec98f4f5fb89f3a1b4213ccd10. Actual availability is checked by required numeric SI columns; missing phases fail rather than become default zeros. Bounds 25–80 °C are exploratory product limits, not a certified database validity interval.

Database audit: Calcite and Fluorite both contain temperature expressions in the official database. CaF+ is commented out. The activity/species completeness and temperature accuracy remain unvalidated; no parameters were imported or altered. Different databases would require separate activity-model and species audits; they are not independent repeat experiments. This sprint does not claim an inter-database validation. See DATABASE_REVIEW.md and the study reports for limitations.
