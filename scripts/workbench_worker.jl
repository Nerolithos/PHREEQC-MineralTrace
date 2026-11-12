# Fixed entry point for the loopback supervisor; no executable paths from requests.
using MineralTrace, TOML
mode,input,output=ARGS
function savejson(path,value)
    temp=path*".tmp";write(temp,MineralTrace.json_value(value)*"\n");mv(temp,path;force=true)
end
try
    s=load_discovery(input);generated=generate_candidates(s)
    length(generated.candidates)<=400 || throw(ArgumentError("Local workbench budget: at most 400 unique candidates"))
    if mode=="validate"
        savejson(output,Dict("valid"=>true,"candidate_count"=>length(generated.candidates),"study"=>s.spec,"warnings"=>["All example inputs are synthetic assumptions","Equilibrium increments are not measured crystallization events","Candidate fractions are not probabilities","No current profile grants strict qualification"]))
    elseif mode=="parse"
        savejson(output,Dict("study"=>s.spec,"candidate_count"=>length(generated.candidates)))
    elseif mode=="run"
        root=dirname(output)
        progress=(done,total,dir)->savejson(joinpath(root,"progress.json"),Dict("completed"=>done,"total"=>total,"archive"=>basename(dir)))
        c=PHREEQCConfig(timeout_seconds=30)
        r=discover_paths(s,c;root,progress);report(r)
        profiles=load_model_profiles();registry=load_evidence_registry()
        context=evaluate_research_applicability(profiles["discovery-cafc-386"],s,c;registry)
        savejson(output,Dict("archive"=>basename(r.directory),"candidate_count"=>length(r.candidates),"provenance"=>r.provenance,"research_applicability"=>context))
    else
        error("unknown worker operation")
    end
catch e
    savejson(output,Dict("error"=>Dict("code"=>"JULIA_VALIDATION_OR_CALCULATION_ERROR","message"=>sprint(showerror,e))))
    exit(1)
end
