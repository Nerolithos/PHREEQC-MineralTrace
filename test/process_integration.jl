@testset "Real PHREEQC titration: independent CLI and chemical accounting" begin
    p=load_process(joinpath(@__DIR__,"../examples/acid_titration.toml"));c=PHREEQCConfig();root=joinpath(@__DIR__,"../results")
    r=simulate(p,c;root)
    @test r.provenance["status"]=="completed"
    @test length(r.steps)==7
    @test all(diff([s["pH"] for s in r.steps]).<0)
    @test all(s->s["mass_balance_pass"],r.steps)
    @test all(s->s["charge_conservation_pass"],r.steps)
    @test abs(r.steps[1]["charge_diagnostic"]["net_charge_eq"])>1e-8 # Residual is not silently erased.
    @test r.steps[1]["charge_diagnostic"]["context"]=="hypothetical"
    @test all(s->s["charge_diagnostic"]["context"]=="controlled_process",r.steps[2:end])
    @test r.steps[end]["cumulative_added_mol"]≈sum(p.spec["titrant"]["amounts_mol"])
    for s in r.steps
        @test isapprox(s["charge_diagnostic"]["net_charge_eq"],r.steps[1]["charge_diagnostic"]["net_charge_eq"];atol=1e-10,rtol=0)
        @test abs(s["rounded_charge_inventory"]["percent_error"]-s["charge_diagnostic"]["percent_error"])<0.02
        @test !isempty(s["rounded_charge_inventory"]["species"])
        for e in MineralTrace.PROCESS_ELEMENTS
            @test s["element_balance"][e]["pass"]
        end
    end
    # Independently call CLI and split SELECTED_OUTPUT, bypassing adapter/extraction/accounting.
    dir=mktempdir(root;prefix="titration-direct-",cleanup=false);dir=abspath(dir)
    write(joinpath(dir,"input.pqi"),process_input(p));cp(c.database,joinpath(dir,"database.dat"))
    executable=environment_check(c).executable
    open(joinpath(dir,"console.log"),"w") do io
        run(pipeline(Cmd(Cmd([executable,"input.pqi","output.pqo","database.dat"]);dir);stdin=devnull,stdout=io,stderr=io))
    end
    lines=filter(l->!isempty(strip(l)),readlines(joinpath(dir,"selected.tsv")));head=String.(split(lines[1]))
    direct=[Dict(zip(head,String.(split(line)))) for line in lines[2:end]]
    @test length(direct)==length(r.steps)
    for (row,s) in zip(direct,r.steps)
        @test Set(keys(row))==Set(keys(s["selected"]))
        for key in head
            v=tryparse(Float64,row[key])
            if v===nothing
                @test row[key]==s["selected"][key]
            else
                @test isapprox(v,parse(Float64,s["selected"][key]);atol=1e-11,rtol=1e-11)
            end
        end
    end
    write(joinpath(@__DIR__,"../data/validation/TITRATION_ENGINE_COMPARISON.md"),"# Engine comparison\n\nActual direct PHREEQC CLI and MineralTrace produced matching selected-output columns at all $(length(r.steps)) acid-titration states, including pH, SI, molalities, water mass, charge and total elemental moles. Numerical comparison: atol=1e-11, rtol=1e-11. This is engine/adapter validation, not experimental validation.\n\nAdapter process: $(r.directory). Direct CLI: $dir. Database SHA-256: $(r.provenance["database_sha256"]).\n")
    # Nonuniform additions demonstrate true incremental reactions through an independent counter-ion inventory.
    d=deepcopy(p.spec);d["titrant"]["identity"]="NaOH";d["titrant"]["amounts_mol"]=[1e-5,3e-5,7e-5]
    base=simulate(AcidBaseTitration(d),c;root)
    @test all(diff([s["pH"] for s in base.steps]).>0)
    @test all(s->s["mass_balance_pass"]&&s["charge_conservation_pass"],base.steps)
    @test parse(Float64,base.steps[end]["selected"]["n_Na"])-parse(Float64,base.steps[1]["selected"]["n_Na"])≈1.1e-4
    @test parse(Float64,r.steps[end]["selected"]["n_Cl"])-parse(Float64,r.steps[1]["selected"]["n_Cl"])≈0.0012
    # Half a kilogram of water and zero-dose control guard molality-versus-mole and time-step mistakes.
    controlspec=deepcopy(p.spec);controlspec["initial"]["water_kg"]=0.5;controlspec["titrant"]["amounts_mol"]=[0.,0.]
    control=simulate(AcidBaseTitration(controlspec),c;root)
    @test all(s->s["mass_balance_pass"]&&s["charge_conservation_pass"],control.steps)
    @test isapprox(parse(Float64,control.steps[1]["selected"]["n_Ca"]),0.0005;atol=1e-12,rtol=0)
    @test maximum(s["pH"] for s in control.steps)-minimum(s["pH"] for s in control.steps)<1e-6
    # Tampered outputs are unit fixtures only; never written as scientific results.
    rows=[deepcopy(s["selected"]) for s in r.steps];rows[2]["n_Cl"]=string(parse(Float64,rows[2]["n_Cl"])+0.0001)
    @test !MineralTrace.process_accounting(p,rows)[2]["mass_balance_pass"]
    rows=[deepcopy(s["selected"]) for s in r.steps];rows[2]["charge"]="0.001"
    @test !MineralTrace.process_accounting(p,rows)[2]["charge_conservation_pass"]
    @test_throws ArgumentError MineralTrace.process_accounting(p,rows[1:end-1])
    for field in ("process.toml","reaction.pqi","database.dat","reproduce.jl","src/processes/Titration.jl")
        @test isfile(joinpath(r.directory,field))
    end
    path=report(r)
    @test occursin("not a universal",read(path,String))
    @test occursin("not completed",read(path,String))
    for file in ("steps.csv","balances.csv","charge-species.csv","pH.svg","SI.svg","species.svg","charge_percent.svg","charge_equivalents.svg","mass_balance.svg","analysis.json")
        @test isfile(joinpath(r.directory,file))
    end
    @test report(base) isa String
    @test report(control) isa String
    # Required missing phase must fail genuinely, with archived input/error instead of zero SI.
    mktempdir() do tmp
        db=joinpath(tmp,"missing.dat");write(db,replace(read(c.database,String),r"(?m)^Fluorite\s*$"=>"Fluorite_REMOVED"))
        @test_throws CalculationError simulate(p,PHREEQCConfig(executable=c.executable,database=db);root)
    end
end
