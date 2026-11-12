struct RobustnessPlan
    spec::Dict{String,Any}
    function RobustnessPlan(spec::AbstractDict)
        d=deepcopy(Dict{String,Any}(spec));check_keys(d,["anchor_candidate","source_id","thresholds_mol","amount_change_threshold_mol","parameters","plane"],"robustness plan")
        all(k->d[k] isa AbstractString && !isempty(strip(d[k])),["anchor_candidate","source_id"]) || throw(ArgumentError("explicit anchor and source required"))
        ts=d["thresholds_mol"];ts isa AbstractVector && 2<=length(ts)<=20 && all(finite_real,ts) && issorted(ts) && length(unique(ts))==length(ts) || throw(ArgumentError("2–20 sorted unique thresholds required"))
        finite_real(d["amount_change_threshold_mol"]) && d["amount_change_threshold_mol"]>0 || throw(ArgumentError("explicit positive amount-change threshold required"))
        pars=d["parameters"];1<=length(pars)<=10 || throw(ArgumentError("1–10 one-at-a-time parameters required"))
        ids=String[]
        for p in pars
            check_keys(p,["id","parameter","units","values","operation_index"],"robustness parameter")
            name=p["parameter"];name in vcat(COMPONENTS,["pH","temperature","dose"]) || throw(ArgumentError("unsupported robustness parameter"))
            p["id"] isa AbstractString && !isempty(strip(p["id"])) || throw(ArgumentError("parameter ID required"));push!(ids,p["id"])
            p["units"]==(name=="dose" ? "mol" : AXIS_UNITS[name]) || throw(ArgumentError("parameter unit mismatch"))
            p["operation_index"] isa Integer && !(p["operation_index"] isa Bool) && (name=="dose" ? p["operation_index"]>=1 : p["operation_index"]==0) || throw(ArgumentError("dose references a 1-based environmental operation; initial parameters use index 0"))
            vs=p["values"];vs isa AbstractVector && 2<=length(vs)<=20 && issorted(vs) && all(finite_real,vs) && length(unique(vs))==length(vs) || throw(ArgumentError("2–20 sorted unique parameter values required"))
            name=="dose" ? all(v->0<v<=0.01,vs) || throw(ArgumentError("invalid reagent dose")) : foreach(v->valid_value(name,v),vs)
        end
        length(unique(ids))==length(ids) || throw(ArgumentError("duplicate parameter ID"))
        plane=d["plane"];check_keys(plane,["x_parameter_id","y_parameter_id"],"sampled plane")
        plane["x_parameter_id"] in ids && plane["y_parameter_id"] in ids && plane["x_parameter_id"]!=plane["y_parameter_id"] || throw(ArgumentError("plane requires two distinct declared parameters"))
        xp=only(p for p in pars if p["id"]==plane["x_parameter_id"]);yp=only(p for p in pars if p["id"]==plane["y_parameter_id"])
        (xp["parameter"],xp["operation_index"])!=(yp["parameter"],yp["operation_index"]) || throw(ArgumentError("plane axes must be physically distinct"))
        new(d)
    end
end
load_robustness(path::AbstractString)=RobustnessPlan(TOML.parsefile(path))

function robustness_digest(item)
    s=item["spec"]
    identity=Dict("initial"=>s["initial"],"temperature_c"=>s["initial_temperature_c"],"sequence"=>item["environmental_sequence"],"phases"=>s["phases"],"boundary"=>s["boundary"])
    io=IOBuffer();TOML.print(io,identity;sorted=true);bytes2hex(sha256(take!(io)))
end
function parameter_value(item,p)
    name=p["parameter"];spec=item["spec"]
    name=="dose" && return item["environmental_sequence"][p["operation_index"]]["amount_mol"]
    name=="temperature" && return spec["initial_temperature_c"]
    name=="pH" ? spec["initial"]["pH"] : spec["initial"]["totals"][name]
end
function perturb_item(s,item,p,value)
    next=deepcopy(item);name=p["parameter"]
    if name=="dose"
        i=p["operation_index"];i<=length(next["environmental_sequence"]) && next["environmental_sequence"][i]["kind"] in ("HCl","NaOH") || throw(ArgumentError("dose index must select a reagent operation"))
        next["environmental_sequence"][i]["amount_mol"]=Float64(value)
        only(next["spec"]["paths"])["operations"][i+1]["amount_mol"]=Float64(value)
    else
        next["coordinates"][name]=Float64(value)
        recipe=discovery_recipe(s,next["coordinates"])
        for key in ("initial","initial_temperature_c");next["spec"][key]=recipe[key];end
    end
    sum((get(op,"amount_mol",0.) for op in next["environmental_sequence"]);init=0.)<=s.spec["search"]["max_total_addition_mol"]+1e-15 || throw(ArgumentError("perturbation exceeds declared cumulative dose budget"))
    digest=robustness_digest(next);next["chemistry_sha256"]=digest;next["id"]="candidate-"*digest[1:16]
    only(next["spec"]["paths"])["id"]=next["id"];PathStudy(next["spec"])
    next
end

function verify_discovery_states(r::DiscoveryResult)
    # Reclassification is allowed only for the same archived chemistry; never rerun/rewrite pH to change a detection threshold.
    TOML.parsefile(joinpath(r.directory,"discovery.toml"))==r.study.spec || throw(ArgumentError("discovery configuration changed; recalculate chemistry"))
    bytes2hex(sha256(read(joinpath(r.directory,"database.dat"))))==r.provenance["database_sha256"] || throw(ArgumentError("archived database changed"))
    hashes=Dict{String,String}()
    for c in r.candidates
        stocks=Dict(p["mineral"]=>Float64(p["initial_mol"]) for p in r.study.spec["phases"])
        for p in c["steps"]
            dir=joinpath(r.directory,p["archive"])
            bytes2hex(sha256(read(joinpath(dir,"input.pqi"))))==p["input_sha256"] || throw(ArgumentError("archived input changed"))
            raw=only(read_selected(joinpath(dir,"selected.tsv")));raw==p["selected"] || throw(ArgumentError("selected states changed"))
            for m in keys(stocks)
                after=p["index"]==0 ? stocks[m] : parse(Float64,raw["solid_$m"])
                tr=p["phase_transfers"][m]
                tr["solid_gain_mol"]==after-stocks[m] && tr["remaining_mol"]==after || throw(ArgumentError("reaction increments differ from archived states"))
                stocks[m]=after
            end
            hashes[c["id"]*":"*string(p["index"])]=bytes2hex(sha256(read(joinpath(dir,"selected.tsv"))))
        end
    end
    hashes
end

function analyze_robustness(r::DiscoveryResult,plan::RobustnessPlan,c::PHREEQCConfig=PHREEQCConfig())
    d=plan.spec;s=r.study;floor=s.spec["diagnostics"]["mass_absolute_tolerance_mol"]
    all(t->t>floor,d["thresholds_mol"]) && s.spec["search"]["reaction_threshold_mol"] in d["thresholds_mol"] || throw(ArgumentError("thresholds must exceed numeric tolerance and include the original threshold"))
    statehashes=verify_discovery_states(r)
    generated=generate_candidates(s);items=Dict(x["id"]=>x for x in generated.candidates)
    haskey(items,d["anchor_candidate"]) || throw(ArgumentError("anchor is not in the generated search"))
    anchor=items[d["anchor_candidate"]];lookup=Dict(x["id"]=>x for x in r.candidates)
    original=lookup[d["anchor_candidate"]]
    original["computational_status"]=="success" || throw(ArgumentError("anchor chemistry must be successfully computed"))
    env=environment_check(c);env.database_sha256==r.provenance["database_sha256"] || throw(ArgumentError("OAT requires the same database as discovery"))
    bytes2hex(sha256(read(env.executable)))==r.provenance["executable_sha256"] || throw(ArgumentError("OAT requires the same engine binary as discovery"))
    frozen=PHREEQCConfig(executable=env.executable,database=joinpath(r.directory,"database.dat"),timeout_seconds=c.timeout_seconds)
    # Validate all prospective runs before adding computations; never skip invalid values and silently narrow the range.
    perturbations=Dict{String,Vector{Dict{String,Any}}}()
    for p in d["parameters"]
        parameter_value(anchor,p) in p["values"] || throw(ArgumentError("OAT values must include the anchor parameter"))
        perturbations[p["id"]]=[perturb_item(s,anchor,p,v) for v in p["values"]]
    end
    oat=Dict{String,Any}[]
    for p in d["parameters"]
        records=Dict{String,Any}[]
        for (value,item) in zip(p["values"],perturbations[p["id"]])
            id=item["id"]
            if !haskey(lookup,id)
                ps=PathStudy(item["spec"]);candidate=run_candidate(ps,only(ps.spec["paths"]),frozen,r.directory)
                candidate["screening"]=screen_discovered(s,candidate);candidate["coordinates"]=item["coordinates"];candidate["chemistry_sha256"]=item["chemistry_sha256"];candidate["environmental_sequence"]=item["environmental_sequence"]
                lookup[id]=candidate;items[id]=item
            end
            candidate=lookup[id]
            amounts=candidate["computational_status"]=="success" ? Dict(m=>last(candidate["steps"])["phase_transfers"][m]["remaining_mol"]-first(candidate["steps"])["phase_transfers"][m]["remaining_mol"] for m in s.spec["minerals"]) : nothing
            push!(records,Dict("value"=>value,"candidate_id"=>id,"computational_status"=>candidate["computational_status"],"classification"=>candidate["screening"]["classification"],"qualitative_signature"=>response_signature(candidate["screening"]),"charge_review_required"=>any(step->step["charge_diagnostic"]["diagnostic_status"]!="within_declared_threshold",candidate["steps"]),"net_solid_gain_mol"=>amounts))
        end
        successful=[q for q in records if q["computational_status"]=="success"]
        spans=Dict(m=>isempty(successful) ? nothing : maximum(q["net_solid_gain_mol"][m] for q in successful)-minimum(q["net_solid_gain_mol"][m] for q in successful) for m in s.spec["minerals"])
        signaturechange=length(unique(q["qualitative_signature"] for q in successful))>1
        classchange=length(unique(q["classification"] for q in records))>1
        kind=length(successful)!=length(records) ? "undetermined_due_to_calculation_failure" : signaturechange || classchange ? "reaction_or_classification_change" : any(v->v!==nothing && v>=d["amount_change_threshold_mol"],values(spans)) ? "amount_only_change" : "below_declared_amount_change_threshold"
        push!(oat,Dict("parameter"=>p,"records"=>records,"net_amount_span_mol"=>spans,"effect_category"=>kind,"classification_changed"=>classchange,"reaction_signature_changed"=>signaturechange,"warning"=>"One parameter at a time around this anchor, with no compensating ion adjustment; not global identifiability or parameter probability"))
    end
    threshold_records=Dict{String,Any}[]
    for t in d["thresholds_mol"]
        changed=deepcopy(s.spec);changed["search"]["reaction_threshold_mol"]=t;ts=DiscoveryStudy(changed)
        results=[merge(Dict("candidate_id"=>x["id"]),screen_discovered(ts,x)) for x in r.candidates]
        flips=[x["candidate_id"] for x in results if x["classification"]!=lookup[x["candidate_id"]]["screening"]["classification"]]
        push!(threshold_records,Dict("threshold_mol"=>t,"counts"=>Dict(k=>count(x->x["classification"]==k,results) for k in ("compatible","incompatible","undetermined")),"flipped_candidate_ids"=>flips,"classifications"=>results,"chemistry_recomputed"=>false))
    end
    plane=d["plane"];xp=only(p for p in d["parameters"] if p["id"]==plane["x_parameter_id"]);yp=only(p for p in d["parameters"] if p["id"]==plane["y_parameter_id"])
    (xp["parameter"],xp["operation_index"])!=(yp["parameter"],yp["operation_index"]) || throw(ArgumentError("plane axes must be physically distinct"))
    points=Dict{String,Any}[]
    for (id,item) in sort(collect(items);by=first)
        # Same sequence structure required before indexing a dose axis; arbitrary paths are not pooled onto a fake plane.
        [op["kind"] for op in item["environmental_sequence"]]==[op["kind"] for op in anchor["environmental_sequence"]] || continue
        normalized=deepcopy(item)
        for p in (xp,yp)
            value=parameter_value(anchor,p);name=p["parameter"]
            if name=="dose"
                normalized["environmental_sequence"][p["operation_index"]]["amount_mol"]=value
            elseif name=="temperature"
                normalized["spec"]["initial_temperature_c"]=value
            elseif name=="pH"
                normalized["spec"]["initial"]["pH"]=value
            else
                normalized["spec"]["initial"]["totals"][name]=value
            end
        end
        robustness_digest(normalized)==anchor["chemistry_sha256"] || continue
        push!(points,Dict("x"=>parameter_value(item,xp),"y"=>parameter_value(item,yp),"candidate_id"=>id,"classification"=>lookup[id]["screening"]["classification"]))
    end
    # All samples are preserved; missing Cartesian cells are explicitly listed, never interpolated.
    xs=sort(unique(vcat(Float64.(xp["values"]),[p["x"] for p in points])));ys=sort(unique(vcat(Float64.(yp["values"]),[p["y"] for p in points])))
    unsampled=[Dict("x"=>x,"y"=>y) for x in xs for y in ys if !any(p->p["x"]==x && p["y"]==y,points)]
    Dict{String,Any}("plan"=>d,"anchor_chemistry_sha256"=>anchor["chemistry_sha256"],"threshold_sensitivity"=>threshold_records,"one_at_a_time"=>oat,"sampled_plane"=>Dict("x_parameter"=>xp,"y_parameter"=>yp,"points"=>points,"unsampled_cells"=>unsampled,"interpretation"=>"Measured computation points only, no continuous compatibility boundary or unique geological history"),"verified_selected_output_sha256"=>statehashes,"candidates"=>[lookup[id] for id in sort(collect(keys(lookup)))],"formation_order_classification"=>"undetermined")
end
