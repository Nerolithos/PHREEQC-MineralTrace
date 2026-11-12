@testset "Cross-study annotation preserves independent applicability dimensions" begin
    registry=load_evidence_registry();profiles=load_model_profiles(;registry)
    @test haskey(registry.entries,"CROSS-STUDY-082")
    @test registry.entries["CROSS-STUDY-082"]["conclusion"]=="applicability_unverified"
    p=profiles["calcite-co2-water-386"]
    q=Dict{String,Any}("observable"=>"equilibrium_reaction_path")
    a=evaluate_applicability(p,q;registry)
    b=evaluate_research_applicability(p,q;registry)
    @test all(b[k]==v for (k,v) in a)
    @test !b["strict_qualified"]
    @test b["cross_study_context"]["experimental_independence"]=="UNKNOWN"
    @test b["cross_study_context"]["actual_mineral_chronology"]=="undetermined"
    @test "CROSS-STUDY-082" in b["cross_study_context"]["references"]
    s=load_discovery(joinpath(@__DIR__,"../examples/discovery.toml"))
    @test length(generate_candidates(s).candidates)==210
end
