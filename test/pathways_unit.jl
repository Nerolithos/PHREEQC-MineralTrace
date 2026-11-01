@testset "Explicit pathway schema and evidence levels" begin
    base=TOML.parsefile(joinpath(@__DIR__,"../examples/reactive_paths.toml"))
    s=PathStudy(base)
    @test length(s.graph.evidence)==1
    @test topological_order(s.graph)==["F-I","C-I"]
    for modify in (d->(d["boundary"]="open_unspecified"),d->delete!(d["phases"][1],"initial_mol"),d->(d["phases"][1]["direction"]="automatic"),d->(d["paths"][1]["operations"][1]["active_phases"]=["Quartz"]),d->(d["paths"][1]["bindings"][1]["level"]="observed_formation_from_SI"),d->(d["paths"][1]["operations"][1]["temperature_c"]=90.))
        d=deepcopy(base);modify(d)
        @test_throws Exception PathStudy(d)
    end
    d=deepcopy(base);push!(d["evidence"],merge(d["evidence"][1],Dict("earlier"=>"C-I","later"=>"F-I")))
    @test_throws CycleConflict PathStudy(d)
    d=deepcopy(base);d["paths"][1]["bindings"][1]["level"]="equilibrium_dissolution"
    @test_throws ArgumentError PathStudy(d) # Dissolution is not a formation-event surrogate.
    input=MineralTrace.path_operation_input(s,base["paths"][1]["operations"][1],Dict("Fluorite"=>0.,"Calcite"=>0.))
    @test occursin("USE equilibrium_phases none",input)
    @test !occursin(r"(?m)^\s*pH\s",input)
    @test occursin("REACTION_TEMPERATURE",input)
end
