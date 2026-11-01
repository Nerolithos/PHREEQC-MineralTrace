@testset "Charge semantics and controlled-process input validation" begin
    q=charge_diagnostic(0.2,2e-6,2.;threshold_percent=0.1,context="hypothetical")
    @test q["net_charge_eq_per_kgw"]==1e-6
    @test q["net_charge_meq_per_kgw"]==0.001
    @test q["diagnostic_status"]=="exceeds_declared_threshold"
    @test occursin("not an analytical",q["interpretation"])
    @test charge_diagnostic(0.2,2e-6,2.;threshold_percent=0.3)["diagnostic_status"]=="within_declared_threshold"
    @test charge_diagnostic(nothing,0.,1.)["diagnostic_status"]=="undetermined"
    @test occursin("measured ionic",charge_diagnostic(0.2,1e-5,1.;context="analytical")["interpretation"])
    @test occursin("partial",charge_diagnostic(0.2,1e-5,1.;context="partial_analysis")["interpretation"])
    @test occursin("inherited",charge_diagnostic(0.2,1e-5,1.;context="controlled_process")["interpretation"])
    @test_throws ArgumentError charge_diagnostic(0.,0.,0.)
    @test_throws ArgumentError charge_diagnostic(0.,0.,1.;threshold_percent=-1.)
    d=TOML.parsefile(joinpath(@__DIR__,"../examples/acid_titration.toml"))
    p=AcidBaseTitration(d);input=process_input(p)
    @test occursin("INCREMENTAL_REACTIONS true",input)
    @test occursin("HCl 1.0",input)
    @test length(collect(eachmatch(r"(?m)^\s*pH\s",input)))==1 # Initial only, never per-step pH replacement.
    @test !occursin("EQUILIBRIUM_PHASES",input)
    @test !occursin(r"(?m)^\s*(Ca|F|Cl|Na|pH)\s+[^\n]*\bcharge\b",input)
    for change in (d->(d["titrant"]["identity"]="H+"),d->(d["titrant"]["amounts_mol"]=[-1e-5]),d->(d["titrant"]["amounts_mol"]=[NaN]),d->(d["titrant"]["addition_model"]="aqueous_volume_unknown"),d->(d["initial"]["units"]="mg/L"),d->delete!(d["initial"]["totals"],"F"),d->(d["initial"]["charge_context"]="analytical"),d->(d["diagnostics"]["charge_threshold_percent"]=-1.),d->(d["pressure_atm"]=100.),d->(d["minerals"]=["Unknown"]))
        bad=deepcopy(d);change(bad);@test_throws ArgumentError AcidBaseTitration(bad)
    end
    d["temperature_c"]=50.;@test_throws ArgumentError AcidBaseTitration(d)
    d["allow_unvalidated_temperature"]=true;@test AcidBaseTitration(d) isa AcidBaseTitration
end
