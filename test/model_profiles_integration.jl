@testset "Discovery annotation preserves finite chemistry, proxy classes and strict uncertainty" begin
    root=joinpath(@__DIR__,"../results");s=load_discovery(joinpath(@__DIR__,"../examples/discovery.toml"));config=PHREEQCConfig()
    reg=load_evidence_registry();p=load_model_profiles(;registry=reg)["discovery-cafc-386"]
    preflight=evaluate_applicability(p,s,config;registry=reg)
    @test preflight["profile_match_status"]=="unknown_evidence"
    @test "ionic_strength_mol_kgw" in preflight["unknown_conditions"]
    r=discover_paths(s,config;root)
    @test length(r.candidates)==210
    @test [count(c->c["screening"]["classification"]==k,r.candidates) for k in ("compatible","incompatible","undetermined")]==[2,201,7]
    @test all(c->c["model_applicability"]["profile_match_status"]=="unknown_evidence" && !c["model_applicability"]["strict_qualified"],r.candidates)
    @test all(c->c["screening"]["formation_order_classification"]=="undetermined",r.candidates)
    path=report(r);page=read(path,String)
    @test occursin("Separate model applicability",page)
    @test isfile(joinpath(r.directory,"model-profile.toml")) && isfile(joinpath(r.directory,"model-applicability.json"))
    @test all(c->all(s->haskey(s["selected"],"ionic_strength") && haskey(s["selected"],"pressure_atm"),c["steps"]),r.candidates)
    println("V080_DISCOVERY_ARCHIVE=",r.directory)
end
