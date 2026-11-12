const SOLID_ATOMS=Dict("Calcite"=>Dict("Ca"=>1,"C"=>1,"O"=>3),"Fluorite"=>Dict("Ca"=>1,"F"=>2))
const PHASE_DIRECTIONS=Dict("bidirectional"=>"", "precipitation_only"=>"precipitate_only", "dissolution_only"=>"dissolve_only")

struct PathStudy
    spec::Dict{String,Any}
    graph::EvidenceGraph
    function PathStudy(spec::AbstractDict)
        d=deepcopy(Dict{String,Any}(spec))
        check_keys(d,["title","boundary","initial_temperature_c","allow_unvalidated_temperature","initial","minerals","phases","diagnostics","evaluation_mode","events","evidence","paths"],"path study")
        d["title"] isa AbstractString && !isempty(strip(d["title"])) || throw(ArgumentError("study title required"))
        d["boundary"]=="closed_aqueous_and_retained_solids_no_gas" || throw(ArgumentError("only explicit closed aqueous+retained solid boundary supported"))
        d["evaluation_mode"] in ("strict","exploratory") || throw(ArgumentError("explicit strict/exploratory mode required"))
        # Reuse the validated initial-fluid and diagnostic schema, without adding any actual reagent.
        prototype=Dict("process"=>"acid_base_titration","temperature_c"=>d["initial_temperature_c"],"pressure_atm"=>1.,"allow_unvalidated_temperature"=>d["allow_unvalidated_temperature"],"minerals"=>d["minerals"],"initial"=>d["initial"],"diagnostics"=>d["diagnostics"],"titrant"=>Dict("identity"=>"HCl","amounts_mol"=>[0.],"addition_model"=>"formula_addition_no_carrier_water"))
        AcidBaseTitration(prototype)
        names=String[]
        for p in d["phases"]
            check_keys(p,["mineral","initial_mol","direction","target_si","source_id"],"phase")
            p["mineral"] in d["minerals"] && haskey(SOLID_ATOMS,p["mineral"]) || throw(ArgumentError("phase must be a monitored Calcite/Fluorite"))
            finite_real(p["initial_mol"]) && p["initial_mol"]>=0 || throw(ArgumentError("explicit nonnegative initial phase inventory required"))
            haskey(PHASE_DIRECTIONS,p["direction"]) || throw(ArgumentError("unknown phase direction"))
            finite_real(p["target_si"]) && abs(p["target_si"])<=10 || throw(ArgumentError("invalid explicit target SI"))
            !isempty(strip(p["source_id"])) || throw(ArgumentError("phase inventory/assumption source required"))
            push!(names,p["mineral"])
        end
        length(unique(names))==length(names) || throw(ArgumentError("duplicate phase inventory"))
        events=FormationEvent[]
        for e in d["events"]
            check_keys(e,["id","mineral","event_kind","source_id","classification","description"],"event")
            e["classification"] in ("Observation","Assumption") || throw(ArgumentError("event classification required"))
            e["event_kind"] in ("formation","dissolution") || throw(ArgumentError("explicit event_kind formation/dissolution required"))
            push!(events,FormationEvent(e["id"],e["mineral"];description=get(e,"description","")))
        end
        edges=Evidence[]
        for e in d["evidence"]
            check_keys(e,["earlier","later","kind","source_id","reliability","interpretation"],"temporal evidence")
            push!(edges,Evidence(e["earlier"],e["later"],Symbol(e["kind"]);source=e["source_id"],reliability=e["reliability"],interpretation=e["interpretation"]))
        end
        graph=EvidenceGraph(events,edges);analyze(graph) # Never delete a conflicting edge.
        ids=String[]
        for path in d["paths"]
            check_keys(path,["id","source_id","operations","bindings"],"candidate path")
            !isempty(strip(path["id"])) && !isempty(strip(path["source_id"])) || throw(ArgumentError("candidate ID and source required"))
            push!(ids,path["id"])
            1<=length(path["operations"])<=100 || throw(ArgumentError("1–100 explicit path operations required"))
            opids=String[]
            for op in path["operations"]
                kind=op["kind"];kind in ("temperature","HCl","NaOH","equilibrium") || throw(ArgumentError("unsupported path operation"))
                extra=kind=="temperature" ? ["temperature_c"] : kind in ("HCl","NaOH") ? ["amount_mol","addition_model"] : String[]
                check_keys(op,vcat(["id","kind","active_phases","source_id"],extra),"operation")
                !isempty(strip(op["id"])) && !isempty(strip(op["source_id"])) || throw(ArgumentError("operation ID/source required"))
                push!(opids,op["id"])
                length(unique(op["active_phases"]))==length(op["active_phases"]) && all(m->m in names,op["active_phases"]) || throw(ArgumentError("active phases must be explicitly inventoried, without duplicates"))
                if kind=="temperature"
                    valid_value("temperature",op["temperature_c"])
                    op["temperature_c"]!=25 && !d["allow_unvalidated_temperature"] && throw(ArgumentError("temperature path requires explicit exploratory opt-in"))
                elseif kind in ("HCl","NaOH")
                    finite_real(op["amount_mol"]) && 0<=op["amount_mol"]<=0.01 || throw(ArgumentError("nonnegative addition <=0.01 mol required"))
                    op["addition_model"]=="formula_addition_no_carrier_water" || throw(ArgumentError("carrier-water model not supported"))
                end
            end
            length(unique(opids))==length(opids) || throw(ArgumentError("duplicate operation ID"))
            bound=String[]
            for b in path["bindings"]
                level=b["level"];level in ("equilibrium_precipitation","equilibrium_dissolution","saturation_opportunity") || throw(ArgumentError("unknown modeled event level"))
                extra=level=="saturation_opportunity" ? ["minimum_si"] : ["minimum_mol"]
                check_keys(b,vcat(["event_id","operation_id","level"],extra),"event binding")
                b["event_id"] in [e.id for e in events] && b["operation_id"] in opids || throw(ArgumentError("binding references unknown event or operation"))
                event=only(e for e in events if e.id==b["event_id"])
                event.mineral in d["minerals"] || throw(ArgumentError("unmodeled mineral cannot be bound to a modeled reaction"))
                level!="saturation_opportunity" && !(event.mineral in names) && throw(ArgumentError("reaction binding requires explicit mineral inventory"))
                expected_kind=level=="equilibrium_dissolution" ? "dissolution" : "formation"
                only(e for e in d["events"] if e["id"]==b["event_id"])["event_kind"]==expected_kind || throw(ArgumentError("dissolution cannot stand in for an observed formation event"))
                threshold=b[only(extra)];finite_real(threshold) && threshold>=0 || throw(ArgumentError("finite nonnegative detection threshold required"))
                level!="saturation_opportunity" && threshold<=d["diagnostics"]["mass_absolute_tolerance_mol"] && throw(ArgumentError("reaction detection threshold must exceed absolute numerical mass tolerance"))
                push!(bound,b["event_id"])
            end
            length(unique(bound))==length(bound) || throw(ArgumentError("one explicit correspondence per observed event per candidate"))
        end
        !isempty(ids) && length(unique(ids))==length(ids) || throw(ArgumentError("nonempty unique candidate paths required"))
        new(d,graph)
    end
end
load_paths(path::AbstractString)=PathStudy(TOML.parsefile(path))

function path_selection(minerals)
    ["SELECTED_OUTPUT 1"," -file selected.tsv"," -reset false"," -high_precision true"," -state true"," -pH true"," -temperature true"," -water true"," -charge_balance true"," -percent_error true"," -totals Ca F C(4) Na Cl"," -molalities Ca+2 F- HCO3- CO3-2 CO2"," -saturation_indices "*join(minerals," "),"USER_PUNCH 1"," -headings "*join(vcat(["n_$e" for e in PROCESS_ELEMENTS],["solid_$m" for m in minerals],["pressure_atm","ionic_strength"])," ")," -start"," 10 PUNCH "*join(vcat(["TOTMOLE(\"$e\")" for e in PROCESS_ELEMENTS],["EQUI(\"$m\")" for m in minerals],["PRESSURE","MU"]),", ")," -end"]
end

function path_initial_input(s::PathStudy)
    d=s.spec;i=d["initial"]
    lines=["SOLUTION 1"," temp $(Float64(d["initial_temperature_c"]))"," pressure 1"," pH $(Float64(i["pH"]))"," pe $(Float64(i["pe"]))"," units mol/kgw"," water $(Float64(i["water_kg"]))"]
    append!(lines,[" $k $(Float64(i["totals"][k]))" for k in sort(COMPONENTS)])
    append!(lines,path_selection(d["minerals"]));append!(lines,["SAVE solution 1","DUMP"," -file state.dmp"," -solution 1","END"])
    join(lines,"\n")*"\n"
end

function path_operation_input(s::PathStudy,op,stocks)
    lines=["INCLUDE\$ previous.dmp","USE solution 1"]
    if isempty(op["active_phases"])
        push!(lines,"USE equilibrium_phases none")
    else
        push!(lines,"EQUILIBRIUM_PHASES 1")
        for m in op["active_phases"]
            p=only(p for p in s.spec["phases"] if p["mineral"]==m)
            push!(lines," $m $(Float64(p["target_si"])) $(stocks[m]) $(PHASE_DIRECTIONS[p["direction"]])")
        end
    end
    if op["kind"]=="temperature"
        append!(lines,["REACTION_TEMPERATURE 1"," $(Float64(op["temperature_c"]))"])
    end
    # Zero-mole neutral addition triggers a batch reaction without altering composition.
    reagent=op["kind"] in ("HCl","NaOH") ? op["kind"] : "HCl"
    amount=op["kind"] in ("HCl","NaOH") ? Float64(op["amount_mol"]) : 0.
    append!(lines,["REACTION 1"," $reagent 1"," $amount moles"])
    append!(lines,path_selection(s.spec["minerals"]));append!(lines,["SAVE solution 1","DUMP"," -file state.dmp"," -solution 1","END"])
    join(lines,"\n")*"\n"
end
