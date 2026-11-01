# v0.4.0 charge-balance semantics

The retained adapter warning threshold is 0.1% for backward regression compatibility. It is a **configurable diagnostic policy**, not a universal analytical or water-quality standard. Existing raw inputs, output values, warning text and historical regressions are preserved. No threshold violation is described as proof of physical impossibility.

## Different meanings

- `analytical`: explicitly user-declared measured ionic analysis. Completeness, unmeasured ions, analytical uncertainty and carbonate/alkalinity reporting basis must be reviewed before interpreting analytical charge-balance error.
- `partial_analysis`: incomplete ionic inventory; the residual cannot certify or invalidate a full analytical analysis. KnownFluid scans default here unless a user explicitly declares another supported context.
- `hypothetical`: imposed synthetic/assumed composition and initial pH; residual is a property of that specification, not measurement error.
- `controlled_process`: calculated reaction state after neutral formula addition. Its charge residual is inherited from the initial state, not an independent measured analysis at each step.

Scan `[evaluation].max_charge_error_percent` and process `[diagnostics].charge_threshold_percent` govern their respective diagnostic evaluation. The raw legacy adapter warning at 0.1% is retained separately even when the configured process threshold differs. Existing `chemical_quality_status = fail` means failure of the declared policy gate, not physically impossible fluid.

## Units and contributors

PHREEQC SELECTED_OUTPUT `charge` is the signed net equivalent inventory (eq). Divide by actual `mass_H2O` to obtain eq/kgw; multiply by 1000 for meq/kgw. The normalized percentage is `100 × (cation equivalents − anion equivalents)/(cation equivalents + anion equivalents)`. A percentage without a nonzero charged inventory is not interpreted as a universal metric.

Aqueous H+, OH−, Ca2+, Na+, Cl−, F−, HCO3−, CO3(2−) and charged complexes contribute according to their **actual aqueous molalities and ionic charges**. Neutral CO2, HF, CaCO3 and water do not contribute charge. Total Ca, F and inorganic carbon determine speciation, but total carbon cannot be assigned the single charge of CO3(2−). Protons and water chemistry can change while element totals are conserved.

Process `charge-species.csv` lists every species parsed from each raw species-distribution table, its molality, integer charge and signed equivalent concentration. These independently summed values are rounded-output diagnostics; they are not a new activity model. High-precision engine charge and actual water mass drive the conservation check. All selected species and total concentrations are retained separately in `steps.csv` and raw output.

## Interpretation during titration

HCl and NaOH additions are neutral stoichiometric formulas: they introduce H/Cl or Na/O/H together. No bare H+ or OH− scenario and no silent charge balancing is supported. Net equivalents should remain equal to the initial net inventory in this closed aqueous model; an initially nonzero residual is recorded rather than edited away. Percentage error may change as its denominator changes without eliminating that absolute residual.

Conservation of a nonzero residual is a bookkeeping consistency result, not experimental validation of an unbalanced initial fluid. Dilute or nearly uncharged solutions can show a relatively large percentage for a small equivalent residual. The report therefore retains both quantities and the initial specification context.
