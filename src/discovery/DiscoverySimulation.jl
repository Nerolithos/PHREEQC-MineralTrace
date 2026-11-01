struct DiscoveryResult
    study::DiscoveryStudy
    candidates::Vector{Dict{String,Any}}
    membership::Dict{String,Vector{String}}
    sensitivity::Vector{Dict{String,Any}}
    groups::Vector{Dict{String,Any}}
    directory::String
    provenance::Dict{String,Any}
end

function screen_discovered(s::DiscoveryStudy,candidate)
    threshold=s.spec["search"]["reaction_threshold_mol"];status=candidate["computational_status"]
    events=s.spec["events"];checks=Dict{String,Any}[];positions=Dict{String,Int}();responses=Dict{String,Any}()
    unknown=isempty(events);contradiction=false
    for m in s.spec["minerals"]
        precip=Int[];dissolve=Int[]
        for p in candidate["steps"]
            p["index"]==0 && continue
            change=p["phase_transfers"][m]["solid_gain_mol"]
            change>=threshold && push!(precip,p["index"])
            change<=-threshold && push!(dissolve,p["index"])
        end
        responses[m]=Dict("precipitation_steps"=>precip,"dissolution_steps"=>dissolve,"baseline_precipitation"=>1 in precip,"baseline_dissolution"=>1 in dissolve)
    end
    if status!="success"
        push!(checks,Dict("constraint"=>"hard chemical/accounting boundary","result"=>status,"detail"=>get(candidate,"error","")))
        classification=status=="hard_constraint_failure" ? "incompatible" : "undetermined"
    else
        for event in events
            id=event["id"];m=event["mineral"];source=get(event,"source_id",nothing)
            repeated=count(e->e["mineral"]==m,events)>1
            values=haskey(responses,m) ? responses[m][event["event_kind"]=="formation" ? "precipitation_steps" : "dissolution_steps"] : Int[]
            sourced=source isa AbstractString && !isempty(strip(source)) && event["classification"]=="Observation"
            if !haskey(responses,m) || repeated
                result="undetermined";unknown=true;detail="Repeated mineral stages or unmodeled minerals cannot be automatically assigned a unique event correspondence"
            elseif isempty(values)
                result="required_modeled_reaction_absent";contradiction=true;detail="No step meets the declared reaction threshold in this finite equilibrium path; this rejects only this model surrogate, not the observed history"
            elseif first(values)==1
                result="baseline_reaction_unresolved";unknown=true;detail="Reaction occurs during common initial equilibration; its prehistory and internal chronology are unknown, so no environmental onset is assigned"
            else
                # This is a deterministic screening surrogate, not a claimed mapping to an actual specimen event.
                positions[id]=first(values);result="modeled_reaction_detected";detail="First above-threshold post-baseline equilibrium increment; kinetic nucleation and actual formation time remain unknown"
            end
            !sourced && (unknown=true)
            push!(checks,Dict("constraint"=>id,"mineral"=>m,"event_kind"=>event["event_kind"],"result"=>result,"reaction_steps"=>values,"source_id"=>source,"independent_source_present"=>sourced,"detail"=>detail))
        end
        for edge in s.spec["evidence"]
            a=edge["earlier"];b=edge["later"]
            if !haskey(positions,a) || !haskey(positions,b)
                result="undetermined";unknown=true
            elseif positions[a]==positions[b]
                result="same_batch_unresolved";unknown=true
            elseif positions[a]>positions[b]
                result="equilibrium_proxy_reversed";contradiction=true
            else
                result="equilibrium_proxy_order_compatible"
            end
            push!(checks,Dict("constraint"=>"$a → $b","result"=>result,"source_id"=>edge["source_id"],"detail"=>"Comparison of model increments only. It cannot establish or refute actual crystallization chronology without additional kinetic/phase-access evidence."))
        end
        quality=all(p->p["charge_diagnostic"]["diagnostic_status"]=="within_declared_threshold",candidate["steps"])
        !quality && (unknown=true;push!(checks,Dict("constraint"=>"charge diagnostic","result"=>"requires_review","detail"=>"Threshold exceedance is a diagnostic, not physical impossibility")))
        s.spec["evaluation_mode"]=="strict" && (unknown=true;push!(checks,Dict("constraint"=>"model applicability","result"=>"unverified","detail"=>"Full independent process validation is incomplete")))
        classification=contradiction ? "incompatible" : unknown ? "undetermined" : "compatible"
    end
    Dict{String,Any}("classification"=>classification,"classification_scope"=>"conditional equilibrium-reaction surrogate screening, not observed formation chronology","formation_order_classification"=>"undetermined","observed_formation_confirmed_by_model"=>false,"model_applicability"=>"unverified","reaction_threshold_mol"=>threshold,"responses"=>responses,"automatic_proxy_positions"=>positions,"checks"=>checks)
end

function response_signature(screen)
    # Deliberately qualitative. Equal signatures do NOT mean equal pH, masses, or geological histories.
    positions=screen["automatic_proxy_positions"]
    reactions=join(["$m:precip=$(!isempty(v["precipitation_steps"])),dissolve=$(!isempty(v["dissolution_steps"])),baseline=$(v["baseline_precipitation"])/$(v["baseline_dissolution"])" for (m,v) in sort(collect(screen["responses"]);by=first)],";")
    ids=sort(collect(keys(positions)))
    order=join(["$(ids[i])/$(ids[j]):$(sign(positions[ids[i]]-positions[ids[j]]))" for i in eachindex(ids) for j in i+1:length(ids)],";")
    reactions*"|relative_proxy_order="*order
end

function discovery_groups(candidates)
    groups=Dict{String,Vector{String}}()
    for c in candidates
        c["computational_status"]=="success" || continue
        key=response_signature(c["screening"]);push!(get!(groups,key,String[]),c["id"])
    end
    [Dict{String,Any}("id"=>"response-group-$i","qualitative_signature"=>key,"candidate_ids"=>groups[key],"interpretation"=>"Same qualitative detected-reaction pattern and relative proxy order; numeric trajectories can differ, and no unique mechanism/history is selected") for (i,key) in enumerate(sort(collect(keys(groups))))]
end

function sensitivity_comparisons(s,candidates,membership)
    grids=s.spec["grids"];base=only(g for g in grids if g["role"]=="baseline");lookup=Dict(c["id"]=>c for c in candidates)
    function grid_summary(g)
        cs=[lookup[id] for id in membership[g["id"]]]
        signatures=sort(unique(response_signature(c["screening"]) for c in cs if c["computational_status"]=="success"))
        Dict("id"=>g["id"],"role"=>g["role"],"candidate_count"=>length(cs),"classification_counts"=>Dict(k=>count(c->c["screening"]["classification"]==k,cs) for k in ("compatible","incompatible","undetermined")),"qualitative_signatures"=>signatures)
    end
    baseline=grid_summary(base);result=Dict{String,Any}[]
    for g in grids
        g["role"]=="baseline" && continue
        summary=grid_summary(g);common=sort(intersect(membership[base["id"]],membership[g["id"]]))
        push!(result,Dict("baseline"=>baseline,"comparison"=>summary,"shared_candidate_ids"=>common,"added_candidate_ids"=>sort(setdiff(membership[g["id"]],membership[base["id"]])),"removed_candidate_ids"=>sort(setdiff(membership[base["id"]],membership[g["id"]])),"new_qualitative_signatures"=>setdiff(summary["qualitative_signatures"],baseline["qualitative_signatures"]),"lost_qualitative_signatures"=>setdiff(baseline["qualitative_signatures"],summary["qualitative_signatures"]),"shared_results_policy"=>"Identical chemistry is run once and referenced by content identity; no inferred statistical confidence", "warning"=>"Finite sampled bounds and depth only; unchanged signatures do not prove grid convergence. Counts are not probabilities or evidence weights."))
    end
    result
end

function discover_paths(s::DiscoveryStudy,c::PHREEQCConfig=PHREEQCConfig();root="results")
    generated=generate_candidates(s) # Budget and every recipe validated BEFORE any engine execution.
    env=environment_check(c);dbtext=read(env.database,String)
    all(m->occursin(Regex("(?m)^"*m*"\\s*\$"),dbtext),s.spec["minerals"]) || throw(DependencyError("Requested phase absent from selected database"))
    mkpath(root);dir=abspath(mktempdir(root;prefix="discovery-",cleanup=false));project=dirname(dirname(@__DIR__))
    open(io->TOML.print(io,s.spec;sorted=true),joinpath(dir,"discovery.toml"),"w")
    open(io->TOML.print(io,Dict("candidates"=>generated.candidates,"membership"=>generated.membership);sorted=true),joinpath(dir,"generated-candidates.toml"),"w")
    cp(env.database,joinpath(dir,"database.dat"))
    for path in ("src","data","Project.toml","Manifest.toml");cp(joinpath(project,path),joinpath(dir,path));end
    write(joinpath(dir,"reproduce.jl"),"using MineralTrace\ns=load_discovery(joinpath(@__DIR__,\"discovery.toml\"))\nc=PHREEQCConfig(database=joinpath(@__DIR__,\"database.dat\"),timeout_seconds=$(c.timeout_seconds))\nr=discover_paths(s,c;root=joinpath(@__DIR__,\"reproduced\"))\nprintln(report(r))\n")
    frozen=PHREEQCConfig(executable=env.executable,database=joinpath(dir,"database.dat"),timeout_seconds=c.timeout_seconds)
    candidates=Dict{String,Any}[]
    for item in generated.candidates
        study=PathStudy(item["spec"]);definition=only(study.spec["paths"])
        candidate=run_candidate(study,definition,frozen,dir)
        candidate["screening"]=screen_discovered(s,candidate)
        candidate["coordinates"]=item["coordinates"];candidate["chemistry_sha256"]=item["chemistry_sha256"]
        candidate["environmental_sequence"]=item["environmental_sequence"]
        candidate["accessibility"]="all_declared_phases_always_accessible"
        push!(candidates,candidate)
    end
    groups=discovery_groups(candidates);sensitivity=sensitivity_comparisons(s,candidates,generated.membership)
    provenance=Dict{String,Any}("timestamp_utc"=>string(now(UTC)),"julia_version"=>string(VERSION),"package_version"=>string(pkgversion(@__MODULE__)),"database_sha256"=>env.database_sha256,"executable_sha256"=>bytes2hex(sha256(read(env.executable))),"config_sha256"=>bytes2hex(sha256(read(joinpath(dir,"discovery.toml")))),"generated_candidates_sha256"=>bytes2hex(sha256(read(joinpath(dir,"generated-candidates.toml")))),"enumeration"=>"deterministic bounded exhaustive enumeration of declared discrete grammar; no random seed, optimization or evidence-guided pruning","phase_access_policy"=>s.spec["accessibility"],"model_applicability"=>"unverified")
    provenance["source_sha256"]=Dict(relpath(joinpath(folder,f),dir)=>bytes2hex(sha256(read(joinpath(folder,f)))) for (folder,_,files) in walkdir(joinpath(dir,"src")) for f in files)
    provenance["evidence_sha256"]=Dict(relpath(joinpath(folder,f),dir)=>bytes2hex(sha256(read(joinpath(folder,f)))) for (folder,_,files) in walkdir(joinpath(dir,"data")) for f in files)
    provenance["engine_banners"]=unique([TOML.parsefile(joinpath(dir,p["archive"],"manifest.toml"))["engine_banner"] for candidate in candidates for p in candidate["steps"]])
    open(io->TOML.print(io,provenance;sorted=true),joinpath(dir,"provenance.toml"),"w")
    DiscoveryResult(s,candidates,generated.membership,sensitivity,groups,dir,provenance)
end
