# All numbers below are genuine engine outputs; no experimental references are invented.
@testset "Locked current-engine regression" begin
    baseline=TOML.parsefile(joinpath(@__DIR__,"../data/validation/ex1-current-engine.toml"))
    c=PHREEQCConfig(); env=environment_check(c)
    @test env.database_sha256 == baseline["database_sha256"]
    original=read(joinpath(@__DIR__,"../data/validation/usgs-ex1.pqi"),String)
    selection="""
    SELECTED_OUTPUT 1
        -file selected.tsv
        -reset false
        -high_precision true
        -pH true
        -temperature true
        -saturation_indices Calcite Gypsum Anhydrite
    END
    """
    input=replace(original,r"(?m)^END\s*$"=>selection;count=1)
    @test bytes2hex(sha256(codeunits(input))) == baseline["input_sha256"]
    if bytes2hex(sha256(read(env.executable))) != baseline["engine_sha256"]
        @warn "Executable hash differs from captured regression binary; compare version/build provenance."
    end
    r=run_phreeqc(c,input;root=joinpath(@__DIR__,"../results"),required=["si_$m" for m in keys(baseline["si"])])
    for (m,expected) in baseline["si"]
        @test isapprox(parse(Float64,r.rows[1]["si_$m"]),expected;atol=baseline["absolute_tolerance"],rtol=0)
    end
end

@testset "Fluorite–Calcite real-engine consistency suite" begin
    c=PHREEQCConfig(); root=joinpath(@__DIR__,"../results"); records=String[]
    function probe(;t=25.,ph=7.,f=0.00016)
        fluid=FluidState(temperature_c=t,pH=ph,totals=Dict("Ca"=>0.001,"F"=>f,"C(4)"=>0.001,"Na"=>0.001,"Cl"=>0.002),label="SYNTHETIC / SIMULATED consistency fixture",allow_unvalidated_temperature=true)
        input=replace(solution_input(fluid),"END"=>"USER_PUNCH 1\n    -headings lkF lkC\n    -start\n    10 PUNCH LK_PHASE(\"Fluorite\"), LK_PHASE(\"Calcite\")\n    -end\nEND")
        input=replace(input,"    -totals Ca F C(4)"=>"    -totals Ca F C(4)\n    -molalities CO2 HCO3- CO3-2\n    -water true")
        run_phreeqc(c,input;root,required=["si_Fluorite","si_Calcite","lkF","lkC","m_CO3-2","m_HCO3-"])
    end
    fs=[probe(f=f) for f in (8e-5,1.6e-4,3.2e-4)]
    fsi=[parse(Float64,r.rows[1]["si_Fluorite"]) for r in fs]
    @test all(diff(fsi).>0)
    push!(records,"Fluoride totals 8e-5, 1.6e-4, 3.2e-4 mol/kgw → Fluorite SI: $fsi. Monotonic only for this fixture; not a universal linear law.")
    ps=[probe(ph=ph) for ph in (6.,7.5,9.)]
    csi=[parse(Float64,r.rows[1]["si_Calcite"]) for r in ps]
    ratios=[parse(Float64,r.rows[1]["m_CO3-2"])/parse(Float64,r.rows[1]["m_HCO3-"]) for r in ps]
    @test all(diff(csi).>0)
    @test all(diff(ratios).>0)
    push!(records,"pH 6, 7.5, 9 → Calcite SI: $csi; CO3/HCO3 molality ratios: $ratios.")
    ts=[probe(t=t) for t in (25.,50.,80.)]
    logks=[[parse(Float64,r.rows[1][k]) for k in ("lkF","lkC")] for r in ts]
    @test all(v->all(isfinite,v),logks)
    @test abs(logks[1][1]-logks[end][1])>0.01
    @test abs(logks[1][2]-logks[end][2])>0.01
    push!(records,"Temperatures 25, 50, 80 °C → [log K Fluorite, log K Calcite]: $logks. Response verified, external accuracy and full applicability not established.")
    for r in vcat(fs,ps,ts)
        row=r.rows[1]; num(k)=parse(Float64,row[k])
        @test isapprox(num("si_Fluorite"),num("la_Ca+2")+2num("la_F-")-num("lkF");atol=1e-9,rtol=0)
        @test isapprox(num("si_Calcite"),num("la_Ca+2")+num("la_CO3-2")-num("lkC");atol=1e-9,rtol=0)
        for (key,total) in (("Ca",0.001),("C(4)",0.001))
            @test isapprox(num(key),total;rtol=1e-10)
        end
        @test any(w->occursin("Charge imbalance",w),r.manifest["warnings"]) == (abs(num("pct_err")) > 0.1)
    end
    push!(records,"SI identity verified against engine-reported log activities and LK_PHASE at every probe; speciation-only Ca/C totals retained. Probe inputs are unadjusted; warning presence checked against the declared 0.1% threshold at each point.")
    for (name,inventory,ca,f,carbon,ph) in (("precipitation",0.,0.01,0.002,0.01,9.),("dissolution",0.01,1e-8,1e-8,1e-8,7.))
        input="""
        SOLUTION 1 SYNTHETIC / SIMULATED reaction mass-balance fixture
            temp 25
            pH $ph
            units mol/kgw
            Ca $ca
            F $f
            C(4) $carbon
            Na 0.02
            Cl 0.02
        EQUILIBRIUM_PHASES 1
            Calcite 0 $inventory
            Fluorite 0 $inventory
        SELECTED_OUTPUT 1
            -file selected.tsv
            -reset false
            -state true
            -high_precision true
            -water true
            -totals Ca F C(4)
            -equilibrium_phases Calcite Fluorite
        END
        """
        r=run_phreeqc(c,input;root,required=["Ca","F","C(4)","mass_H2O"])
        initial=only(filter(row->row["state"]=="i_soln",r.rows)); final=only(filter(row->row["state"]=="react",r.rows))
        n(row,k)=parse(Float64,row[k]); water=n(final,"mass_H2O"); pc=n(final,"Calcite"); pf=n(final,"Fluorite")
        diffs=Float64[]
        for (element,solid_initial,solid_final) in (("Ca",2inventory,pc+pf),("F",2inventory,2pf),("C(4)",inventory,pc))
            before=n(initial,element)*n(initial,"mass_H2O")+solid_initial
            after=n(final,element)*water+solid_final
            push!(diffs,after-before)
            @test isapprox(after,before;atol=1e-9,rtol=1e-8)
        end
        name=="precipitation" ? (@test pc+pf>0) : (@test pc+pf<2inventory)
        push!(records,"$name: final phase mol [Calcite, Fluorite] = $([pc,pf]); total-inventory residuals [Ca,F,C] mol = $diffs. Aqueous molality × actual water mass plus phase inventories; no assumption of fixed water after reaction.")
    end
    env=environment_check(c)
    push!(records,"Database SHA-256: $(env.database_sha256). Actual availability is checked by required numeric SI columns; missing phases fail rather than become default zeros. Bounds 25–80 °C are exploratory product limits, not a certified database validity interval.")
    doc="# Fluorite–Calcite benchmark suite — 2026-11-01\n\nAll fixtures are SYNTHETIC / SIMULATED. These are internal consistency and behavior tests, not measured equilibrium data or validation of natural deposits.\n\n"*join(["- $x" for x in records],"\n\n")*"\n\nDatabase audit: Calcite and Fluorite both contain temperature expressions in the official database. CaF+ is commented out. The activity/species completeness and temperature accuracy remain unvalidated; no parameters were imported or altered. Different databases would require separate activity-model and species audits; they are not independent repeat experiments. This sprint does not claim an inter-database validation. See DATABASE_REVIEW.md and the study reports for limitations.\n"
    write(joinpath(@__DIR__,"../data/validation/CAF_C_BENCHMARK.md"),doc)
end
