const CHARGE_CONTEXTS = ("hypothetical", "partial_analysis", "analytical")
"""Signed PHREEQC charge in eq and eq/kgw. Threshold is a policy diagnostic, never a universal standard."""
function charge_diagnostic(percent, net_eq, water_kg; threshold_percent=0.1, context="hypothetical")
    context in (CHARGE_CONTEXTS...,"controlled_process") || throw(ArgumentError("unknown charge diagnostic context"))
    finite_real(net_eq) && finite_real(water_kg) && water_kg>0 || throw(ArgumentError("finite charge and positive water mass required"))
    finite_real(threshold_percent) && threshold_percent>=0 || throw(ArgumentError("nonnegative diagnostic threshold required"))
    percent===nothing || finite_real(percent) || throw(ArgumentError("invalid percent error"))
    meaning=context=="controlled_process" ? "Calculated reaction state after explicit neutral additions; initial charge residual is inherited, not an independently measured analytical error." : context=="analytical" ? "Charge-balance diagnostic for a user-declared measured ionic analysis; completeness, analytical uncertainties and omitted ions require independent review." : context=="partial_analysis" ? "Residual of a partial ionic inventory; not a complete analytical charge-balance error." : "Residual of an imposed hypothetical fluid/speciation state; not an analytical measurement error."
    Dict{String,Any}("context"=>context,"percent_error"=>percent,"net_charge_eq"=>net_eq,
        "net_charge_eq_per_kgw"=>net_eq/water_kg,"net_charge_meq_per_kgw"=>1000net_eq/water_kg,
        "threshold_percent"=>threshold_percent,"diagnostic_status"=>percent===nothing ? "undetermined" : abs(percent)<=threshold_percent ? "within_declared_threshold" : "exceeds_declared_threshold",
        "interpretation"=>meaning,"limitation"=>"A threshold violation does not prove physical impossibility. Percent normalization can change while absolute charge is conserved. No concentrations were adjusted.")
end
