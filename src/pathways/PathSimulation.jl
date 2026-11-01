struct PathComparison
    study::PathStudy
    candidates::Vector{Dict{String,Any}}
    directory::String
    provenance::Dict{String,Any}
end

function path_account(s::PathStudy,row,initial_row,stocks,initial_stocks,added_atoms)
    d=s.spec;diag=d["diagnostics"];balances=Dict{String,Any}()
    for e in PROCESS_ELEMENTS
        key=e=="C" ? "C(4)" : e
        aqueous_initial=e in ("H","O") ? parse(Float64,initial_row["n_$e"]) : d["initial"]["totals"][key]*d["initial"]["water_kg"]
        initial_solid=sum((get(SOLID_ATOMS[m],e,0)*mol for (m,mol) in initial_stocks);init=0.)
        current_solid=sum((get(SOLID_ATOMS[m],e,0)*mol for (m,mol) in stocks);init=0.)
        expected=aqueous_initial+initial_solid+get(added_atoms,e,0.)
        aqueous=parse(Float64,row["n_$e"]);actual=aqueous+current_solid;residual=actual-expected
        tolerance=diag["mass_absolute_tolerance_mol"]+diag["mass_relative_tolerance"]*abs(expected)
        balances[e]=Dict("aqueous_mol"=>aqueous,"solid_mol"=>current_solid,"expected_total_mol"=>expected,"residual_mol"=>residual,"tolerance_mol"=>tolerance,"pass"=>abs(residual)<=tolerance)
    end
    delta_charge=parse(Float64,row["charge"])-parse(Float64,initial_row["charge"])
    Dict("elements"=>balances,"mass_pass"=>all(b->b["pass"],values(balances)),"charge_change_eq"=>delta_charge,"charge_pass"=>abs(delta_charge)<=diag["charge_conservation_tolerance_eq"])
end

function run_candidate(s::PathStudy,definition,c::PHREEQCConfig,root)
    d=s.spec;stocks=Dict(p["mineral"]=>Float64(p["initial_mol"]) for p in d["phases"]);initial_stocks=copy(stocks)
    added_atoms=Dict{String,Float64}();steps=Dict{String,Any}[];previous_dump=nothing;initial_row=nothing
    candidate=Dict{String,Any}("id"=>definition["id"],"source_id"=>definition["source_id"],"steps"=>steps,"computational_status"=>"started","error"=>"")
    operations=vcat([Dict{String,Any}("id"=>"initial","kind"=>"initial","active_phases"=>String[])],definition["operations"])
    for (index,op) in enumerate(operations)
        input=index==1 ? path_initial_input(s) : path_operation_input(s,op,stocks)
        aux=index==1 ? Dict{String,String}() : Dict("previous.dmp"=>previous_dump)
        last_archive=nothing
        try
            result=run_phreeqc(c,input;root,auxiliary_files=aux,required=vcat(["pH","temp","mass_H2O","charge","pct_err"],["n_$e" for e in PROCESS_ELEMENTS]),sources=[definition["source_id"]],metadata=Dict("candidate"=>definition["id"],"operation"=>op["id"],"active_phases"=>op["active_phases"]))
            last_archive=result.directory
            length(result.rows)==1 || error("expected exactly one saved-state calculation per operation")
            row=only(result.rows);index==1 && (initial_row=row)
            index==1 ? row["state"]=="i_soln" || error("unexpected initial state") : row["state"]=="react" || error("expected a batch-reaction state")
            dump=joinpath(result.directory,"state.dmp");isfile(dump) && filesize(dump)>0 || error("engine solution-state dump missing")
            previous_dump=dump
            transfers=Dict{String,Any}();directions_ok=true
            for phase in d["phases"]
                m=phase["mineral"];before=stocks[m]
                after=m in op["active_phases"] ? parse(Float64,row["solid_$m"]) : before
                isfinite(after) || error("nonfinite phase inventory")
                change=after-before;tol=d["diagnostics"]["mass_absolute_tolerance_mol"]
                permitted=after>=-tol && (phase["direction"]=="bidirectional" || phase["direction"]=="precipitation_only" && change>=-tol || phase["direction"]=="dissolution_only" && change<=tol)
                directions_ok &= permitted;stocks[m]=after
                transfers[m]=Dict("initial_for_step_mol"=>before,"remaining_mol"=>after,"solid_gain_mol"=>change,"aqueous_transfer_formula_mol"=>-change,"active"=>m in op["active_phases"],"direction"=>phase["direction"],"direction_pass"=>permitted)
            end
            if op["kind"] in ("HCl","NaOH")
                for (e,n) in TITRANT_ATOMS[op["kind"]]
                    added_atoms[e]=get(added_atoms,e,0.)+op["amount_mol"]*n
                end
            end
            si=Dict{String,Any}()
            for m in d["minerals"]
                v=tryparse(Float64,row["si_$m"])
                si[m]=v===nothing || !isfinite(v) || v<=-999 ? nothing : v
            end
            account=path_account(s,row,initial_row,stocks,initial_stocks,added_atoms)
            charge=charge_diagnostic(parse(Float64,row["pct_err"]),parse(Float64,row["charge"]),parse(Float64,row["mass_H2O"]);threshold_percent=d["diagnostics"]["charge_threshold_percent"],context=index==1 ? d["initial"]["charge_context"] : "controlled_process")
            push!(steps,Dict{String,Any}("index"=>index-1,"operation_id"=>op["id"],"kind"=>op["kind"],"active_phases"=>op["active_phases"],"temperature_c"=>parse(Float64,row["temp"]),"pH"=>parse(Float64,row["pH"]),"si"=>si,"phase_transfers"=>transfers,"accounting"=>account,"direction_pass"=>directions_ok,"charge_diagnostic"=>charge,"selected"=>row,"archive"=>relpath(result.directory,root),"input_sha256"=>result.manifest["input_sha256"],"state_sha256"=>bytes2hex(sha256(read(dump)))))
            # Conservation and direction permissions are hard constraints: never continue a broken path.
            if !account["mass_pass"] || !account["charge_pass"] || !directions_ok
                candidate["computational_status"]="hard_constraint_failure";return candidate
            end
        catch e
            e isa InterruptException && rethrow()
            candidate["computational_status"]="failed";candidate["error"]=sprint(showerror,e)
            archive=e isa CalculationError ? e.directory : last_archive
            archive!==nothing && (candidate["failed_archive"]=relpath(archive,root))
            candidate["failed_operation"]=op["id"];return candidate
        end
    end
    candidate["computational_status"]="success";candidate
end

function compare_evidence(s::PathStudy,definition,candidate)
    checks=Dict{String,Any}[];positions=Dict{String,Int}();unknown=isempty(s.spec["events"]);contradiction=false
    if candidate["computational_status"]!="success"
        hard=candidate["computational_status"]=="hard_constraint_failure"
        return Dict("classification"=>hard ? "incompatible" : "undetermined","qualification"=>"No geological history confirmed","checks"=>[Dict("constraint"=>"hard chemical/process constraints","result"=>candidate["computational_status"],"detail"=>get(candidate,"error",""))],"model_applicability"=>"unverified","observed_formation_confirmed_by_model"=>false)
    end
    isempty(s.spec["events"]) && push!(checks,Dict("constraint"=>"independent observations","result"=>"undetermined","detail"=>"No independent event evidence supplied"))
    for event in s.spec["events"]
        bindings=filter(b->b["event_id"]==event["id"],definition["bindings"])
        source=get(event,"source_id",nothing)
        sourced=source isa AbstractString && !isempty(strip(source))
        if isempty(bindings)
            push!(checks,Dict("constraint"=>event["id"],"result"=>"undetermined","detail"=>"No user correspondence between this observed event and a modeled operation"));unknown=true;continue
        end
        b=only(bindings);step=only(p for p in candidate["steps"] if p["operation_id"]==b["operation_id"]);m=event["mineral"]
        if b["level"]=="saturation_opportunity"
            value=step["si"][m];matches=value!==nothing && value>b["minimum_si"]
            result=value===nothing ? "undetermined" : matches ? "opportunity_only" : "mismatch"
            unknown=true # Opportunity never establishes a formation event, even if chronological indices fit.
        else
            transfer=get(step["phase_transfers"],m,nothing)
            value=transfer===nothing ? nothing : transfer["solid_gain_mol"]*(b["level"]=="equilibrium_precipitation" ? 1 : -1)
            matches=value!==nothing && value>=b["minimum_mol"]
            result=value===nothing ? "undetermined" : matches ? "modeled_equilibrium_match" : "mismatch"
            value===nothing ? (unknown=true) : !matches && (contradiction=true)
        end
        sourced && event["classification"]=="Observation" || (unknown=true)
        event["classification"]!="Observation" && push!(checks,Dict("constraint"=>event["id"],"result"=>"undetermined","detail"=>"Event is a user assumption, not an independently supplied observation"))
        matches && (positions[event["id"]]=step["index"])
        push!(checks,Dict("constraint"=>event["id"],"level"=>b["level"],"operation_id"=>b["operation_id"],"result"=>result,"value"=>value,"source_id"=>source,"source_status"=>sourced ? "documented_user_evidence" : "missing","detail"=>"User correspondence tested; modeled reaction is not independent observed formation"))
    end
    for edge in s.graph.evidence
        if !haskey(positions,edge.earlier) || !haskey(positions,edge.later)
            result="undetermined";unknown=true;detail="At least one event lacks a matching modeled correspondence"
        elseif positions[edge.earlier]>positions[edge.later]
            result="contradiction";contradiction=true;detail="Explicit modeled event assignments reverse this independent temporal constraint"
        elseif positions[edge.earlier]==positions[edge.later]
            result="undetermined";unknown=true;detail="One batch-equilibrium operation cannot resolve internal crystallization chronology"
        else
            result="order_compatible";detail="User assignments preserve the supplied relative order; no elapsed time inferred"
        end
        push!(checks,Dict("constraint"=>"$(edge.earlier) → $(edge.later)","result"=>result,"source_id"=>edge.source,"detail"=>detail))
    end
    quality=all(p->p["charge_diagnostic"]["diagnostic_status"]=="within_declared_threshold",candidate["steps"])
    !quality && (unknown=true;push!(checks,Dict("constraint"=>"charge diagnostic policy","result"=>"requires_review","detail"=>"Threshold exceedance is not proof of physical impossibility")))
    s.spec["evaluation_mode"]=="strict" && (unknown=true;push!(checks,Dict("constraint"=>"model applicability gate","result"=>"unverified","detail"=>"No full validated Ca-F-C profile available")))
    Dict("classification"=>contradiction ? "incompatible" : unknown ? "undetermined" : "compatible","qualification"=>"Conditional on specified fluids, phase permissions, equilibrium model and user event correspondences; not confirmed geological history","checks"=>checks,"model_applicability"=>"unverified","observed_formation_confirmed_by_model"=>false)
end

function compare_paths(s::PathStudy,c::PHREEQCConfig=PHREEQCConfig();root="results")
    env=environment_check(c)
    dbtext=read(env.database,String)
    all(m->occursin(Regex("(?m)^"*m*"\\s*\$"),dbtext),s.spec["minerals"]) || throw(DependencyError("Requested mineral phase missing from database"))
    mkpath(root);dir=abspath(mktempdir(root;prefix="paths-",cleanup=false))
    open(io->TOML.print(io,s.spec;sorted=true),joinpath(dir,"paths.toml"),"w");cp(env.database,joinpath(dir,"database.dat"))
    project=dirname(dirname(@__DIR__));cp(joinpath(project,"src"),joinpath(dir,"src"));cp(joinpath(project,"Project.toml"),joinpath(dir,"Project.toml"));cp(joinpath(project,"Manifest.toml"),joinpath(dir,"Manifest.toml"));cp(joinpath(project,"data"),joinpath(dir,"data"))
    write(joinpath(dir,"reproduce.jl"),"using MineralTrace\ns=load_paths(joinpath(@__DIR__,\"paths.toml\"))\nc=PHREEQCConfig(database=joinpath(@__DIR__,\"database.dat\"),timeout_seconds=$(c.timeout_seconds))\nr=compare_paths(s,c;root=joinpath(@__DIR__,\"reproduced\"))\nprintln(report(r))\n")
    frozen=PHREEQCConfig(executable=env.executable,database=joinpath(dir,"database.dat"),timeout_seconds=c.timeout_seconds)
    candidates=Dict{String,Any}[]
    for definition in s.spec["paths"]
        candidate=run_candidate(s,definition,frozen,dir);candidate["compatibility"]=compare_evidence(s,definition,candidate);push!(candidates,candidate)
    end
    provenance=Dict{String,Any}("timestamp_utc"=>string(now(UTC)),"julia_version"=>string(VERSION),"package_version"=>string(pkgversion(@__MODULE__)),"database_sha256"=>env.database_sha256,"executable"=>env.executable,"executable_sha256"=>bytes2hex(sha256(read(env.executable))),"config_sha256"=>bytes2hex(sha256(read(joinpath(dir,"paths.toml")))),"random_seed"=>"not applicable","model_applicability"=>"unverified","sign_convention"=>"positive solid_gain_mol means precipitation; negative means dissolution; aqueous formula transfer is its negative","source_sha256"=>Dict(relpath(joinpath(folder,f),dir)=>bytes2hex(sha256(read(joinpath(folder,f)))) for (folder,_,files) in walkdir(joinpath(dir,"src")) for f in files))
    provenance["evidence_sha256"]=Dict(relpath(joinpath(folder,f),dir)=>bytes2hex(sha256(read(joinpath(folder,f)))) for (folder,_,files) in walkdir(joinpath(dir,"data")) for f in files)
    provenance["engine_banners"]=unique([TOML.parsefile(joinpath(dir,p["archive"],"manifest.toml"))["engine_banner"] for candidate in candidates for p in candidate["steps"]])
    open(io->TOML.print(io,provenance;sorted=true),joinpath(dir,"provenance.toml"),"w")
    PathComparison(s,candidates,dir,provenance)
end
