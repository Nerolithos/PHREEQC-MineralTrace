@testset "Real-engine grid, reports and off-grid signature recovery" begin
    d=TOML.parsefile(joinpath(@__DIR__,"../examples/fluorite_calcite.toml"))
    d["axes"][1]["values"]=[40.,45.]
    d["axes"][2]["values"]=[7.3,7.4]
    d["tolerances"]=Dict("Fluorite"=>10.,"Calcite"=>10.)
    root=joinpath(@__DIR__,"../results"); c=PHREEQCConfig(); r=scan(MineralStudy(d),c;root)
    @test length(r.samples)==4
    for (i,p) in enumerate(r.samples)
        @test p["ix"] == mod1(i,2)
        @test p["iy"] == cld(i,2)
        @test parse(Float64,p["selected"]["temp"]) == p["coordinates"]["temperature"]
        @test parse(Float64,p["selected"]["pH"]) ≈ p["coordinates"]["pH"]
        @test isfile(joinpath(r.directory,p["archive"],"input.pqi"))
        @test isfile(joinpath(r.directory,p["archive"],"manifest.toml"))
        @test p["status"] == "compatible"
    end
    direct=run_phreeqc(c,MineralTrace.study_input(r.study,r.samples[2]["coordinates"]);root,required=["si_Calcite","si_Fluorite"])
    @test r.samples[2]["si"]["Calcite"] == parse(Float64,direct.rows[1]["si_Calcite"])
    @test occursin("Multiple",MineralTrace.scan_summary(r)["identifiability"])
    for f in ("study.toml","provenance.toml","database.dat","src/MineralTrace.jl","Project.toml","Manifest.toml","reproduce.jl","samples.toml","data/sources/USGS-PHREEQC-3.8.6-17100.json")
        @test isfile(joinpath(r.directory,f))
    end
    @test r.provenance["database_sha256"] == bytes2hex(sha256(read(c.database)))
    @test !isempty(r.provenance["engine_banners"])
    p=report(r)
    @test isfile(p)
    @test occursin("Conditional on assumed fluid composition ranges",read(p,String))
    @test occursin("SI=0 interpolation",read(p,String))
    @test !occursin("<script src",read(p,String))
    for f in ("grid.csv","results.json","Fluorite.svg","Calcite.svg","joint.svg")
        @test isfile(joinpath(r.directory,f))
    end
    truecoords=Dict("temperature"=>42.5,"pH"=>7.35)
    @test !(truecoords["temperature"] in d["axes"][1]["values"])
    @test !(truecoords["pH"] in d["axes"][2]["values"])
    hidden=run_phreeqc(c,MineralTrace.study_input(r.study,truecoords);root,required=["si_Fluorite","si_Calcite"])
    target=Dict(m=>parse(Float64,hidden.rows[1]["si_$m"]) for m in d["minerals"])
    matches=signature_matches(r,target,Dict(m=>0.15 for m in d["minerals"]))
    @test length(matches)>=2
    for key in ("temperature","pH")
        @test minimum(p["coordinates"][key] for p in matches) <= truecoords[key] <= maximum(p["coordinates"][key] for p in matches)
    end
    recovery="# Off-grid synthetic SI-signature recovery\n\nSYNTHETIC / SIMULATED; no specimen or experimental data. This test matches forward SI signatures, not an equilibrium observation or geological history.\n\nHidden point: $truecoords. Search coordinates: temperature [40,45] °C and pH [7.3,7.4]; hidden values are off both axes.\n\nPHREEQC-generated target SI: $target. Declared signature tolerance 0.15 SI per mineral. Matched points: $([p["coordinates"] for p in matches]).\n\nThe true point is enclosed by matched grid coordinates; it is not recovered exactly, and multiple matches are reported. This checks consistency and bracketing only. Chemical warnings and the fixed assumed fluid remain applicable.\n\nSearch archive: $(r.directory). Target archive: $(hidden.directory). Database SHA-256: $(r.provenance["database_sha256"]).\n"
    write(joinpath(@__DIR__,"../data/validation/SYNTHETIC_RECOVERY.md"),recovery)
    # This verifies near-signature recovery/bracketing, not unique inversion or natural-deposit accuracy.
    one=deepcopy(d);one["axes"]=[Dict("parameter"=>"F","units"=>"mol/kgw","values"=>[0.00016,0.000161])]
    one["fixed"]["temperature"]=25.;one["mode"]="KnownFluid";one["fluid"]["origin"]="Observation";one["fluid"]["source"]="SYNTHETIC test of KnownFluid interface, not actual measurements"
    r1=scan(MineralStudy(one),c;root); @test length(r1.samples)==2
    @test report(r1) isa String
    @test occursin("Conditional on supplied fluid analysis",read(joinpath(r1.directory,"report.html"),String))
    @test occursin("Multiple",MineralTrace.scan_summary(r1)["identifiability"])
    # Actual PHREEQC runs against a deliberately incomplete database, not a mock engine.
    mktempdir() do tmp
        db=joinpath(tmp,"missing-phase.dat")
        write(db,replace(read(c.database,String),r"(?m)^Fluorite\s*$"=>"Fluorite_TEST_REMOVED"))
        bad=scan(MineralStudy(one),PHREEQCConfig(executable=c.executable,database=db);root)
        @test all(p->p["status"]=="failed",bad.samples)
        @test all(p->isempty(p["si"]),bad.samples)
        @test all(p->!isempty(p["error"]) && isfile(joinpath(bad.directory,p["archive"],"manifest.toml")),bad.samples)
        @test report(bad) isa String
        @test occursin("2 failed",read(joinpath(bad.directory,"report.html"),String))
        @test occursin("#555",read(joinpath(bad.directory,"Fluorite.svg"),String))
    end
end
