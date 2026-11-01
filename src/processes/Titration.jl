const TITRANT_ATOMS = Dict("HCl"=>Dict("H"=>1,"Cl"=>1),"NaOH"=>Dict("Na"=>1,"O"=>1,"H"=>1))
const PROCESS_ELEMENTS = ["Ca","F","C","Na","Cl","H","O"]

"""Auditable closed aqueous formula-addition titration, not a kinetic or precipitation model."""
struct AcidBaseTitration
    spec::Dict{String,Any}
    function AcidBaseTitration(spec::AbstractDict)
        d=deepcopy(Dict{String,Any}(spec))
        check_keys(d,["process","temperature_c","pressure_atm","allow_unvalidated_temperature","minerals","initial","titrant","diagnostics"],"process")
        d["process"]=="acid_base_titration" || throw(ArgumentError("only acid_base_titration supported"))
        finite_real(d["pressure_atm"]) && d["pressure_atm"]==1 || throw(ArgumentError("only 1 atm supported"))
        get(d,"allow_unvalidated_temperature",false) isa Bool || throw(ArgumentError("allow_unvalidated_temperature must be Boolean"))
        init=d["initial"]
        check_keys(init,["pH","pe","water_kg","units","totals","origin","source","label","charge_context"],"initial")
        init["units"]=="mol/kgw" || throw(ArgumentError("initial concentrations require mol/kgw"))
        Set(keys(init["totals"]))==Set(COMPONENTS) || throw(ArgumentError("explicit Ca, F, C(4), Na, Cl including zeros required"))
        all(v->finite_real(v)&&0<=v<=0.1,values(init["totals"])) || throw(ArgumentError("initial totals outside exploratory 0–0.1 mol/kgw bounds"))
        finite_real(init["water_kg"]) && 0<init["water_kg"]<=100 || throw(ArgumentError("initial water mass must be positive, <=100 kg"))
        finite_real(init["pH"]) && 0<=init["pH"]<=14 || throw(ArgumentError("numeric initial pH in [0,14] required"))
        finite_real(init["pe"]) && -20<=init["pe"]<=20 || throw(ArgumentError("invalid pe"))
        init["origin"] in ("Observation","Assumption") || throw(ArgumentError("initial origin must be Observation or Assumption"))
        all(k->init[k] isa AbstractString && !isempty(strip(init[k])),("source","label")) || throw(ArgumentError("initial source/label required"))
        init["charge_context"] in CHARGE_CONTEXTS || throw(ArgumentError("explicit charge_context required"))
        init["charge_context"]=="analytical" && init["origin"]!="Observation" && throw(ArgumentError("analytical diagnostic requires user-declared observations"))
        FluidState(temperature_c=d["temperature_c"],pH=init["pH"],totals=init["totals"],label=init["label"],allow_unvalidated_temperature=get(d,"allow_unvalidated_temperature",false))
        minerals=d["minerals"]
        !isempty(minerals) && length(unique(minerals))==length(minerals) && all(m->m in ("Calcite","Fluorite"),minerals) || throw(ArgumentError("monitor Calcite and/or Fluorite once"))
        reagent=d["titrant"]
        check_keys(reagent,["identity","amounts_mol","addition_model"],"titrant")
        haskey(TITRANT_ATOMS,reagent["identity"]) || throw(ArgumentError("only neutral HCl or NaOH formula additions supported; not H+ alone"))
        reagent["addition_model"]=="formula_addition_no_carrier_water" || throw(ArgumentError("only formula addition without carrier water supported; no silent dilution approximation"))
        amounts=reagent["amounts_mol"]
        1<=length(amounts)<=500 && all(v->finite_real(v)&&0<=v<=0.01,amounts) && sum(amounts)<=0.1 || throw(ArgumentError("1–500 nonnegative incremental mol additions required, each <=0.01 and total <=0.1"))
        diag=d["diagnostics"]
        check_keys(diag,["charge_threshold_percent","mass_absolute_tolerance_mol","mass_relative_tolerance","charge_conservation_tolerance_eq"],"diagnostics")
        for k in ("charge_threshold_percent","mass_absolute_tolerance_mol","mass_relative_tolerance","charge_conservation_tolerance_eq")
            finite_real(diag[k]) && diag[k]>=0 || throw(ArgumentError("finite nonnegative $k required"))
        end
        diag["mass_absolute_tolerance_mol"]>0 && diag["charge_conservation_tolerance_eq"]>0 || throw(ArgumentError("positive absolute accounting tolerances required"))
        new(d)
    end
end
load_process(path::AbstractString)=AcidBaseTitration(TOML.parsefile(path))

function process_input(p::AcidBaseTitration)
    d=p.spec; i=d["initial"]; reagent=d["titrant"]
    lines=["TITLE MineralTrace acid-base formula-addition titration", "SOLUTION 1", "    temp $(Float64(d["temperature_c"]))", "    pressure 1", "    pH $(Float64(i["pH"]))", "    pe $(Float64(i["pe"]))", "    units mol/kgw", "    water $(Float64(i["water_kg"]))"]
    append!(lines,["    $k $(Float64(i["totals"][k]))" for k in sort(COMPONENTS)])
    append!(lines,["INCREMENTAL_REACTIONS true", "REACTION 1", "    $(reagent["identity"]) 1.0", "    "*join(Float64.(reagent["amounts_mol"])," ")*" moles", "SELECTED_OUTPUT 1", "    -file selected.tsv", "    -reset false", "    -high_precision true", "    -state true", "    -step true", "    -pH true", "    -temperature true", "    -water true", "    -charge_balance true", "    -percent_error true", "    -ionic_strength true", "    -totals Ca F C(4) Na Cl", "    -molalities H+ OH- Ca+2 F- HF HCO3- CO3-2 CO2 Na+ Cl- CaCO3 CaHCO3+", "    -saturation_indices "*join(d["minerals"]," "), "USER_PUNCH 1", "    -headings "*join(["n_$e" for e in PROCESS_ELEMENTS]," "), "    -start", "    10 PUNCH "*join(["TOTMOLE(\"$e\")" for e in PROCESS_ELEMENTS],", "), "    -end", "END"])
    join(lines,"\n")*"\n"
end

struct ProcessResult
    process::AcidBaseTitration
    steps::Vector{Dict{String,Any}}
    directory::String
    provenance::Dict{String,Any}
end

"""Independent stoichiometric inventory check; all elements include aqueous water H/O."""
function process_accounting(p::AcidBaseTitration,rows)
    d=p.spec; amounts=Float64.(d["titrant"]["amounts_mol"]);diag=d["diagnostics"]
    length(rows)==length(amounts)+1 || throw(ArgumentError("expected one initial row and exactly one reaction row per addition"))
    rows[1]["state"]=="i_soln" && all(r->r["state"]=="react",rows[2:end]) || throw(ArgumentError("unexpected PHREEQC process states"))
    num(r,k)=parse(Float64,r[k]); initial=rows[1]; cumulative=0.;steps=Dict{String,Any}[]
    for (index,row) in enumerate(rows)
        step=index-1;added=step==0 ? 0. : amounts[step];cumulative+=added
        step==0 || num(row,"step")==step || throw(ArgumentError("PHREEQC step indices do not match declared additions"))
        balances=Dict{String,Any}()
        for e in PROCESS_ELEMENTS
            total_key=e=="C" ? "C(4)" : e
            initial_expected=e in ("H","O") ? num(initial,"n_$e") : Float64(d["initial"]["totals"][total_key])*Float64(d["initial"]["water_kg"])
            predicted=initial_expected+cumulative*get(TITRANT_ATOMS[d["titrant"]["identity"]],e,0)
            actual=num(row,"n_$e");residual=actual-predicted
            tolerance=diag["mass_absolute_tolerance_mol"]+diag["mass_relative_tolerance"]*abs(predicted)
            balances[e]=Dict("initial_basis"=>e in ("H","O") ? "engine initial aqueous inventory including water" : "declared initial mol/kgw times initial kg water","expected_mol"=>predicted,"actual_mol"=>actual,"residual_mol"=>residual,"tolerance_mol"=>tolerance,"pass"=>abs(residual)<=tolerance)
        end
        charge_change=num(row,"charge")-num(initial,"charge") # Both supported formulas are neutral.
        charge=charge_diagnostic(num(row,"pct_err"),num(row,"charge"),num(row,"mass_H2O");threshold_percent=diag["charge_threshold_percent"],context=step==0 ? d["initial"]["charge_context"] : "controlled_process")
        si=Dict{String,Any}()
        for m in d["minerals"]
            v=num(row,"si_$m");isfinite(v) && v> -999 || throw(ArgumentError("undefined $m SI at step $step"));si[m]=v
        end
        push!(steps,Dict{String,Any}("step"=>step,"added_mol"=>added,"cumulative_added_mol"=>cumulative,"pH"=>num(row,"pH"),"si"=>si,"charge_diagnostic"=>charge,
            "charge_change_eq"=>charge_change,"charge_conservation_pass"=>abs(charge_change)<=diag["charge_conservation_tolerance_eq"],"element_balance"=>balances,"mass_balance_pass"=>all(b->b["pass"],values(balances)),"selected"=>row))
    end
    steps
end

function simulate(p::AcidBaseTitration,c::PHREEQCConfig=PHREEQCConfig();root="results")
    env=environment_check(c);mkpath(root);dir=abspath(mktempdir(root;prefix="process-",cleanup=false))
    open(io->TOML.print(io,p.spec;sorted=true),joinpath(dir,"process.toml"),"w")
    input=process_input(p);write(joinpath(dir,"reaction.pqi"),input)
    cp(env.database,joinpath(dir,"database.dat"))
    source_root=dirname(@__DIR__);project=dirname(source_root)
    cp(source_root,joinpath(dir,"src"));cp(joinpath(project,"Project.toml"),joinpath(dir,"Project.toml"));cp(joinpath(project,"Manifest.toml"),joinpath(dir,"Manifest.toml"))
    mkpath(joinpath(dir,"data"));cp(joinpath(project,"data","sources"),joinpath(dir,"data","sources"))
    mkpath(joinpath(dir,"data","validation"))
    for f in ("SCIENTIFIC_VALIDATION.md","CHARGE_BALANCE_SEMANTICS.md","EXPERIMENTAL_CASE_V040.md","experimental-case-v040.json")
        path=joinpath(project,"data","validation",f);isfile(path) && cp(path,joinpath(dir,"data","validation",f))
    end
    # Scan can also run from this archived package without losing its sources/validation structure.
    write(joinpath(dir,"reproduce.jl"),"using MineralTrace\np=load_process(joinpath(@__DIR__,\"process.toml\"))\nc=PHREEQCConfig(database=joinpath(@__DIR__,\"database.dat\"),timeout_seconds=$(c.timeout_seconds))\nr=simulate(p,c;root=joinpath(@__DIR__,\"reproduced\"))\nprintln(report(r))\n")
    provenance=Dict{String,Any}("status"=>"started","timestamp_utc"=>string(now(UTC)),"package_version"=>string(pkgversion(@__MODULE__)),"julia_version"=>string(VERSION),"database_sha256"=>env.database_sha256,"database_name"=>basename(env.database),"executable"=>env.executable,"executable_sha256"=>bytes2hex(sha256(read(env.executable))),"input_sha256"=>bytes2hex(sha256(codeunits(input))),"random_seed"=>"not applicable","source_id"=>p.spec["initial"]["source"],"validation_levels"=>["engine: direct CLI comparison tested in project suite, not automatically repeated for every run","chemistry: conservation audited for this run","experiment: not completed; registered data gaps"],"warnings"=>["Aqueous activity/species/temperature applicability remains unverified.","Monitored SI does not simulate mineral precipitation or geological chronology.","No independent experimental titration comparison completed."])
    save()=open(io->TOML.print(io,provenance;sorted=true),joinpath(dir,"provenance.toml"),"w");save()
    try
        frozen=PHREEQCConfig(executable=env.executable,database=joinpath(dir,"database.dat"),timeout_seconds=c.timeout_seconds)
        required=vcat(["pH","charge","pct_err","mass_H2O"],["n_$e" for e in PROCESS_ELEMENTS],["si_$m" for m in p.spec["minerals"]])
        result=run_phreeqc(frozen,input;root=dir,required,sources=[p.spec["initial"]["source"]],metadata=Dict("process"=>"acid_base_titration","addition_model"=>p.spec["titrant"]["addition_model"]))
        steps=process_accounting(p,result.rows)
        inventories=process_species_audits(joinpath(result.directory,"output.pqo"))
        length(inventories)==length(steps) || error("raw species table count does not match process steps")
        for (step,inventory) in zip(steps,inventories)
            step["rounded_charge_inventory"]=inventory
        end
        provenance["engine_banner"]=result.manifest["engine_banner"];provenance["raw_archive"]=relpath(result.directory,dir);provenance["engine_warnings"]=result.manifest["warnings"]
        provenance["source_sha256"]=Dict(relpath(joinpath(folder,f),dir)=>bytes2hex(sha256(read(joinpath(folder,f)))) for (folder,_,files) in walkdir(joinpath(dir,"src")) for f in files)
        provenance["process_sha256"]=bytes2hex(sha256(read(joinpath(dir,"process.toml"))))
        provenance["evidence_sha256"]=Dict(relpath(joinpath(folder,f),dir)=>bytes2hex(sha256(read(joinpath(folder,f)))) for (folder,_,files) in walkdir(joinpath(dir,"data")) for f in files)
        provenance["status"]=all(s->s["mass_balance_pass"]&&s["charge_conservation_pass"],steps) ? "completed" : "completed_with_accounting_failures"
        save();ProcessResult(p,steps,dir,provenance)
    catch e
        provenance["status"]="failed";provenance["error"]=sprint(showerror,e)
        e isa CalculationError && (provenance["raw_archive"]=relpath(e.directory,dir))
        save()
        e isa InterruptException && rethrow()
        e isa CalculationError && rethrow()
        throw(CalculationError(sprint(showerror,e),dir))
    end
end


"""Every rounded raw species table; an independent equivalent sum, not a second activity model."""
function process_species_audits(path)
    inventories=Dict{String,Any}[]
    for part in eachmatch(r"(?s)Distribution of species(.*?)Saturation indices",read(path,String))
        amounts=Dict{String,Float64}()
        for line in split(part[1],'\n')
            f=split(line);length(f)>=6 || continue
            occursin(r"^[A-Za-z]",f[1]) || continue
            n=tryparse(Float64,f[2]);a=tryparse(Float64,f[3]);lg=tryparse(Float64,f[4])
            if n!==nothing && a!==nothing && lg!==nothing
                amounts[String(f[1])]=n
            end
        end
        isempty(amounts) && error("empty raw aqueous species inventory")
        charges=Dict(k=>species_charge(k) for k in keys(amounts))
        audit=charge_equivalents(amounts,charges)
        audit["precision"]="rounded raw output; not the high-precision conservation decision"
        audit["species"]=[Dict("name"=>k,"molality_mol_per_kgw"=>amounts[k],"charge"=>charges[k],"signed_eq_per_kgw"=>amounts[k]*charges[k]) for k in sort(collect(keys(amounts)))]
        push!(inventories,audit)
    end
    inventories
end
