include(joinpath(@__DIR__,"../scripts/validate_holdout.jl"))
@testset "Pre-prediction freeze prevents data/model drift without fitting" begin
    project=joinpath(dirname(@__DIR__),"data/validation/frozen-v081");config=PHREEQCConfig()
    receipt=verify_holdout_freeze(project,config)
    @test receipt["frozen_before_first_prediction"]
    @test receipt["holdout_qualification"]=="database_calibration_independence_UNKNOWN"
    rows=[split(line,',') for line in readlines(joinpath(project,"data/validation/holdout-ferreira-2025/observations.csv"))[2:end]]
    @test length(rows)==5 && all(r->parse(Float64,r[2])-273.15==25.,rows)
    @test all(isapprox.( [parse(Float64,r[3])/100 for r in rows], [1.013,1.346,1.613,1.88,2.146]; atol=1e-12,rtol=0))
    registry=load_evidence_registry();profile=load_model_profiles(;registry)["calcite-co2-water-386"]
    @test registry.entries["FERREIRA-2025-25C-Ca"]["independent_of_calibration"]=="UNKNOWN"
    query=Dict{String,Any}("database_sha256"=>receipt["database_sha256"],"activity_model"=>"ion_association","gas_model"=>"peng_robinson","boundary"=>"fixed_partial_pressure","components"=>["Ca","C","H","O"],"minerals"=>["Calcite"],"temperature_c"=>25.,"pco2_bar"=>1.013,"pressure_bar"=>1.0447,"ionic_strength_mol_kgw"=>0.03,"observable"=>"total_Ca_as_CaCO3_endpoint")
    match=evaluate_applicability(profile,query;registry,database_audit=audit_database(config.database))
    @test match["profile_match_status"]=="experimentally_challenged" && !match["strict_qualified"]
    @test match["applicable_reference_ids"]==["FERREIRA-2025-25C-Ca"]
    # No engine call is made in the tampering test; malformed frozen files stop preflight first.
    mktempdir() do fixture
        for file in keys(receipt["files_sha256"])
            dest=joinpath(fixture,file);mkpath(dirname(dest));cp(joinpath(project,file),dest)
        end
        dest=joinpath(fixture,"data/validation/holdout-ferreira-2025/FREEZE.toml");cp(joinpath(project,"data/validation/holdout-ferreira-2025/FREEZE.toml"),dest)
        open(joinpath(fixture,"data/validation/holdout-ferreira-2025/observations.csv"),"a") do io
            println(io,"# forbidden silent rebaseline")
        end
        @test_throws ErrorException verify_holdout_freeze(fixture,config)
    end
end
