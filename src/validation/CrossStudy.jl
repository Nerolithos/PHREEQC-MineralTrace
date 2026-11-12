"""Append cross-study evidence context without changing base applicability or strict qualification."""
function evaluate_research_applicability(profile, args...; kwargs...)
    result=evaluate_applicability(profile,args...;kwargs...)
    references=get(profile.spec,"cross_study_references",String[])
    result["cross_study_context"]=Dict("references"=>references,
        "experimental_independence"=>"UNKNOWN",
        "experimental_agreement"=>"opposite-sign discrepancies in unmatched domains; no global validation",
        "conditions_differ"=>["24 versus 25 degC","nonoverlapping CO2 pressure domains","EDTA versus AAS sampling","REFLECT mass denominator unresolved"],
        "unresolved"=>["database calibration lineage","initial trace chemistry","matched-condition independent Ca and DIC data"],
        "scope"=>"Two discrete endpoint series; no support for paths, kinetics or chronology",
        "actual_mineral_chronology"=>"undetermined")
    result
end
