@testset "Robustness plans and explicit endpoint boundaries" begin
    plan=load_robustness(joinpath(@__DIR__,"../examples/robustness.toml"))
    @test length(plan.spec["parameters"])==5
    for change in (d->(d["parameters"][1]["units"]="degC"),d->(d["parameters"][5]["operation_index"]=0),d->(d["thresholds_mol"]=[NaN,1e-7]),d->(d["plane"]["y_parameter_id"]="initial-pH"))
        d=deepcopy(plan.spec);change(d);@test_throws Exception RobustnessPlan(d)
    end
    spec=Dict("temperature_c"=>24.,"solution_pressure_bar"=>10.12,"pco2_bar"=>10.09,"water_kg"=>0.8,"calcite_g"=>10.,"co2_reservoir_mol"=>10.,"source_id"=>"REFLECT-D23-2023","allow_unvalidated_conditions"=>true,"initial_recipe"=>"degassed_deionised_water_modelled_as_pure_water")
    e=CalciteCO2Endpoint(spec)
    @test occursin("pH 7 charge",MineralTrace.endpoint_input(e)) # Explicit neutral pure-water model only, not a measured-fluid correction.
    for change in (d->(d["pco2_bar"]=60.),d->(d["solution_pressure_bar"]=9.),d->(d["allow_unvalidated_conditions"]=false),d->(d["initial_recipe"]="unknown_natural_fluid"))
        d=deepcopy(spec);change(d);@test_throws ArgumentError CalciteCO2Endpoint(d)
    end
    @test bytes2hex(sha256(read(joinpath(@__DIR__,"../data/validation/reflect-2023/observations.csv"))))=="2e8df44966f958f0959c4f252124e8a0b55c5b4b3e4889a5799a328a0d12d805"
    # All selected points existed before predictions and remain unchanged; no inaccurate point is removed.
    @test length(readlines(joinpath(@__DIR__,"../data/validation/reflect-2023/observations.csv")))==6
end
