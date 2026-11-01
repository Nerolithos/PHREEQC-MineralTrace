@testset "Study configuration and SI mask semantics" begin
    base=TOML.parsefile(joinpath(@__DIR__,"../examples/fluorite_calcite.toml"))
    @test load_study(joinpath(@__DIR__,"../examples/fluorite_calcite.toml")) isa MineralStudy
    @test compatibility(Dict("Calcite"=>0.1),Dict("Calcite"=>0.2)) == "compatible"
    @test compatibility(Dict("Calcite"=>0.2),Dict("Calcite"=>0.2)) == "incompatible"
    @test compatibility(Dict("Calcite"=>NaN),Dict("Calcite"=>0.2)) == "failed"
    @test compatibility(Dict(),Dict("Calcite"=>0.2)) == "failed"
    for change in (d->(d["fluid"]["units"]="mg/L"),d->delete!(d["fluid"]["totals"],"F"),d->(d["axes"][1]["values"]=[25.,90.]),d->(d["axes"][1]["units"]="K"),d->(d["axes"][1]["values"]=[25.,25.]),d->(d["assumption"]="unknown"),d->(d["allow_unvalidated_temperature"]=false),d->(d["tolerances"]["Calcite"]=-1.))
        d=deepcopy(base); change(d); @test_throws ArgumentError MineralStudy(d)
    end
    @test_throws ArgumentError compatibility(Dict(),Dict())
    @test_throws ArgumentError compatibility(Dict("Calcite"=>0.),Dict("Calcite"=>-1.))
    d=deepcopy(base); d["fixed"]["temperatre"]=25.; @test_throws ArgumentError MineralStudy(d)
    d=deepcopy(base);d["mode"]="KnownFluid"; @test_throws ArgumentError MineralStudy(d)
    d["fluid"]["origin"]="Observation"; @test MineralStudy(d) isa MineralStudy
    @test MineralTrace.html("<script>\"&") == "&lt;script&gt;&quot;&amp;"
end
