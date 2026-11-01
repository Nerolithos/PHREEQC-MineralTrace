"""Bounded, evidence-independent environmental path enumeration with invariant mineral access."""
struct DiscoveryStudy
    spec::Dict{String,Any}
    function DiscoveryStudy(spec::AbstractDict)
        d=deepcopy(Dict{String,Any}(spec))
        common=["title","boundary","initial_temperature_c","allow_unvalidated_temperature","initial","minerals","phases","diagnostics","evaluation_mode","events","evidence"]
        check_keys(d,vcat(common,["accessibility","search","grids"]),"discovery study")
        d["accessibility"]=="all_declared_phases_always_accessible" || throw(ArgumentError("discovery cannot search phase activation; all declared phases must remain accessible"))
        names=[p["mineral"] for p in d["phases"]]
        Set(names)==Set(d["minerals"]) || throw(ArgumentError("every monitored mineral needs an explicit phase inventory"))
        q=d["search"]
        check_keys(q,["allowed_processes","max_depth","max_candidates","max_total_addition_mol","reaction_threshold_mol","source_id"],"search")
        allowed=q["allowed_processes"]
        !isempty(allowed) && length(unique(allowed))==length(allowed) && all(k->k in ("cooling","HCl","NaOH","equilibrium"),allowed) || throw(ArgumentError("select unique supported environmental processes"))
        q["max_depth"] isa Integer && !(q["max_depth"] isa Bool) && 1<=q["max_depth"]<=4 || throw(ArgumentError("search depth must be 1–4 environmental operations"))
        q["max_candidates"] isa Integer && !(q["max_candidates"] isa Bool) && 1<=q["max_candidates"]<=2000 || throw(ArgumentError("explicit candidate budget must be 1–2000"))
        finite_real(q["max_total_addition_mol"]) && 0<=q["max_total_addition_mol"]<=0.04 || throw(ArgumentError("explicit cumulative reagent budget required (0–0.04 mol)"))
        finite_real(q["reaction_threshold_mol"]) && q["reaction_threshold_mol"]>d["diagnostics"]["mass_absolute_tolerance_mol"] || throw(ArgumentError("reaction threshold must exceed numerical accounting tolerance"))
        q["source_id"] isa AbstractString && !isempty(strip(q["source_id"])) || throw(ArgumentError("search assumptions need a source"))
        grids=d["grids"];length(grids)==3 || throw(ArgumentError("declare baseline, resolution and range grids explicitly"))
        Set(g["role"] for g in grids)==Set(["baseline","resolution","range"]) || throw(ArgumentError("one grid of each sensitivity role required"))
        length(unique(g["id"] for g in grids))==3 || throw(ArgumentError("unique grid IDs required"))
        for g in grids
            check_keys(g,["id","role","source_id","temperature_values_c","titrant_amounts_mol","initial_values"],"search grid")
            all(k->g[k] isa AbstractString && !isempty(strip(g[k])),["id","source_id"]) || throw(ArgumentError("grid ID/source required"))
            for (key,values) in (("temperature",g["temperature_values_c"]),("dose",g["titrant_amounts_mol"]))
                values isa AbstractVector && length(values)<=20 && all(finite_real,values) && issorted(values) && length(unique(values))==length(values) || throw(ArgumentError("grid values must be finite, sorted and unique"))
                if key=="temperature"
                    foreach(v->valid_value("temperature",v),values)
                else
                    all(v->0<v<=0.01,values) || throw(ArgumentError("titrant increments must be >0 and <=0.01 mol"))
                end
            end
            "cooling" in allowed && isempty(g["temperature_values_c"]) && throw(ArgumentError("cooling needs explicit temperature samples"))
            any(k->k in allowed,["HCl","NaOH"]) && isempty(g["titrant_amounts_mol"]) && throw(ArgumentError("titrants need explicit dose samples"))
            check_keys(g["initial_values"],vcat(COMPONENTS,["pH","temperature"]),"initial grid")
            # At least one declared range is required, even if all its values coincide with the initial recipe.
            isempty(g["initial_values"]) && throw(ArgumentError("declare at least one initial parameter grid for range sensitivity"))
            for (parameter,values) in g["initial_values"]
                values isa AbstractVector && 1<=length(values)<=20 && all(finite_real,values) && issorted(values) && length(unique(values))==length(values) || throw(ArgumentError("initial samples must be sorted unique finite values"))
                foreach(v->valid_value(parameter,v),values)
            end
            prod(length(v) for v in Base.values(g["initial_values"]))<=q["max_candidates"] || throw(ArgumentError("initial Cartesian grid exceeds candidate budget"))
        end
        base=only(g for g in grids if g["role"]=="baseline");refined=only(g for g in grids if g["role"]=="resolution");ranged=only(g for g in grids if g["role"]=="range")
        # Resolution adds samples within identical bounds; range changes bounds at the same action resolution.
        changed=false
        for key in ("temperature_values_c","titrant_amounts_mol")
            a=base[key];b=refined[key]
            all(v->v in b,a) && (isempty(a) ? isempty(b) : (first(a)==first(b) && last(a)==last(b))) || throw(ArgumentError("resolution grid must nest baseline samples without changing bounds"))
            changed |= a!=b
            ranged[key]==a || throw(ArgumentError("range comparison must retain baseline environmental samples"))
        end
        Set(keys(base["initial_values"]))==Set(keys(refined["initial_values"]))==Set(keys(ranged["initial_values"])) || throw(ArgumentError("sensitivity grids must vary the same initial parameters"))
        rangechanged=false
        for key in keys(base["initial_values"])
            a=base["initial_values"][key];b=refined["initial_values"][key];r=ranged["initial_values"][key]
            all(v->v in b,a) && first(a)==first(b) && last(a)==last(b) || throw(ArgumentError("initial refinement must keep bounds and baseline samples"))
            changed |= a!=b
            rangechanged |= first(a)!=first(r) || last(a)!=last(r)
        end
        changed || throw(ArgumentError("resolution grid must actually add samples"))
        rangechanged || throw(ArgumentError("range grid must actually change at least one initial bound"))
        prototype=Dict{String,Any}(k=>deepcopy(d[k]) for k in common)
        prototype["paths"]=[Dict("id"=>"schema-check","source_id"=>q["source_id"],"operations"=>[Dict("id"=>"initial-equilibration","kind"=>"equilibrium","active_phases"=>names,"source_id"=>q["source_id"])],"bindings"=>Any[])]
        PathStudy(prototype)
        new(d)
    end
end
load_discovery(path::AbstractString)=DiscoveryStudy(TOML.parsefile(path))

function discovery_recipe(s::DiscoveryStudy,coordinates)
    keys_=["title","boundary","initial_temperature_c","allow_unvalidated_temperature","initial","minerals","phases","diagnostics","evaluation_mode","events","evidence"]
    d=Dict{String,Any}(k=>deepcopy(s.spec[k]) for k in keys_)
    for (k,v) in coordinates
        if k=="temperature";d["initial_temperature_c"]=v
        elseif k=="pH";d["initial"]["pH"]=v
        else;d["initial"]["totals"][k]=v
        end
    end
    # Samples are explicitly assumed scenarios, even when the nominal recipe is an observation.
    # Preserve the original input unchanged in DiscoveryStudy and the exported discovery.toml.
    d["initial"]["origin"]="Assumption"
    d["initial"]["charge_context"]="hypothetical"
    d["initial"]["label"]="Sampled scenario (Assumption); nominal label: "*s.spec["initial"]["label"]
    d["initial"]["source"]="Declared search assumptions: "*s.spec["search"]["source_id"]*"; nominal source: "*s.spec["initial"]["source"]
    d
end

function initial_coordinates(g)
    names=sort(collect(keys(g["initial_values"])));result=[Dict{String,Float64}()]
    for key in names
        result=[merge(r,Dict(key=>Float64(v))) for r in result for v in g["initial_values"][key]]
    end
    result
end

function environmental_sequences(s::DiscoveryStudy,g,initial_temperature;limit=s.spec["search"]["max_candidates"])
    q=s.spec["search"];result=Vector{Dict{String,Any}}[]
    "equilibrium" in q["allowed_processes"] && push!(result,Dict{String,Any}[])
    function extend(prefix,temp,total)
        length(prefix)>=q["max_depth"] && return
        choices=Dict{String,Any}[]
        for kind in q["allowed_processes"]
            if kind=="cooling"
                append!(choices,[Dict{String,Any}("kind"=>"temperature","temperature_c"=>Float64(t)) for t in g["temperature_values_c"] if t<temp])
            elseif kind in ("HCl","NaOH")
                append!(choices,[Dict{String,Any}("kind"=>kind,"amount_mol"=>Float64(v),"addition_model"=>"formula_addition_no_carrier_water") for v in g["titrant_amounts_mol"] if total+v<=q["max_total_addition_mol"]+1e-15])
            else
                # An equilibrium-only control is the common initial equilibration. Repeated zero-change waits are not new chemical paths.
                continue
            end
        end
        for op in choices
            next=vcat(prefix,[op]);push!(result,next)
            length(result)>limit && throw(ArgumentError("candidate budget exceeded before execution; reduce grids/depth or explicitly increase budget"))
            extend(next,get(op,"temperature_c",temp),total+get(op,"amount_mol",0.))
        end
    end
    extend(Dict{String,Any}[],Float64(initial_temperature),0.)
    # The no-change control is included only when equilibrium is an allowed process.
    "equilibrium" in q["allowed_processes"] || filter!(x->!isempty(x),result)
    result
end

"""Generate every declared discrete path before reading evidence or calling the engine. Never truncate to best matches."""
function generate_candidates(s::DiscoveryStudy)
    generated=Dict{String,Any}[];bykey=Dict{String,Int}();members=Dict{String,Vector{String}}()
    for g in s.spec["grids"]
        ids=String[]
        for coordinate in initial_coordinates(g)
            base=discovery_recipe(s,coordinate)
            for sequence in environmental_sequences(s,g,base["initial_temperature_c"])
                # Identity excludes the evidence, grid name and event order. Identical chemistry shared across grids is run once.
                identity=Dict("initial"=>base["initial"],"temperature_c"=>base["initial_temperature_c"],"sequence"=>sequence,"phases"=>base["phases"],"boundary"=>base["boundary"])
                io=IOBuffer();TOML.print(io,identity;sorted=true);digest=bytes2hex(sha256(take!(io)));id="candidate-"*digest[1:16]
                if !haskey(bykey,digest)
                    phases=String[p["mineral"] for p in s.spec["phases"]]
                    operations=Dict{String,Any}[Dict("id"=>"initial-equilibration","kind"=>"equilibrium","active_phases"=>copy(phases),"source_id"=>s.spec["search"]["source_id"])]
                    for (i,op) in enumerate(sequence)
                        push!(operations,merge(deepcopy(op),Dict("id"=>"environment-$i","active_phases"=>copy(phases),"source_id"=>s.spec["search"]["source_id"])))
                    end
                    definition=Dict{String,Any}("id"=>id,"source_id"=>s.spec["search"]["source_id"],"operations"=>operations,"bindings"=>Any[])
                    basecopy=deepcopy(base);basecopy["paths"]=[definition]
                    PathStudy(basecopy) # Validate every sampled recipe and operation, not only the nominal fluid.
                    push!(generated,Dict("id"=>id,"chemistry_sha256"=>digest,"coordinates"=>coordinate,"spec"=>basecopy,"environmental_sequence"=>sequence))
                    bykey[digest]=length(generated)
                    length(generated)>s.spec["search"]["max_candidates"] && throw(ArgumentError("total unique candidate budget exceeded before execution; no partial search run"))
                end
                push!(ids,id)
            end
        end
        members[g["id"]]=unique(ids)
    end
    isempty(generated) && throw(ArgumentError("declared grids generate no environmental path"))
    (candidates=generated,membership=members)
end
