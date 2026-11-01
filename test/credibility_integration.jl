@testset "Historical reference attributed to database profile, original tolerance retained" begin
    root=joinpath(@__DIR__,"../results");db=joinpath(@__DIR__,"../data/validation/historical-2012/phreeqc.dat")
    original=read(joinpath(@__DIR__,"../data/validation/usgs-ex1.pqi"),String)
    input=replace(original,r"(?m)^END\s*$"=>"SELECTED_OUTPUT\n -file selected.tsv\n -reset false\n -high_precision true\n -saturation_indices Calcite Gypsum Anhydrite\nEND";count=1)
    config=PHREEQCConfig();old=run_phreeqc(PHREEQCConfig(executable=config.executable,database=db),input;root)
    modern=run_phreeqc(config,input;root);refs=TOML.parsefile(joinpath(@__DIR__,"../data/validation/ex1-reference.toml"))
    @test refs["absolute_tolerance"]==0.01
    for (phase,value) in refs["si"]
        @test abs(parse(Float64,only(old.rows)["si_$phase"])-value)<=0.01
        @test abs(parse(Float64,only(modern.rows)["si_$phase"])-value)>0.01
    end
    @test old.manifest["executable_sha256"]==modern.manifest["executable_sha256"]
    @test old.manifest["input_sha256"]==modern.manifest["input_sha256"]
    @test old.manifest["database_sha256"]!=modern.manifest["database_sha256"]
end

@testset "Real regulated CO2 endpoint, numerical closure and direct replay" begin
    d=Dict("temperature_c"=>24.,"solution_pressure_bar"=>10.12,"pco2_bar"=>10.09,"water_kg"=>0.8,"calcite_g"=>10.,"co2_reservoir_mol"=>10.,"source_id"=>"REFLECT-D23-2023","allow_unvalidated_conditions"=>true,"initial_recipe"=>"degassed_deionised_water_modelled_as_pure_water")
    config=PHREEQCConfig();root=joinpath(@__DIR__,"../results");r=calcite_endpoint(CalciteCO2Endpoint(d),config;root)
    @test r["mass_pass"] && r["charge_pass"] && r["boundary_attained"]
    @test r["model_applicability"]=="unverified"
    @test r["calcite_net_dissolved_mol"]>0 && r["CO2_exchange_mol"]>0
    @test r["solubility_g_per_kg_water"]>r["solubility_g_per_kg_solution"]>0
    @test 0<r["gas_fugacity_coefficient"]<1
    d["calcite_g"]=40.;d["co2_reservoir_mol"]=20.;control=calcite_endpoint(CalciteCO2Endpoint(d),config;root)
    @test abs(control["solubility_g_per_kg_water"]-r["solubility_g_per_kg_water"])<1e-8
    # Agreement with measured data is not asserted as a software invariant: the independent challenge exposes a real discrepancy.
    direct=abspath(mktempdir(root;prefix="endpoint-direct-",cleanup=false))
    cp(joinpath(r["archive"],"input.pqi"),joinpath(direct,"input.pqi"));cp(config.database,joinpath(direct,"database.dat"))
    open(joinpath(direct,"console.log"),"w") do io
        run(pipeline(Cmd(Cmd([environment_check(config).executable,"input.pqi","output.pqo","database.dat"]);dir=direct);stdin=devnull,stdout=io,stderr=io))
    end
    lines=filter(l->!isempty(strip(l)),readlines(joinpath(direct,"selected.tsv")));heads=split(lines[1]);raw=[Dict(zip(heads,split(l))) for l in lines[2:end]];row=only(filter(q->q["state"]=="react",raw))
    @test all(k->parse(Float64,row[k])==parse(Float64,r["selected"][k]),["pH","n_Ca","n_C","n_H","n_O","solid_Calcite","reservoir_CO2"])
end

@testset "Verified state reclassification, OAT and uncomputed plane cells" begin
    spec=TOML.parsefile(joinpath(@__DIR__,"../examples/discovery.toml"));spec["search"]["allowed_processes"]=["equilibrium","cooling","NaOH"]
    for g in spec["grids"]
        g["titrant_amounts_mol"]=[0.001,0.009]
        g["role"]=="resolution" && (g["initial_values"]["pH"]=[2.,2.1])
    end
    config=PHREEQCConfig();r=discover_paths(DiscoveryStudy(spec),config;root=joinpath(@__DIR__,"../results"));plan=load_robustness(joinpath(@__DIR__,"../examples/robustness.toml"))
    before=deepcopy(r.candidates);a=analyze_robustness(r,plan,config)
    @test r.candidates==before # Thresholds and OAT do not overwrite original chemistry/results.
    @test all(t->!t["chemistry_recomputed"],a["threshold_sensitivity"])
    baseline=only(t for t in a["threshold_sensitivity"] if t["threshold_mol"]==1e-7)
    @test isempty(baseline["flipped_candidate_ids"])
    @test all(t->t["counts"]==baseline["counts"],filter(t->t["threshold_mol"]<=1e-6,a["threshold_sensitivity"]))
    @test !isempty(last(a["threshold_sensitivity"])["flipped_candidate_ids"])
    @test all(t->all(q->q["formation_order_classification"]=="undetermined",t["classifications"]),a["threshold_sensitivity"])
    @test length(a["one_at_a_time"])==5
    @test !isempty(a["sampled_plane"]["unsampled_cells"])
    @test length(unique((p["x"],p["y"]) for p in a["sampled_plane"]["points"]))==length(a["sampled_plane"]["points"])
    @test all(c->c["computational_status"]=="success" && all(p->p["accounting"]["mass_pass"] && p["accounting"]["charge_pass"],c["steps"]),a["candidates"])
    bad=deepcopy(plan.spec);bad["thresholds_mol"][1]=0.
    @test_throws ArgumentError analyze_robustness(r,RobustnessPlan(bad),config)
    tr=r.candidates[1]["steps"][2]["phase_transfers"]["Fluorite"];old=tr["solid_gain_mol"];tr["solid_gain_mol"]+=1e-5
    @test_throws ArgumentError analyze_robustness(r,plan,config)
    tr["solid_gain_mol"]=old
    report(r);path=report_robustness(r,a);page=read(path,String)
    @test occursin("White space between samples is uncomputed",page)
    @test !occursin("<script",page)
    @test all(f->isfile(joinpath(r.directory,f)),["robustness-analysis.json","parameter-sensitivity.csv","threshold-sensitivity.csv","sampled-compatibility.svg","reproduce_robustness.jl"])
end
