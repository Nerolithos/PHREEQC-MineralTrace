include(joinpath(@__DIR__,"../scripts/validate_upstream.jl"))
@testset "Version-matched official references never grant experimental support" begin
    dir=validate_upstream(joinpath(@__DIR__,"../results"));r=TOML.parsefile(joinpath(dir,"benchmark-results.toml"))
    @test !r["experimental_support_granted"]
    @test length(r["benchmarks"])==3
    @test all(b->b["adapter_direct_byte_identical"] && b["locked_reference_agreement"],r["benchmarks"])
    @test only(b for b in r["benchmarks"] if b["example"]=="ex6")["behavior"]["reaction_dose_progression"]
    @test only(b for b in r["benchmarks"] if b["example"]=="ex7")["behavior"]["fixed_volume_liters"]==23.19
    @test only(b for b in r["benchmarks"] if b["example"]=="ex22")["behavior"]["phi_min"]<1
    @test isfile(joinpath(dir,"reproduce.jl"))
    println("V080_UPSTREAM_ARCHIVE=",dir)
end
