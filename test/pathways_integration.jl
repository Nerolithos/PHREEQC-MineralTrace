@testset "Reactive candidate workflow and state continuity" begin
    c=PHREEQCConfig();root=joinpath(@__DIR__,"../results");s=load_paths(joinpath(@__DIR__,"../examples/reactive_paths.toml"));r=compare_paths(s,c;root)
    @test [p["compatibility"]["classification"] for p in r.candidates]==["compatible","incompatible"]
    @test all(p->p["computational_status"]=="success",r.candidates)
    for candidate in r.candidates
        @test [p["temperature_c"] for p in candidate["steps"]]==[80.,60.,60.,40.,40.]
        @test all(p->p["accounting"]["mass_pass"]&&p["accounting"]["charge_pass"]&&p["direction_pass"],candidate["steps"])
        for i in 2:length(candidate["steps"])
            step=candidate["steps"][i];prev=candidate["steps"][i-1]
            manifest=TOML.parsefile(joinpath(r.directory,step["archive"],"manifest.toml"))
            @test manifest["auxiliary_sha256"]["previous.dmp"]==prev["state_sha256"]
        end
    end
    forward=r.candidates[1];definition=s.spec["paths"][1]
    @test forward["steps"][3]["phase_transfers"]["Fluorite"]["solid_gain_mol"]>1e-8
    @test forward["steps"][5]["phase_transfers"]["Calcite"]["solid_gain_mol"]>1e-8
    @test forward["steps"][4]["phase_transfers"]["Fluorite"]["remaining_mol"]==forward["steps"][3]["phase_transfers"]["Fluorite"]["remaining_mol"]
    @test !forward["steps"][4]["phase_transfers"]["Fluorite"]["active"]
    # Opportunity-only correspondences can never establish a formation chronology.
    weak=deepcopy(definition)
    for b in weak["bindings"];b["operation_id"]="cool60";b["level"]="saturation_opportunity";delete!(b,"minimum_mol");b["minimum_si"]=0.;end
    weak_result=MineralTrace.compare_evidence(s,weak,forward)
    @test weak_result["classification"]=="undetermined"
    @test count(q->q["result"]=="opportunity_only",weak_result["checks"])==2
    @test length(s.graph.evidence)==1
    strict=deepcopy(s.spec);strict["evaluation_mode"]="strict"
    @test MineralTrace.compare_evidence(PathStudy(strict),definition,forward)["classification"]=="undetermined"
    missing=deepcopy(s.spec);delete!(missing["events"][1],"source_id")
    @test MineralTrace.compare_evidence(PathStudy(missing),definition,forward)["classification"]=="undetermined"
    extra=deepcopy(s.spec);push!(extra["events"],Dict("id"=>"Q-I","mineral"=>"Quartz","event_kind"=>"formation","classification"=>"Observation","source_id"=>"SYNTHETIC unknown-model event"))
    @test MineralTrace.compare_evidence(PathStudy(extra),definition,forward)["classification"]=="undetermined"
    hard=deepcopy(forward);hard["computational_status"]="hard_constraint_failure"
    @test MineralTrace.compare_evidence(s,definition,hard)["classification"]=="incompatible"
    @test !forward["compatibility"]["observed_formation_confirmed_by_model"]
    @test_throws ArgumentError run_phreeqc(c,MineralTrace.path_initial_input(s);root,auxiliary_files=Dict("../bad.dmp"=>c.database))
    last=forward["steps"][end];badrow=deepcopy(last["selected"]);badrow["n_Ca"]=string(parse(Float64,badrow["n_Ca"])+0.001)
    currentstocks=Dict(m=>p["remaining_mol"] for (m,p) in last["phase_transfers"]);initialstocks=Dict(p["mineral"]=>p["initial_mol"] for p in s.spec["phases"])
    @test !MineralTrace.path_account(s,badrow,forward["steps"][1]["selected"],currentstocks,initialstocks,Dict())["mass_pass"]
    @test any(q->q["result"]=="contradiction",r.candidates[2]["compatibility"]["checks"])
    # Direct CLI replays the exact operations with its own state dumps, independently of the adapter parser.
    previous=nothing;maxdelta=0.
    for step in forward["steps"]
        dir=abspath(mktempdir(root;prefix="path-direct-",cleanup=false))
        cp(joinpath(r.directory,step["archive"],"input.pqi"),joinpath(dir,"input.pqi"));cp(c.database,joinpath(dir,"database.dat"))
        previous!==nothing && cp(previous,joinpath(dir,"previous.dmp"))
        open(joinpath(dir,"console.log"),"w") do io
            run(pipeline(Cmd(Cmd([environment_check(c).executable,"input.pqi","output.pqo","database.dat"]);dir);stdin=devnull,stdout=io,stderr=io))
        end
        lines=filter(x->!isempty(strip(x)),readlines(joinpath(dir,"selected.tsv")));headers=split(lines[1]);values=split(only(lines[2:end]));row=Dict(zip(headers,values))
        for key in ["pH","temp","n_Ca","n_F","n_C","solid_Fluorite","solid_Calcite"]
            maxdelta=max(maxdelta,abs(parse(Float64,row[key])-parse(Float64,step["selected"][key])))
        end
        previous=joinpath(dir,"state.dmp")
    end
    @test maxdelta<1e-10
    write(joinpath(@__DIR__,"../data/validation/PATH_ENGINE_COMPARISON.md"),"# Direct engine pathway comparison\n\nAll five states of the first candidate were independently executed through the PHREEQC CLI with the direct run's own previous-state dump. Maximum absolute difference over pH, temperature, aqueous Ca/F/C moles and both phase stocks: $maxdelta. This is engine consistency, not experimental validation.\n\nWorkspace: $(r.directory). Database hash: $(r.provenance["database_sha256"]).\n")
    @test report(r) isa String
    for file in ("analysis.json","steps.csv","balances.csv","evidence.svg","candidate-1-solid_gain.svg","reproduce.jl")
        @test isfile(joinpath(r.directory,file))
    end
end

@testset "Finite phase stock and permitted reaction directions" begin
    c=PHREEQCConfig();root=joinpath(@__DIR__,"../results")
    function phase_study(mineral,direction,stock; supersaturated=false)
        d=TOML.parsefile(joinpath(@__DIR__,"../examples/reactive_paths.toml"));d["initial_temperature_c"]=25.;d["allow_unvalidated_temperature"]=false;d["minerals"]=[mineral]
        d["events"]=Any[];d["evidence"]=Any[]
        d["initial"]["pH"]=supersaturated ? 8. : 7.
        d["initial"]["totals"]=Dict("Ca"=>supersaturated ? 0.01 : 0.,"F"=>supersaturated ? 0.002 : 0.,"C(4)"=>supersaturated ? 0.001 : 0.,"Na"=>0.,"Cl"=>0.)
        d["phases"]=[Dict("mineral"=>mineral,"initial_mol"=>stock,"direction"=>direction,"target_si"=>0.,"source_id"=>"SYNTHETIC stock fixture")]
        d["paths"]=[Dict("id"=>"phase_test","source_id"=>"SYNTHETIC process fixture","operations"=>[Dict("id"=>"equilibrate","kind"=>"equilibrium","active_phases"=>[mineral],"source_id"=>"SYNTHETIC contact")],"bindings"=>Any[])]
        PathStudy(d)
    end
    for mineral in ("Calcite","Fluorite")
        dissolution=compare_paths(phase_study(mineral,"dissolution_only",0.01),c;root).candidates[1]
        @test dissolution["computational_status"]=="success"
        final=dissolution["steps"][end]
        @test final["phase_transfers"][mineral]["solid_gain_mol"]<0
        @test final["accounting"]["mass_pass"] && final["accounting"]["charge_pass"]
        @test dissolution["steps"][1]["si"][mineral]===nothing # Undefined activity product is not silently SI=0.
        precipitation=compare_paths(phase_study(mineral,"precipitation_only",0.;supersaturated=true),c;root).candidates[1]
        @test precipitation["steps"][end]["phase_transfers"][mineral]["solid_gain_mol"]>0
        blocked=compare_paths(phase_study(mineral,"dissolution_only",0.;supersaturated=true),c;root).candidates[1]
        @test abs(blocked["steps"][end]["phase_transfers"][mineral]["solid_gain_mol"])<1e-10
        bidirectional=compare_paths(phase_study(mineral,"bidirectional",0.01),c;root).candidates[1]
        @test bidirectional["steps"][end]["phase_transfers"][mineral]["solid_gain_mol"]<0
    end
    protected=compare_paths(phase_study("Calcite","precipitation_only",0.01),c;root).candidates[1]
    @test protected["computational_status"]=="success"
    @test abs(protected["steps"][end]["phase_transfers"]["Calcite"]["solid_gain_mol"])<1e-10
    depleted=compare_paths(phase_study("Calcite","dissolution_only",1e-8),c;root).candidates[1]
    @test depleted["steps"][end]["phase_transfers"]["Calcite"]["remaining_mol"]<1e-10
    @test depleted["steps"][end]["si"]["Calcite"]<0
    simultaneous=TOML.parsefile(joinpath(@__DIR__,"../examples/reactive_paths.toml"))
    simultaneous["paths"]=simultaneous["paths"][1:1]
    simultaneous["paths"][1]["operations"]=[Dict("id"=>"both","kind"=>"equilibrium","active_phases"=>["Fluorite","Calcite"],"source_id"=>"SYNTHETIC simultaneous contact")]
    for b in simultaneous["paths"][1]["bindings"];b["operation_id"]="both";end
    tied=compare_paths(PathStudy(simultaneous),c;root).candidates[1]
    @test tied["compatibility"]["classification"]=="undetermined"
    @test all(p->p["solid_gain_mol"]>1e-8,values(tied["steps"][end]["phase_transfers"]))
    # Reversible cooling and reagent operations preserve the solution instead of reconstructing it.
    d=deepcopy(phase_study("Calcite","bidirectional",0.01).spec)
    push!(d["paths"][1]["operations"],Dict("id"=>"acid","kind"=>"HCl","amount_mol"=>0.0001,"addition_model"=>"formula_addition_no_carrier_water","active_phases"=>["Calcite"],"source_id"=>"SYNTHETIC acid"))
    push!(d["paths"][1]["operations"],Dict("id"=>"base","kind"=>"NaOH","amount_mol"=>0.0001,"addition_model"=>"formula_addition_no_carrier_water","active_phases"=>["Calcite"],"source_id"=>"SYNTHETIC base"))
    result=compare_paths(PathStudy(d),c;root).candidates[1]
    @test all(p->p["accounting"]["mass_pass"]&&p["accounting"]["charge_pass"],result["steps"])
end
