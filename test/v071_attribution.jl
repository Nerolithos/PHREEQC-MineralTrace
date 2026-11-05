using Test, MineralTrace, SHA
include(joinpath(@__DIR__,"../scripts/attribute_calcite_bias.jl"))
@testset "Attribution controls preserve observations and isolate declared changes" begin
    base=ENV["PHREEQC_DATABASE"];pitzer=joinpath(dirname(base),"pitzer.dat")
    @test bytes2hex(sha256(read(joinpath(@__DIR__,"../data/validation/reflect-2023/observations.csv"))))==OBS_HASH
    mktempdir() do d
        patch=diagnostic_databases(base,pitzer,d)
        original=read(base,String);ideal=read(joinpath(d,"ideal-co2.dat"),String);davies=read(joinpath(d,"davies-ions.dat"),String)
        # Exactly three EOS lines may be removed; all equilibrium constants remain byte-identical.
        old=split(original,'\n');new=split(ideal,'\n');removed=filter(l->!(l in new),old)
        @test length(removed)==3
        @test all(l->occursin(r"-(T_c|P_c|Omega)",l),removed)
        constants(s)=filter(l->occursin(r"(?i)(log_k|analytic|delta_h)",l),split(s,'\n'))
        @test constants(original)==constants(ideal)==constants(davies)
        @test length(split(davies,'\n'))==length(old)-5 # five declared charged-ion parameter lines
        @test patch["davies_ions_with_removed_gamma"]==["CO3-2","Ca+2","CaHCO3+","H+","HCO3-"]
        @test read(joinpath(d,"pitzer.dat"))==read(pitzer)
    end
    e=CalciteCO2Endpoint(Dict("temperature_c"=>24.,"solution_pressure_bar"=>10.12,"pco2_bar"=>10.09,"water_kg"=>0.8,"calcite_g"=>10.,"co2_reservoir_mol"=>10.,"source_id"=>"REFLECT-D23-2023","allow_unvalidated_conditions"=>true,"initial_recipe"=>"degassed_deionised_water_modelled_as_pure_water"))
    input=attribution_input(e,0.1;pressure_atm=1.)
    @test occursin("REACTION_PRESSURE 1\n 1.0",input)
    @test occursin("PRESSURE, MU",input)
    @test occursin("CO2(g) $(log10(10.09/1.01325)) 10",input)
end
