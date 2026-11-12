# Evidence scopes are separate from execution domains; neither is a scalar validity score.
const MODEL_DATA = normpath(joinpath(@__DIR__,"../../data/models"))
const BAR_PER_ATM = 1.01325
bar_to_atm(p::Real) = p / BAR_PER_ATM
atm_to_bar(p::Real) = p * BAR_PER_ATM

"""Narrow structural audit of PHREEQC text. Presence is not thermodynamic certification.
Unsupported INCLUDE\$ databases are explicitly incomplete, never silently certified.
"""
function audit_database(path; phases=["Calcite","CO2(g)"], species=["H+","OH-","H2O","Ca+2","HCO3-","CO3-2","CO2"])
    text=read(path,String);sections=Dict{String,Vector{String}}();section=""
    keywords=Set(["SOLUTION_MASTER_SPECIES","SOLUTION_SPECIES","PHASES","PITZER","SIT","EXCHANGE_MASTER_SPECIES","EXCHANGE_SPECIES","SURFACE_MASTER_SPECIES","SURFACE_SPECIES","RATES","END","NAMED_EXPRESSIONS","GAS_BINARY_PARAMETERS","LLNL_AQUEOUS_MODEL_PARAMETERS"])
    for line in split(text,'\n')
        plain=strip(first(split(line,'#')));isempty(plain) && continue
        token=uppercase(first(split(plain)))
        if token in keywords;section=token;get!(sections,section,String[]);continue;end
        push!(get!(sections,section,String[]),plain)
    end
    phaseblocks=Dict{String,Vector{String}}();current=""
    for line in get(sections,"PHASES",String[])
        if !occursin('=',line) && length(split(line))==1 && !startswith(line,'-') && tryparse(Float64,line)===nothing
            current=line;phaseblocks[current]=String[]
        elseif !isempty(current)
            push!(phaseblocks[current],line)
        end
    end
    # PHREEQC associates the definition with the first species on the right of the equation.
    defined=Set{String}()
    for line in get(sections,"SOLUTION_SPECIES",String[])
        occursin('=',line) || continue
        left,right=split(line,'=';limit=2)
        tokens=split(strip(right))
        !isempty(tokens) && push!(defined,tryparse(Float64,first(tokens))===nothing ? first(tokens) : length(tokens)>1 ? tokens[2] : "")
    end
    speciesblocks=Dict{String,Vector{String}}();current_species=""
    for line in get(sections,"SOLUTION_SPECIES",String[])
        if occursin('=',line)
            right=strip(last(split(line,'=';limit=2)));tokens=split(right)
            current_species=isempty(tokens) ? "" : tryparse(Float64,first(tokens))===nothing ? String(first(tokens)) : length(tokens)>1 ? String(tokens[2]) : ""
            speciesblocks[current_species]=[line]
        elseif !isempty(current_species)
            push!(speciesblocks[current_species],line)
        end
    end
    speciescoverage=Dict{String,Any}()
    for name in unique(vcat(species,["CaHCO3+","CaCO3","(CO2)2"]))
        block=get(speciesblocks,name,String[])
        speciescoverage[name]=Dict("present"=>haskey(speciesblocks,name),"definition"=>block,"temperature_dependence_present"=>any(l->occursin(r"(?i)(analytic|delta_h)",l),block),"volume_parameters_present"=>any(l->occursin(r"(?i)^-?vm\s",l),block),"explicit_gamma_present"=>any(l->occursin(r"(?i)^-?gamma\s",l),block))
    end
    coverage=Dict{String,Any}()
    for name in phases
        block=get(phaseblocks,name,String[])
        coverage[name]=Dict("present"=>haskey(phaseblocks,name),"definition"=>block,"temperature_dependence_present"=>any(l->occursin(r"(?i)(analytic|delta_h)",l),block),"molar_volume_present"=>any(l->occursin(r"(?i)^-?vm\s",l),block))
    end
    co2=join(get(phaseblocks,"CO2(g)",String[]),'\n');critical=Dict{String,Any}()
    for key in ("T_c","P_c","Omega")
        m=match(Regex("(?i)(?:^|[;\\s])-?"*key*"\\s+([-+0-9.eE]+)"),co2)
        critical[key]=isnothing(m) ? nothing : tryparse(Float64,m.captures[1])
    end
    pr=all(v->v isa Real && isfinite(v),values(critical)) && get(critical,"T_c",0)>0 && get(critical,"P_c",0)>0
    activity=haskey(sections,"PITZER") ? "pitzer" : haskey(sections,"SIT") ? "sit" : "ion_association"
    includes=occursin(r"(?im)^\s*INCLUDE\$",text)
    missing_phases=setdiff(phases,collect(keys(phaseblocks)));missing_species=setdiff(species,collect(defined))
    Dict{String,Any}("database_sha256"=>bytes2hex(sha256(codeunits(text))),"activity_model_family"=>activity,"phase_coverage"=>coverage,"aqueous_species_coverage"=>speciescoverage,"required_species"=>species,"present_required_species"=>sort(intersect(species,collect(defined))),"missing_required_species"=>missing_species,"missing_required_phases"=>missing_phases,"CO2_critical_parameters"=>critical,"CO2_EOS_available"=>pr ? "peng_robinson" : "ideal_or_incomplete_parameters","audit_complete"=>!includes,"coverage_pass"=>isempty(missing_phases)&&isempty(missing_species)&&!includes,"limitations"=>["Structural coverage only; constants, interactions and T/P validity require source-specific review","Species presence does not establish completeness; neutral CO2 and complex activity conventions matter","Missing explicit -Vm or temperature coefficients do not establish a valid zero correction","INCLUDE\$ dependencies are not resolved by this text audit","Database calibration lineage versus experiments remains incompletely documented"])
end

struct EvidenceRegistry
    entries::Dict{String,Dict{String,Any}}
    fingerprint::String
end
function load_evidence_registry(path=joinpath(MODEL_DATA,"evidence.toml"))
    d=TOML.parsefile(path);d["schema_version"]==1 || throw(ArgumentError("unknown evidence schema"))
    entries=Dict{String,Dict{String,Any}}()
    for e in d["entries"]
        required=["id","source_type","source_path","source_sha256","persistent_id","observable","conclusion","comparison_method","limitations","independent_of_calibration","domain","assumptions","numerical_result"]
        all(k->haskey(e,k),required) || throw(ArgumentError("incomplete evidence record"))
        e["source_type"] in ("independent_experiment","engine_reference","synthetic_regression","cross_study_analysis") || throw(ArgumentError("unknown evidence type"))
        e["conclusion"] in ("engine_verified","chemically_consistent","experimentally_supported","experimentally_challenged","applicability_unverified") || throw(ArgumentError("unknown evidence conclusion"))
        e["conclusion"] in ("experimentally_supported","experimentally_challenged") && e["source_type"]!="independent_experiment" && throw(ArgumentError("engine or synthetic evidence cannot grant experimental status"))
        e["conclusion"]=="experimentally_supported" && e["independent_of_calibration"]!==true && throw(ArgumentError("independent holdout lineage required for support"))
        source=normpath(joinpath(dirname(path),e["source_path"]))
        isfile(source) && bytes2hex(sha256(read(source)))==e["source_sha256"] || throw(ArgumentError("evidence source missing or fingerprint mismatch: $(e["id"])"))
        haskey(entries,e["id"]) && throw(ArgumentError("duplicate evidence identifier"))
        entries[e["id"]]=deepcopy(e)
    end
    EvidenceRegistry(entries,bytes2hex(sha256(read(path))))
end
struct ModelProfile
    spec::Dict{String,Any}
end
function ModelProfile(d::AbstractDict)
    q=deepcopy(Dict{String,Any}(d))
    required=["id","chemical_system","mineral_phases","aqueous_components","required_species","required_phases","database_identifier","database_sha256","activity_model","gas_model","boundary","domain","observables","statuses","experimental_references","known_discrepancies","unresolved_limitations","supports_equilibrium_paths"]
    issubset(Set(required),Set(keys(q))) && issubset(Set(keys(q)),Set(vcat(required,["cross_study_references"]))) || throw(ArgumentError("missing or unknown model profile fields"))
    occursin(r"^[a-f0-9]{64}$",q["database_sha256"]) || throw(ArgumentError("profile requires exact database SHA-256"))
    q["boundary"] in ("none_closed","fixed_partial_pressure","fixed_total_pressure","fixed_volume") || throw(ArgumentError("unknown gas boundary"))
    all(s->s in ("engine_verified","chemically_consistent","experimentally_supported","experimentally_challenged","applicability_unverified","out_of_scope"),q["statuses"]) || throw(ArgumentError("unknown nonordinal status"))
    for key in ("temperature_c","pressure_bar","ionic_strength_mol_kgw")
        v=q["domain"][key]
        v isa Vector && length(v)==2 && all(x->x isa Real && !(x isa Bool) && isfinite(x),v) && v[1]<=v[2] || throw(ArgumentError("invalid profile interval: $key"))
    end
    ModelProfile(q)
end
function load_model_profiles(path=joinpath(MODEL_DATA,"profiles.toml"); registry=load_evidence_registry())
    d=TOML.parsefile(path);d["schema_version"]==1 || throw(ArgumentError("unknown profile schema"))
    profiles=Dict{String,ModelProfile}()
    for row in d["profiles"]
        p=ModelProfile(row);haskey(profiles,row["id"]) && throw(ArgumentError("duplicate profile"))
        all(id->haskey(registry.entries,id),row["experimental_references"]) || throw(ArgumentError("unregistered evidence reference"))
        if "experimentally_supported" in row["statuses"]
            any(id->registry.entries[id]["conclusion"]=="experimentally_supported",row["experimental_references"]) || throw(ArgumentError("profile status lacks experimental support"))
        end
        refs=get(row,"cross_study_references",String[])
        refs isa AbstractVector && all(id->id isa AbstractString && haskey(registry.entries,id) && registry.entries[id]["source_type"]=="cross_study_analysis",refs) || throw(ArgumentError("invalid cross-study reference"))
        profiles[row["id"]]=p
    end
    profiles
end

# An evidence domain may consist of discrete JOINT points: never replace these with their convex hull.
function evidence_matches(e,q)
    d=e["domain"]
    all(k->haskey(q,k) && q[k]==d[k],intersect(["boundary","database_sha256","gas_model","activity_model"],collect(keys(d)))) || return false
    get(q,"observable",nothing)==e["observable"] || return false
    if haskey(d,"points")
        any(point->all(k->haskey(q,k) && q[k] isa Real && isapprox(q[k],point[k];atol=1e-8,rtol=0),keys(point)),d["points"]) || return false
    else
        return false # No evidence-domain rule => insufficient, never universal support.
    end
    true
end

"""Compare explicit model query against documented model/evidence scope; never infer impossibility."""
function evaluate_applicability(p::ModelProfile,q::AbstractDict; registry=load_evidence_registry(),database_audit=nothing)
    d=p.spec;matched=String[];unmatched=String[];unknown=String[]
    for key in ("database_sha256","activity_model","gas_model","boundary")
        !haskey(q,key) ? push!(unknown,key) : q[key]==d[key] ? push!(matched,key) : push!(unmatched,key)
    end
    for (key,allowed) in (("components",d["aqueous_components"]),("minerals",d["mineral_phases"]))
        !haskey(q,key) ? push!(unknown,key) : issubset(Set(q[key]),Set(allowed)) ? push!(matched,key) : push!(unmatched,key)
    end
    for key in ("temperature_c","pressure_bar","ionic_strength_mol_kgw")
        vals=get(q,key,nothing);vals=vals isa Real ? [vals] : vals
        if !(vals isa AbstractVector) || isempty(vals) || any(x->!(x isa Real) || x isa Bool || !isfinite(x),vals)
            push!(unknown,key)
        else
            lo,hi=d["domain"][key];all(v->lo<=v<=hi,vals) ? push!(matched,key) : push!(unmatched,key)
        end
    end
    observable=get(q,"observable",nothing)
    observable===nothing ? push!(unknown,"observable") : observable in d["observables"] ? push!(matched,"observable") : push!(unmatched,"observable")
    if database_audit===nothing
        push!(unknown,"database structural coverage")
    else
        get(database_audit,"database_sha256",nothing)==get(q,"database_sha256",nothing) || push!(unmatched,"database audit fingerprint")
        get(database_audit,"activity_model_family",nothing)==get(q,"activity_model",nothing) || push!(unmatched,"actual database activity family")
        get(database_audit,"coverage_pass",false) && all(m->haskey(database_audit["phase_coverage"],m) && database_audit["phase_coverage"][m]["present"],d["required_phases"]) && all(m->haskey(database_audit["aqueous_species_coverage"],m) && database_audit["aqueous_species_coverage"][m]["present"],d["required_species"]) || push!(unmatched,"required thermodynamic species/phases")
        d["gas_model"]=="peng_robinson" && database_audit["CO2_EOS_available"]!="peng_robinson" && push!(unmatched,"gas critical properties")
    end
    support=String[];challenged=String[];refs=String[]
    for id in d["experimental_references"]
        haskey(registry.entries,id) || throw(ArgumentError("unregistered evidence"));e=registry.entries[id]
        e["source_type"]=="independent_experiment" || continue
        evidence_matches(e,q) || continue
        push!(refs,id)
        e["conclusion"]=="experimentally_challenged" && push!(challenged,e["observable"])
        e["conclusion"]=="experimentally_supported" && e["independent_of_calibration"]===true && push!(support,e["observable"])
    end
    status=!isempty(unmatched) ? "outside_documented_scope" : !isempty(unknown) ? "unknown_evidence" : !isempty(challenged) ? "experimentally_challenged" : !isempty(support) ? "applicable_documented_scope" : "unknown_evidence"
    isempty(support) && isempty(challenged) && push!(unknown,"no independent evidence for requested joint conditions and observable")
    strict=status=="applicable_documented_scope" && d["supports_equilibrium_paths"] && observable=="equilibrium_reaction_path" && "experimentally_supported" in d["statuses"]
    Dict{String,Any}("model_profile_id"=>d["id"],"profile_match_status"=>status,"matched_conditions"=>matched,"unmatched_conditions"=>unmatched,"unknown_conditions"=>unknown,"experimentally_challenged_observables"=>unique(challenged),"experimentally_supported_observables"=>unique(support),"unsupported_extrapolations"=>vcat(unmatched,unknown),"applicable_reference_ids"=>refs,"profile_statuses"=>d["statuses"],"strict_qualified"=>strict,"evidence_registry_sha256"=>registry.fingerprint,"profile_sha256"=>bytes2hex(sha256(codeunits(json_value(d)))),"interpretation"=>"Documented scope is not physical possibility; endpoint support never certifies a path, rate or chronology")
end

function discovery_applicability(p,candidate,db_audit;registry=load_evidence_registry())
    steps=candidate["steps"]
    q=Dict{String,Any}("components"=>["Ca","F","C","Na","Cl","H","O"],"minerals"=>sort(collect(keys(first(steps)["phase_transfers"]))),"temperature_c"=>[s["temperature_c"] for s in steps],"pressure_bar"=>[haskey(s["selected"],"pressure_atm") ? parse(Float64,s["selected"]["pressure_atm"])*BAR_PER_ATM : NaN for s in steps],"ionic_strength_mol_kgw"=>[haskey(s["selected"],"ionic_strength") ? parse(Float64,s["selected"]["ionic_strength"]) : NaN for s in steps],"database_sha256"=>db_audit["database_sha256"],"activity_model"=>db_audit["activity_model_family"],"gas_model"=>"none","boundary"=>"none_closed","observable"=>"equilibrium_reaction_path")
    evaluate_applicability(p,q;registry,database_audit=db_audit)
end

"""Unweighted descriptive discrepancies; no statistical acceptance with unknown pointwise sigma."""
function comparison_statistics(observed,predicted)
    length(observed)==length(predicted)>0 || throw(ArgumentError("paired nonempty endpoints required"))
    all(x->x isa Real && isfinite(x) && x>0,observed) && all(x->x isa Real && isfinite(x),predicted) || throw(ArgumentError("finite predictions and strictly positive observations required"))
    errors=predicted.-observed;relative=errors./observed
    Dict{String,Any}("signed_absolute_errors"=>errors,"signed_relative_errors"=>relative,"mean_signed_error"=>sum(errors)/length(errors),"mean_absolute_error"=>sum(abs,errors)/length(errors),"root_mean_square_error"=>sqrt(sum(abs2,errors)/length(errors)),"maximum_absolute_relative_error"=>maximum(abs,relative),"pointwise_experimental_uncertainty"=>"UNKNOWN","uncertainty_weighted_acceptance"=>"not calculated","interpretation"=>"Descriptive endpoint differences, not confidence, validation score or model ranking")
end

"""Preflight a study without chemistry: ionic strength stays unknown until PHREEQC runs."""
function evaluate_applicability(p::ModelProfile,s::DiscoveryStudy,c::PHREEQCConfig;registry=load_evidence_registry())
    temps=Float64[s.spec["initial_temperature_c"]]
    for grid in s.spec["grids"]
        append!(temps,grid["temperature_values_c"])
        append!(temps,get(grid["initial_values"],"temperature",Float64[]))
    end
    a=audit_database(c.database;phases=p.spec["required_phases"],species=p.spec["required_species"])
    q=Dict{String,Any}("components"=>["Ca","F","C","Na","Cl","H","O"],"minerals"=>s.spec["minerals"],"temperature_c"=>temps,"pressure_bar"=>[BAR_PER_ATM],"database_sha256"=>a["database_sha256"],"activity_model"=>a["activity_model_family"],"gas_model"=>"none","boundary"=>"none_closed","observable"=>"equilibrium_reaction_path")
    evaluate_applicability(p,q;registry,database_audit=a)
end
