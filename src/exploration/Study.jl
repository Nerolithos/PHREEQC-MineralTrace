const COMPONENTS = ["Ca", "F", "C(4)", "Na", "Cl"]
const AXIS_UNITS = Dict("temperature"=>"degC", "pH"=>"dimensionless", (k=>"mol/kgw" for k in COMPONENTS)...)
const STUDY_WARNINGS = [
    "SI compatibility is conditional on supplied chemistry and same-stage equilibrium; it is not confirmed precipitation or geological history.",
    "Only sampled grid points are classified; unsampled conditions are undetermined. Tolerances are user-declared model tolerances.",
    "Database/species completeness and the full 25–80 °C activity-model range are not independently validated; CaF+ is commented out in the locked phreeqc.dat.",
    "Charge imbalance is reported without ion adjustment. SI-compatible points with chemical warnings require review.",
    "Historical USGS Example 1 mismatch remains unresolved. Current-engine regression is not independent scientific validation."]

struct MineralStudy
    spec::Dict{String,Any}
    function MineralStudy(spec::AbstractDict)
        d = deepcopy(Dict{String,Any}(spec))
        check_keys(d,["mode","minerals","assumption","allow_unvalidated_temperature","fluid","fixed","tolerances","axes","evaluation","constraints","stage_id"],"study")
        get(d,"mode","") in ("KnownFluid","HypothesisExplorer") || throw(ArgumentError("mode must be KnownFluid or HypothesisExplorer"))
        get(d,"assumption","") == "same_stage_equilibrium" || throw(ArgumentError("explicit same_stage_equilibrium assumption required"))
        minerals = get(d,"minerals",String[])
        !isempty(minerals) && length(unique(minerals)) == length(minerals) && all(m->m in ("Fluorite","Calcite"),minerals) || throw(ArgumentError("select Fluorite and/or Calcite once"))
        f = d["fluid"]
        check_keys(f,["units","totals","source","label","origin","charge_context"],"fluid")
        f["units"] == "mol/kgw" || throw(ArgumentError("fluid units must be mol/kgw"))
        all(k -> haskey(f["totals"],k),COMPONENTS) && length(f["totals"]) == length(COMPONENTS) || throw(ArgumentError("explicit Ca, F, C(4), Na, Cl totals required, including zeros; nothing is filled in"))
        for v in values(f["totals"])
            v isa Real && isfinite(v) && 0 <= v <= 0.1 || throw(ArgumentError("exploratory totals must be 0–0.1 mol/kgw"))
        end
        for k in ("source","label","origin")
            !isempty(strip(f[k])) || throw(ArgumentError("fluid $k is required"))
        end
        f["origin"] == (d["mode"] == "KnownFluid" ? "Observation" : "Assumption") || throw(ArgumentError("fluid origin must match input mode"))
        if haskey(f,"charge_context")
            f["charge_context"] in CHARGE_CONTEXTS || throw(ArgumentError("invalid charge_context"))
            f["charge_context"]=="analytical" && f["origin"]!="Observation" && throw(ArgumentError("analytical charge diagnostic requires observations"))
        end
        fixed = d["fixed"]
        check_keys(fixed,["temperature","pH","pressure_atm","water_kg","pe"],"fixed")
        all(k->haskey(fixed,k),("temperature","pH","pressure_atm","water_kg","pe")) || throw(ArgumentError("all fixed conditions must be explicit"))
        fixed["pressure_atm"] == 1 && fixed["water_kg"] == 1 || throw(ArgumentError("only 1 atm and 1 kg water supported"))
        all(v->v isa Real && isfinite(v),values(fixed)) || throw(ArgumentError("fixed conditions must be finite numbers"))
        -20 <= fixed["pe"] <= 20 || throw(ArgumentError("pe outside exploratory bounds"))
        valid_value("temperature",fixed["temperature"])
        valid_value("pH",fixed["pH"])
        axes = d["axes"]
        1 <= length(axes) <= 2 || throw(ArgumentError("one or two axes required"))
        names = [a["parameter"] for a in axes]
        length(unique(names)) == length(names) || throw(ArgumentError("duplicate scan axes"))
        for a in axes
            check_keys(a,["parameter","units","values"],"axis")
            name = a["parameter"]
            haskey(AXIS_UNITS,name) || throw(ArgumentError("unsupported scan axis $name"))
            a["units"] == AXIS_UNITS[name] || throw(ArgumentError("wrong units for $name"))
            vals = a["values"]
            length(vals) >= 2 && issorted(vals) && length(unique(vals)) == length(vals) || throw(ArgumentError("axis values must be strictly increasing with at least two points"))
            foreach(v->valid_value(name,v),vals)
        end
        prod(length(a["values"]) for a in axes) <= 2500 || throw(ArgumentError("maximum 2500 grid points"))
        temps = "temperature" in names ? axes[findfirst(==("temperature"),names)]["values"] : [fixed["temperature"]]
        any(!=(25),temps) && get(d,"allow_unvalidated_temperature",false) !== true && throw(ArgumentError("set allow_unvalidated_temperature=true to acknowledge exploratory temperature range"))
        Set(keys(d["tolerances"])) == Set(minerals) || throw(ArgumentError("tolerance keys must match selected minerals"))
        for m in minerals
            v = d["tolerances"][m]
            v isa Real && isfinite(v) && v > 0 || throw(ArgumentError("positive finite SI tolerance required for $m"))
        end
        validate_evaluation(d)
        new(d)
    end
end
function valid_value(name,v)
    v isa Real && isfinite(v) || throw(ArgumentError("nonfinite or nonnumeric $name"))
    lo,hi = name == "temperature" ? (25,80) : name == "pH" ? (0,14) : (0,0.1)
    lo <= v <= hi || throw(ArgumentError("$name outside exploratory bounds [$lo,$hi]"))
end
load_study(path::AbstractString) = MineralStudy(TOML.parsefile(path))

function study_input(s::MineralStudy, coordinates)
    d=s.spec; fixed=d["fixed"]; totals=merge(Dict{String,Float64}(d["fluid"]["totals"]),Dict(k=>Float64(v) for (k,v) in coordinates if k in COMPONENTS))
    t=get(coordinates,"temperature",fixed["temperature"]); ph=get(coordinates,"pH",fixed["pH"])
    f=FluidState(temperature_c=t,pH=ph,totals=totals,label=d["fluid"]["label"],allow_unvalidated_temperature=get(d,"allow_unvalidated_temperature",false))
    input=solution_input(f)
    input=replace(input,"    units mol/kgw"=>"    pe $(fixed["pe"])\n    units mol/kgw")
    input=replace(input,"    -saturation_indices Fluorite Calcite"=>"    -saturation_indices "*join(d["minerals"]," "))
    replace(input,"    -totals Ca F C(4)"=>"    -totals Ca F C(4) Na Cl\n    -molalities CO2 HCO3- CO3-2 HF F-\n    -water true")
end

function check_keys(d,allowed,section)
    unknown=setdiff(collect(keys(d)),allowed)
    isempty(unknown) || throw(ArgumentError("unknown $section keys: $unknown"))
end
