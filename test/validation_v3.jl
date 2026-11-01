@testset "Version-matched upstream reference and independent parameter screening" begin
    c=PHREEQCConfig(); ref=TOML.parsefile(joinpath(@__DIR__,"../data/validation/ex1-current-engine.toml"))
    raw=read(joinpath(@__DIR__,"../data/validation/upstream-v3.8.6/ex1.out"),String)
    for m in ("Calcite","Fluorite","Gypsum","Anhydrite")
        m=="Fluorite" && continue
        matchrow=match(Regex("(?m)^\\s*"*m*"\\s+([-0-9.]+)"),raw)
        @test matchrow!==nothing
        @test abs(ref["si"][m]-parse(Float64,matchrow[1]))<=0.01
    end
    @test read(joinpath(@__DIR__,"../data/validation/upstream-v3.8.6/ex1.pqi"))==read(joinpath(@__DIR__,"../data/validation/usgs-ex1.pqi"))
    input="""
    SOLUTION 1 SYNTHETIC parameter check, not an experimental case
        temp 25
        pressure 1
        pH 7
        units mol/kgw
        Ca 0.001
        F 0.00022
        C(4) 0.001
    SELECTED_OUTPUT
        -file selected.tsv
        -reset false
        -high_precision true
    USER_PUNCH
        -headings Fluorite Calcite
        -start
        10 PUNCH LK_PHASE("Fluorite"), LK_PHASE("Calcite")
        -end
    END
    """
    r=run_phreeqc(c,input;root=joinpath(@__DIR__,"../results"),required=["Fluorite","Calcite"],sources=["NORDSTROM-2022","PLUMMER-BUSENBERG-1982"])
    refs=TOML.parsefile(joinpath(@__DIR__,"../data/validation/independent-reference-checks.toml"))
    rows=String[]
    for phase in ("Fluorite","Calcite")
        actual=parse(Float64,r.rows[1][phase]);d=refs[phase]
        @test abs(actual-d["value"])<=d["reported_uncertainty"]
        push!(rows,"| $phase | $(d["value"]) | $(d["reported_uncertainty"]) | $actual | $(actual-d["value"]) |")
    end
    write(joinpath(@__DIR__,"../data/validation/independent-parameter-results.md"),"# Published parameter screening\n\nNot a complete independent aqueous-case validation. Published uncertainty is used for a scalar consistency screen, not as an invented model tolerance. Fluorite reference is at 1 bar, calculation at 1 atm; this pressure mismatch is disclosed, not silently corrected.\n\n| Phase | Reference log K | Published uncertainty | Engine log K | Signed delta |\n|---|---:|---:|---:|---:|\n"*join(rows,"\n")*"\n\nSources and limitations: independent-reference-checks.toml. Raw calculation: $(r.directory).\n")
end

@testset "Actual balanced/unbalanced chemistry and v0.2 raw regression" begin
    c=PHREEQCConfig();root=joinpath(@__DIR__,"../results")
    for (cl,balanced) in ((0.001,true),(0.002,false))
        f=FluidState(temperature_c=25.,pH=7.,totals=Dict("Ca"=>0.001,"F"=>0.002,"C(4)"=>0.,"Na"=>0.001,"Cl"=>cl),label="SYNTHETIC / SIMULATED CaF2 + NaCl total recipe")
        input=solution_input(f)
        r=run_phreeqc(c,input;root,required=["pct_err"])
        pct=parse(Float64,r.rows[1]["pct_err"])
        @test (abs(pct)<=0.1)==balanced
        @test read(joinpath(r.directory,"input.pqi"),String)==input
        @test !occursin(r"(?m)^\s*(pH|Ca|F|Na|Cl)\s+[^\n]*\bcharge\b",input)
        audit=MineralTrace.species_charge_audit(joinpath(r.directory,"output.pqo"))
        @test audit["status"]=="rounded_species_diagnostic"
        @test abs(audit["percent_error"]-pct)<0.02
    end
    legacy=load_study(joinpath(@__DIR__,"../examples/fluorite_calcite.toml"))
    r=scan(legacy,c;root)
    baseline=TOML.parsefile(joinpath(@__DIR__,"../data/validation/v020-scan-regression.toml"))
    @test r.provenance["database_sha256"]==baseline["database_sha256"]
    @test length(r.samples)==length(baseline["points"])==42
    for (p,old) in zip(r.samples,baseline["points"])
        @test p["coordinates"]==Dict("temperature"=>old["temperature"],"pH"=>old["pH"])
        @test p["status"]==old["status"]
        for m in ("Fluorite","Calcite")
            @test isapprox(p["si"][m],old[m];atol=1e-10,rtol=0)
        end
        @test abs(p["charge_audit"]["percent_error"]-parse(Float64,p["selected"]["pct_err"]))<0.02
    end
    @test count(p->p["evaluation"]["chemical_quality_status"]=="fail",r.samples)==41
    @test count(p->p["evaluation"]["computational_status"]=="success",r.samples)==42
    @test all(p->p["evaluation"]["model_applicability_status"]=="unverified",r.samples)
    @test count(p->p["evaluation"]["final_status"]=="included_conditional",r.samples)==1
    # New evidence example exercises actual strict/exploratory policies without changing its inputs.
    s=load_study(joinpath(@__DIR__,"../examples/evidence_constraints.toml")); er=scan(s,c;root)
    @test_throws ArgumentError evaluate_constraints(s,er.samples[1];database_sha256="different")
    changed=deepcopy(s.spec);changed["fluid"]["totals"]["F"]*=2
    @test_throws ArgumentError evaluate_constraints(MineralStudy(changed),er.samples[1])
    contribution=constraint_contribution(s,er.samples)
    @test contribution["baseline_si_and_chemistry_count"]>contribution["after_evidence_count"]>0
    @test any(q->q["removed"]>0,contribution["sequential"])
    @test any(q->q["redundant_on_grid"],contribution["leave_one_out"])
    strict=deepcopy(s.spec);strict["evaluation"]["mode"]="strict";ss=MineralStudy(strict)
    for p in er.samples
        e=evaluate_constraints(ss,p)
        @test !e["regions"]["final_feasible"]
        @test e["chemical_quality_status"]==p["evaluation"]["chemical_quality_status"]
    end
    path=report(er)
    @test occursin("Constraint contribution",read(path,String))
    for f in ("chemical.svg","model.svg","final.svg","warnings.svg","exclusions.svg","analysis.json","constraints.csv","constraint-evaluations.csv","constraint-contribution.csv")
        @test isfile(joinpath(er.directory,f))
    end
end
