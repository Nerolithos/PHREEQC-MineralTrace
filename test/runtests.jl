using Test, MineralTrace, TOML, SHA

@testset "Formation events and evidence DAG" begin
    a = FormationEvent("F-I", "Fluorite")
    b = FormationEvent("C-I", "Calcite")
    c = FormationEvent("F-II", "Fluorite")
    ev(x,y) = Evidence(x,y,:overgrowth; source="SYNTHETIC / SIMULATED", reliability="test fixture only", interpretation="assumed later overgrowth")
    g = EvidenceGraph([a,b,c],[ev(a.id,b.id)])
    r = analyze(g)
    @test r.determined == [(a.id,b.id)]
    @test Set(r.undetermined) == Set([(a.id,c.id),(b.id,c.id)])
    @test topological_order(EvidenceGraph([a,b,c],[ev(a.id,b.id),ev(b.id,c.id)])) == [a.id,b.id,c.id]
    @test (a.id,c.id) in analyze(EvidenceGraph([a,b,c],[ev(a.id,b.id),ev(b.id,c.id)])).determined
    loop = EvidenceGraph([a,b,c],[ev(a.id,b.id),ev(b.id,a.id),ev(b.id,c.id)])
    @test_throws CycleConflict analyze(loop)
    try
        analyze(loop)
    catch e
        @test length(e.evidence) == 2
        @test occursin("SYNTHETIC", sprint(showerror,e))
    end
    @test_throws CycleConflict analyze(EvidenceGraph([a],[ev(a.id,a.id)]))
    @test_throws ArgumentError EvidenceGraph([a,a],Evidence[])
    @test_throws ArgumentError EvidenceGraph([a],[ev(a.id,"missing")])
    @test_throws ArgumentError Evidence(a.id,b.id,:inclusion; source="", reliability="unknown", interpretation="test")
    @test isempty(analyze(EvidenceGraph(FormationEvent[],Evidence[])).order)
    @test isempty(analyze(EvidenceGraph([a,b],[ev(a.id,b.id),ev(a.id,b.id)])).undetermined)
end

@testset "Input units and dependency failures" begin
    f = FluidState(temperature_c=25,pH=7,totals=Dict("Ca"=>1e-3,"F"=>2e-3),label="SYNTHETIC / SIMULATED")
    @test occursin("units mol/kgw",solution_input(f))
    @test occursin("pressure 1",solution_input(f))
    @test_throws ArgumentError FluidState(temperature_c=100,pH=7,totals=f.totals,label=f.label)
    @test_throws ArgumentError FluidState(temperature_c=25,pH=NaN,totals=f.totals,label=f.label)
    @test_throws ArgumentError FluidState(temperature_c=25,pH=7,totals=Dict("Ca"=>-1.),label=f.label)
    @test_throws ArgumentError FluidState(temperature_c=25,pH=7,totals=Dict("Ca\nEND"=>1.),label=f.label)
    @test_throws DependencyError environment_check(PHREEQCConfig(executable="/nonexistent/mineraltrace-phreeqc"))
    @test_throws DependencyError environment_check(PHREEQCConfig(executable=joinpath(Sys.BINDIR,"julia"),database="/nonexistent/database"))
end

@testset "Selected output integrity (synthetic parser fixtures)" begin
    mktempdir() do d
        p = joinpath(d,"selected.tsv")
        @test_throws ArgumentError read_selected(p)
        write(p,"si_Calcite pH\n0.1 7.0\n")
        @test read_selected(p;required=["si_Calcite"])[1]["pH"] == "7.0"
        @test_throws ArgumentError read_selected(p;required=["si_Fluorite"])
        for text in ("a b\n1\n", "a a\n1 2\n", "a\n", "a\nNaN\n", "a\n-999.999\n")
            write(p,text)
            @test_throws ArgumentError read_selected(p;required=["a"])
        end
    end
end

include("exploration_unit.jl")
include("constraints.jl")
include("process_unit.jl")
include("pathways_unit.jl")
include("discovery_unit.jl")
include("credibility_unit.jl")
include("model_profiles.jl")
include("cross_study.jl")

if get(ENV,"MINERALTRACE_INTEGRATION","0") == "1"
    include("v071_attribution.jl")
    include("integration.jl")
    include("cafc.jl")
    include("exploration.jl")
    include("validation_v3.jl")
    include("process_integration.jl")
    include("pathways_integration.jl")
    include("discovery_integration.jl")
    include("credibility_integration.jl")
    include("model_profiles_integration.jl")
    include("upstream_reference.jl")
    include("holdout_integration.jl")
else
    @info "Real PHREEQC integration NOT RUN. Set MINERALTRACE_INTEGRATION=1 and configure executable/database."
end

@testset "CLI failure archives (process fixtures, no chemistry)" begin
    mktempdir() do d
        db = joinpath(d,"unused database.dat")
        write(db,"# SYNTHETIC process-test placeholder; never used for chemistry\n")
        exe = joinpath(d,"process fixture")
        for (body, message) in (("exit 7", "code 7"), ("exit 0", "raw output missing"), ("exec /bin/sleep 3", "timeout"))
            write(exe,"#!/bin/sh\n$body\n")
            chmod(exe,0o755)
            c = PHREEQCConfig(executable=exe,database=db,timeout_seconds=(message == "timeout" ? 0.2 : 5.0))
            try
                run_phreeqc(c,"# process fixture only";root=d)
                @test false
            catch e
                @test e isa CalculationError
                @test occursin(message,sprint(showerror,e))
                @test isfile(joinpath(e.directory,"input.pqi"))
                @test TOML.parsefile(joinpath(e.directory,"manifest.toml"))["status"] == "failed"
            end
        end
    end
end
