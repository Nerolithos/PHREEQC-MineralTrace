@testset "Evidence-independent bounded environmental discovery" begin
    base=TOML.parsefile(joinpath(@__DIR__,"../examples/discovery.toml"));s=DiscoveryStudy(base);g=generate_candidates(s)
    @test length(g.candidates)==210
    @test Dict(k=>length(v) for (k,v) in g.membership)==Dict("baseline"=>60,"refined"=>210,"narrower"=>30)
    @test length(unique(c["chemistry_sha256"] for c in g.candidates))==length(g.candidates)
    @test s.spec==base
    @test all(c->all(op->Set(op["active_phases"])==Set(base["minerals"]),only(c["spec"]["paths"])["operations"]),g.candidates)
    @test all(c->isempty(only(c["spec"]["paths"])["bindings"]),g.candidates)
    @test any(c->count(op->op["kind"]=="temperature",c["environmental_sequence"])==2,g.candidates)
    @test any(c->Set(op["kind"] for op in c["environmental_sequence"])==Set(["HCl","NaOH"]),g.candidates) # Neutralizing sequence can add salt; not discarded as an identity.
    for c in g.candidates
        t=c["spec"]["initial_temperature_c"]
        for op in c["environmental_sequence"]
            if op["kind"]=="temperature";@test op["temperature_c"]<t;t=op["temperature_c"];end
        end
        @test sum((get(op,"amount_mol",0.) for op in c["environmental_sequence"]);init=0.)<=base["search"]["max_total_addition_mol"]+1e-15
    end
    reversed=deepcopy(base);reversed["evidence"][1]["earlier"]="C-I";reversed["evidence"][1]["later"]="F-I"
    reversed["events"]=reverse(reversed["events"])
    other=generate_candidates(DiscoveryStudy(reversed))
    @test [c["chemistry_sha256"] for c in other.candidates]==[c["chemistry_sha256"] for c in g.candidates]
    @test [only(c["spec"]["paths"])["operations"] for c in other.candidates]==[only(c["spec"]["paths"])["operations"] for c in g.candidates]
    @test other.membership==g.membership
    for mutate in (d->(d["accessibility"]="toggle_to_fit_evidence"),d->(d["search"]["max_depth"]=5),d->(d["search"]["max_candidates"]=1),d->(d["grids"][2]["temperature_values_c"]=[25.,50.,79.]),d->(d["grids"][3]["initial_values"]["pH"]=[2.,2.1]),d->(d["search"]["allowed_processes"]=["overwrite_pH"]),d->(d["search"]["reaction_threshold_mol"]=0.),d->(d["grids"][1]["initial_values"]["Mg"]=[0.]))
        bad=deepcopy(base);mutate(bad)
        @test_throws Exception generate_candidates(DiscoveryStudy(bad))
    end
    bad=deepcopy(base);bad["grids"][2]["temperature_values_c"]=[25.,80.];bad["grids"][2]["titrant_amounts_mol"]=[0.001,0.009];bad["grids"][2]["initial_values"]["pH"]=[2.,2.1]
    @test_throws ArgumentError DiscoveryStudy(bad) # No pretend resolution audit.
    known=deepcopy(base);known["initial"]["origin"]="Observation";known["initial"]["charge_context"]="analytical"
    ks=DiscoveryStudy(known);kg=generate_candidates(ks)
    @test ks.spec["initial"]["origin"]=="Observation"
    @test all(c->c["spec"]["initial"]["origin"]=="Assumption",kg.candidates)
    @test all(c->occursin(known["initial"]["source"],c["spec"]["initial"]["source"]),kg.candidates)
end

@testset "Screening surrogate does not certify crystallization time (synthetic logic fixtures)" begin
    s=load_discovery(joinpath(@__DIR__,"../examples/discovery.toml"))
    function fixture(fstep,cstep)
        steps=Dict{String,Any}[]
        for i in 0:3
            push!(steps,Dict("index"=>i,"phase_transfers"=>Dict(m=>Dict("solid_gain_mol"=>((m=="Fluorite" ? fstep : cstep)==i ? 1e-4 : 0.)) for m in s.spec["minerals"]),"charge_diagnostic"=>Dict("diagnostic_status"=>"within_declared_threshold")))
        end
        Dict("computational_status"=>"success","steps"=>steps,"error"=>"")
    end
    for (f,c,classification) in ((2,3,"compatible"),(3,2,"incompatible"),(2,2,"undetermined"),(1,3,"undetermined"),(9,2,"incompatible"))
        result=MineralTrace.screen_discovered(s,fixture(f,c))
        @test result["classification"]==classification
        @test result["formation_order_classification"]=="undetermined"
        @test !result["observed_formation_confirmed_by_model"]
    end
    strict=deepcopy(s.spec);strict["evaluation_mode"]="strict"
    @test MineralTrace.screen_discovered(DiscoveryStudy(strict),fixture(2,3))["classification"]=="undetermined"
    absent=deepcopy(s.spec);delete!(absent["events"][1],"source_id")
    @test MineralTrace.screen_discovered(DiscoveryStudy(absent),fixture(2,3))["classification"]=="undetermined"
    repeated=deepcopy(s.spec);push!(repeated["events"],merge(repeated["events"][1],Dict("id"=>"F-II")))
    @test MineralTrace.screen_discovered(DiscoveryStudy(repeated),fixture(2,3))["classification"]=="undetermined"
    hard=fixture(2,3);hard["computational_status"]="hard_constraint_failure"
    @test MineralTrace.screen_discovered(s,hard)["classification"]=="incompatible"
    hard["computational_status"]="failed"
    @test MineralTrace.screen_discovered(s,hard)["classification"]=="undetermined"
end
