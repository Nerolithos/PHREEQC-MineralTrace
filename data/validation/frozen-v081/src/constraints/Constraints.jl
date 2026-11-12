"""Structured user evidence; missing source/stage stay absent, never fabricated."""
struct EvidenceConstraint
    spec::Dict{String,Any}
    function EvidenceConstraint(spec::AbstractDict)
        d=deepcopy(Dict{String,Any}(spec))
        check_keys(d,["id","parameter","type","units","source_id","classification","stage_id","lower","upper","value","tolerance"],"constraint")
        all(k->haskey(d,k),("id","parameter","type","units","classification")) || throw(ArgumentError("constraint id, parameter, type, units, classification required"))
        all(k->d[k] isa AbstractString,("id","parameter","type","units","classification")) || throw(ArgumentError("constraint metadata must be strings"))
        for k in ("source_id","stage_id")
            !haskey(d,k) || d[k] isa AbstractString || throw(ArgumentError("$k must be a string or omitted"))
        end
        isempty(strip(d["id"])) && throw(ArgumentError("empty constraint id"))
        d["classification"] in ("Observation","Assumption") || throw(ArgumentError("constraint classification must be Observation or Assumption"))
        kind=d["type"]; p=d["parameter"]
        kind in ("interval","measurement","saturation","quality","stage") || throw(ArgumentError("unsupported constraint type"))
        common=["id","parameter","type","units","source_id","classification","stage_id"]
        specific=kind=="interval" ? ["lower","upper"] : kind in ("measurement","saturation") ? ["value","tolerance"] : kind=="quality" ? ["upper"] : String[]
        check_keys(d,vcat(common,specific),"$kind constraint")
        if kind in ("interval","measurement")
            haskey(AXIS_UNITS,p) || throw(ArgumentError("unsupported constrained parameter $p"))
            d["units"]==AXIS_UNITS[p] || throw(ArgumentError("constraint unit mismatch for $p"))
            if kind=="interval"
                lo=d["lower"]; hi=d["upper"]
                valid_evidence_value(p,lo);valid_evidence_value(p,hi); lo<=hi || throw(ArgumentError("reversed interval"))
            else
                p in COMPONENTS || throw(ArgumentError("measurement constraints support dissolved component totals"))
                valid_evidence_value(p,d["value"])
                finite_real(d["tolerance"]) && d["tolerance"]>=0 || throw(ArgumentError("measurement needs finite nonnegative absolute tolerance"))
            end
        elseif kind=="saturation"
            p in ("Fluorite","Calcite") && d["units"]=="SI" || throw(ArgumentError("invalid saturation phase/units"))
            get(d,"classification","")=="Assumption" || throw(ArgumentError("mineral equilibrium is an Assumption, not a direct observation"))
            finite_real(d["value"]) && finite_real(d["tolerance"]) && d["tolerance"]>0 || throw(ArgumentError("saturation target/tolerance invalid"))
        elseif kind=="quality"
            p=="charge_error" && d["units"]=="percent" || throw(ArgumentError("quality constraint requires charge_error percent"))
            finite_real(d["upper"]) && d["upper"]>=0 || throw(ArgumentError("charge threshold must be finite nonnegative"))
        else
            p in ("Fluorite","Calcite") && d["units"]=="stage_id" || throw(ArgumentError("stage constraint requires selected mineral/stage_id units"))
            !isempty(strip(get(d,"stage_id",""))) || throw(ArgumentError("explicit formation-stage identifier required"))
        end
        new(d)
    end
end

function validate_evaluation(d)
    e=get(d,"evaluation",Dict{String,Any}())
    check_keys(e,["mode","max_charge_error_percent"],"evaluation")
    get(e,"mode","exploratory") in ("strict","exploratory") || throw(ArgumentError("evaluation mode must be strict or exploratory"))
    v=get(e,"max_charge_error_percent",0.1)
    finite_real(v) && v>=0 || throw(ArgumentError("invalid charge quality threshold"))
    constraints=EvidenceConstraint.(get(d,"constraints",Any[]))
    ids=[c.spec["id"] for c in constraints]
    length(unique(ids))==length(ids) || throw(ArgumentError("duplicate constraint IDs"))
    for c in constraints
        if c.spec["type"] in ("saturation","stage")
            c.spec["parameter"] in d["minerals"] || throw(ArgumentError("constraint refers to an unselected mineral"))
        end
    end
    nothing
end

"""No charge adjustment. All amounts are aqueous species molalities, not element totals."""
function charge_equivalents(amounts::AbstractDict,charges::AbstractDict)
    Set(keys(amounts))==Set(keys(charges)) || throw(ArgumentError("species and charges must match"))
    cat=0.; an=0.
    for k in sort(collect(keys(amounts)))
        n=amounts[k]
        finite_real(n) && n>=0 || throw(ArgumentError("finite nonnegative species molalities required"))
        z=charges[k]; z isa Integer || throw(ArgumentError("integer species charges required"))
        z>0 && (cat+=n*z); z<0 && (an-=n*z)
    end
    Dict{String,Any}("cation_eq_per_kgw"=>cat,"anion_eq_per_kgw"=>an,"net_eq_per_kgw"=>cat-an,"percent_error"=>cat+an==0 ? nothing : 100*(cat-an)/(cat+an))
end

function species_charge(name)
    m=match(r"([+-])(\d*)$",name)
    isnothing(m) ? 0 : (m[1]=="+" ? 1 : -1)*(isempty(m[2]) ? 1 : parse(Int,m[2]))
end

"""Independent equivalent sum from rounded species table; a diagnostic, not an activity-model validation."""
function species_charge_audit(path)
    text=read(path,String)
    part=match(r"(?s)Distribution of species(.*?)Saturation indices",text)
    isnothing(part) && return Dict{String,Any}("status"=>"unavailable")
    amounts=Dict{String,Float64}()
    for line in split(part[1],'\n')
        f=split(line)
        length(f)>=6 || continue
        occursin(r"^[A-Za-z]",f[1]) || continue
        n=tryparse(Float64,f[2]); a=tryparse(Float64,f[3]); lg=tryparse(Float64,f[4])
        if n!==nothing && a!==nothing && lg!==nothing
            amounts[String(f[1])]=n
        end
    end
    isempty(amounts) && return Dict{String,Any}("status"=>"unavailable")
    result=charge_equivalents(amounts,Dict(k=>species_charge(k) for k in keys(amounts)))
    result["status"]="rounded_species_diagnostic";result["species_count"]=length(amounts)
    result
end

function constraint_value(c::EvidenceConstraint,s::MineralStudy,p)
    d=c.spec; kind=d["type"]; name=d["parameter"]
    if kind in ("interval","measurement")
        v=get(p["coordinates"],name,get(s.spec["fixed"],name,get(s.spec["fluid"]["totals"],name,nothing)))
        v===nothing && return "unverified"
        return (kind=="interval" ? d["lower"]<=v<=d["upper"] : abs(v-d["value"])<=d["tolerance"]) ? "pass" : "fail"
    elseif kind=="stage"
        study_stage=get(s.spec,"stage_id",nothing)
        return study_stage===nothing ? "unverified" : study_stage==d["stage_id"] ? "pass" : "fail"
    elseif !haskey(p,"selected")
        return "unverified"
    elseif kind=="quality"
        return abs(parse(Float64,p["selected"]["pct_err"]))<=d["upper"] ? "pass" : "fail"
    else
        return abs(p["si"][name]-d["value"])<d["tolerance"] ? "pass" : "fail"
    end
end

function evaluate_constraints(s::MineralStudy,p; database_sha256="", database_phases_available=true)
    recorded_db=get(p,"database_sha256","")
    database_sha256!="" && recorded_db!="" && database_sha256!=recorded_db && throw(ArgumentError("point database does not match requested database"))
    database_sha256=database_sha256=="" ? recorded_db : database_sha256
    if haskey(p,"input_sha256")
        expected=bytes2hex(sha256(codeunits(study_input(s,p["coordinates"]))))
        p["input_sha256"]==expected || throw(ArgumentError("point chemistry/input does not exactly match this study; rerun PHREEQC"))
    end
    mode=get(get(s.spec,"evaluation",Dict()),"mode","exploratory")
    threshold=get(get(s.spec,"evaluation",Dict()),"max_charge_error_percent",0.1)
    success=p["status"]!="failed"
    engine_warnings=[w for w in p["warnings"] if !startswith(w,"Charge imbalance ")]
    chemical= !success ? "unverified" : abs(parse(Float64,p["selected"]["pct_err"]))<=threshold ? "pass" : "fail"
    model=database_phases_available ? "unverified" : "invalid"
    checks=Dict{String,Any}[]
    for c in EvidenceConstraint.(get(s.spec,"constraints",Any[]))
        source=get(c.spec,"source_id",nothing)
        sourced=source isa AbstractString && !isempty(strip(source))
        value=constraint_value(c,s,p)
        if c.spec["type"]=="saturation" && (get(c.spec,"stage_id",nothing)===nothing || get(s.spec,"stage_id",nothing)===nothing)
            value="unverified"
        end
        stage=get(c.spec,"stage_id",nothing)
        if c.spec["type"]!="stage" && stage!==nothing && stage!=get(s.spec,"stage_id",nothing)
            value="unverified" # Evidence assigned to another stage must never silently constrain this one.
        end
        push!(checks,Dict("id"=>c.spec["id"],"type"=>c.spec["type"],"classification"=>c.spec["classification"],"value_status"=>value,"source_status"=>sourced ? "documented" : "missing","effective_status"=>!sourced && mode=="strict" && value!="fail" ? "unverified" : value))
    end
    obs=[q for q in checks if q["classification"]=="Observation"]
    obs_status=any(q->q["effective_status"]=="fail",obs) ? "fail" : any(q->q["effective_status"]=="unverified",obs) ? "unverified" : "pass"
    reasons=String[]
    !isempty(engine_warnings) && push!(reasons,"unresolved_engine_diagnostic")
    !success && push!(reasons,"computational_failure: "*p["error"])
    chemical=="fail" && push!(reasons,"charge_error_exceeds_$(threshold)_percent")
    model!="verified" && push!(reasons,model=="invalid" ? "missing_phase_definition" : "model_applicability_not_independently_validated")
    p["status"]=="incompatible" && push!(reasons,"outside_declared_SI_tolerances")
    for q in checks
        q["effective_status"]!="pass" && push!(reasons,"constraint_$(q["id"]):$(q["effective_status"])")
        q["source_status"]=="missing" && push!(reasons,"missing_source:$(q["id"])")
    end
    hard= !success || chemical=="fail" || model=="invalid" || p["status"]=="incompatible" || any(q->q["effective_status"]=="fail",checks)
    unknown=!haskey(p,"input_sha256") || !isempty(engine_warnings) || chemical=="unverified" || model=="unverified" || any(q->q["effective_status"]=="unverified" || q["source_status"]=="missing",checks)
    # Unknown constraint values cannot be included even in exploratory mode.
    unresolved=any(q->q["effective_status"]=="unverified",checks)
    final=hard ? "excluded" : unresolved || (mode=="strict" && unknown) ? "unverified" : unknown ? "included_conditional" : "included"
    included=final in ("included","included_conditional")
    regions=Dict{String,Any}("raw_si"=>success ? p["status"]=="compatible" : nothing,"chemically_admissible"=>success ? chemical=="pass" : nothing,
        "observation_constrained"=>obs_status=="unverified" || !success ? nothing : p["status"]=="compatible" && chemical=="pass" && obs_status=="pass", "final_feasible"=>included,"unverified"=>!success || unknown)
    sources=Dict("charge_diagnostic"=>[w for w in p["warnings"] if startswith(w,"Charge imbalance ")],"engine_diagnostics"=>engine_warnings,"model_limitations"=>["Ca-F-C species completeness, activity model and temperature applicability are not fully validated; the locked database omits active CaF+."])
    failure_kind=success ? "none" : !database_phases_available ? "missing_phase" : occursin(r"(?i)converg|iteration",p["error"]) ? "numerical_failure" : "engine_or_output_failure"
    Dict{String,Any}("provenance_status"=>haskey(p,"input_sha256") ? "input_hash_matched" : "not_supplied","warning_sources"=>sources,"failure_kind"=>failure_kind,"evaluation_mode"=>mode,"computational_status"=>success ? "success" : "failed","chemical_quality_status"=>chemical,
        "model_applicability_status"=>model,"model_details"=>Dict("database_sha256"=>database_sha256,"phase_definitions"=>database_phases_available ? "available" : "missing","species_completeness"=>"unverified","CaF+"=>database_sha256=="59373961d648dfbf68a40744060c1d64f57ecbec98f4f5fb89f3a1b4213ccd10" ? "commented_out" : "not_audited","activity_model"=>database_sha256=="59373961d648dfbf68a40744060c1d64f57ecbec98f4f5fb89f3a1b4213ccd10" ? "ion association; species-specific WATEQ gamma / Davies defaults" : "not_audited","temperature_applicability"=>"unverified"),
        "observation_status"=>obs_status,"final_status"=>final,"regions"=>regions,"constraints"=>checks,"reasons"=>reasons,"charge_threshold_percent"=>threshold)
end

"""Sample counts only. Redundancy/conflict are grid-relative, not logical or probabilistic claims."""
function constraint_contribution(s::MineralStudy,points)
    defs=EvidenceConstraint.(get(s.spec,"constraints",Any[])); ids=[c.spec["id"] for c in defs]
    # The physical baseline omits evidence filters; model gate is reported separately.
    base=[i for (i,p) in enumerate(points) if p["status"]=="compatible" && p["evaluation"]["chemical_quality_status"]=="pass"]
    pass(i,id)=only(q for q in points[i]["evaluation"]["constraints"] if q["id"]==id)["effective_status"]=="pass"
    candidates=copy(base); sequential=Dict{String,Any}[]
    for id in ids
        before=length(candidates);filter!(i->pass(i,id),candidates)
        push!(sequential,Dict("id"=>id,"before"=>before,"after"=>length(candidates),"removed"=>before-length(candidates)))
    end
    n=length(candidates); loo=Dict{String,Any}[]
    for id in ids
        remaining=[i for i in base if all(other->other==id || pass(i,other),ids)]
        added=setdiff(remaining,candidates)
        push!(loo,Dict("id"=>id,"without_count"=>length(remaining),"added_count"=>length(added),"redundant_on_grid"=>!isempty(base) && isempty(added),"assessment"=>isempty(base) ? "undetermined_empty_baseline" : "grid_relative","conflict_relief"=>n==0 && !isempty(remaining)))
    end
    strict=get(get(s.spec,"evaluation",Dict()),"mode","exploratory")=="strict"
    finalbase=[i for i in base if points[i]["evaluation"]["model_applicability_status"]!="invalid" && (!strict || points[i]["evaluation"]["model_applicability_status"]=="verified")]
    finalseq=Dict{String,Any}[]; filtered=copy(finalbase)
    for id in ids
        before=length(filtered);filter!(i->pass(i,id),filtered)
        push!(finalseq,Dict("id"=>id,"before"=>before,"after"=>length(filtered),"removed"=>before-length(filtered)))
    end
    finalloo=[Dict("id"=>id,"without_count"=>count(i->all(other->other==id || pass(i,other),ids),finalbase),"added_count"=>count(i->all(other->other==id || pass(i,other),ids),finalbase)-length(filtered)) for id in ids]
    Dict("baseline_final_inclusion_count"=>length(finalbase),"final_sequential"=>finalseq,"final_leave_one_out"=>finalloo,"baseline_si_and_chemistry_count"=>length(base),"after_evidence_count"=>n,"final_feasible_count"=>count(p->p["evaluation"]["regions"]["final_feasible"],points),"sequential"=>sequential,"leave_one_out"=>loo,
        "conflict_on_sampled_grid"=>!isempty(base) && !isempty(ids) && n==0 && all(i->all(q->q["effective_status"]!="unverified",points[i]["evaluation"]["constraints"]),base),"scope"=>"Counts depend on sampled axes, bounds and resolution; no physical probability measure is defined. Empty baseline cannot establish evidence conflict. Redundancy is conditional on all other constraints.")
end

"""Four-neighbor components of included sampled cells; not continuous geological regions."""
function grid_components(points)
    remaining=Dict((p["ix"],p["iy"])=>i for (i,p) in enumerate(points) if p["evaluation"]["regions"]["final_feasible"])
    components=Vector{Int}[]
    while !isempty(remaining)
        first_key=first(sort(collect(keys(remaining))))
        queue=[first_key]; component=Int[]
        while !isempty(queue)
            key=popfirst!(queue);haskey(remaining,key) || continue
            push!(component,pop!(remaining,key));x,y=key
            append!(queue,[(x-1,y),(x+1,y),(x,y-1),(x,y+1)])
        end
        push!(components,sort(component))
    end
    components
end

function valid_evidence_value(name,v)
    v isa Real && !(v isa Bool) && isfinite(v) || throw(ArgumentError("finite numeric evidence value required"))
    lower=name=="temperature" ? -273.15 : 0.
    v>=lower && (name!="pH" || v<=14) || throw(ArgumentError("evidence value outside physical bounds"))
end

finite_real(x)=x isa Real && !(x isa Bool) && isfinite(x)
