@testset "Real all-phase environmental discovery and sensitivity" begin
    spec=TOML.parsefile(joinpath(@__DIR__,"../examples/discovery.toml"))
    spec["search"]["allowed_processes"]=["equilibrium","cooling","NaOH"]
    for g in spec["grids"]
        g["titrant_amounts_mol"]=[0.001,0.009]
        g["role"]=="resolution" && (g["initial_values"]["pH"]=[2.,2.1])
    end
    s=DiscoveryStudy(spec);config=PHREEQCConfig();root=joinpath(@__DIR__,"../results");r=discover_paths(s,config;root)
    @test all(c->c["computational_status"]=="success",r.candidates)
    @test Set(c["screening"]["classification"] for c in r.candidates)==Set(["compatible","incompatible","undetermined"])
    @test all(c->c["screening"]["formation_order_classification"]=="undetermined" && !c["screening"]["observed_formation_confirmed_by_model"],r.candidates)
    @test all(c->all(p->p["accounting"]["mass_pass"] && p["accounting"]["charge_pass"] && p["direction_pass"],c["steps"]),r.candidates)
    @test all(c->all(p->p["index"]==0 || Set(p["active_phases"])==Set(spec["minerals"]),c["steps"]),r.candidates)
    @test any(g->length(g["candidate_ids"])>1,r.groups)
    @test length(r.sensitivity)==2
    refined=only(q for q in r.sensitivity if q["comparison"]["role"]=="resolution")
    ranged=only(q for q in r.sensitivity if q["comparison"]["role"]=="range")
    @test isempty(refined["removed_candidate_ids"])
    @test !isempty(refined["added_candidate_ids"])
    @test ranged["comparison"]["classification_counts"]["compatible"]==0
    @test ranged["baseline"]["classification_counts"]["compatible"]>0
    @test !isempty(ranged["lost_qualitative_signatures"])
    # An independent temporal edge does not drive generation or engine inputs.
    reverse=deepcopy(spec);reverse["evidence"][1]["earlier"]="C-I";reverse["evidence"][1]["later"]="F-I"
    reversed_study=DiscoveryStudy(reverse)
    compatible=first(c for c in r.candidates if c["screening"]["classification"]=="compatible")
    @test MineralTrace.screen_discovered(reversed_study,compatible)["classification"]=="incompatible"
    @test r.study.spec["evidence"]==spec["evidence"]
    @test all(p->p["phase_transfers"]["Calcite"]["active"] && p["phase_transfers"]["Fluorite"]["active"],compatible["steps"][2:end])
    @test compatible["screening"]["automatic_proxy_positions"]["F-I"]<compatible["screening"]["automatic_proxy_positions"]["C-I"]
    # Replay one discovered candidate in the direct CLI with its OWN state dumps.
    previous=nothing;maxdelta=0.
    for step in compatible["steps"]
        direct=abspath(mktempdir(root;prefix="discovery-direct-",cleanup=false))
        cp(joinpath(r.directory,step["archive"],"input.pqi"),joinpath(direct,"input.pqi"));cp(config.database,joinpath(direct,"database.dat"))
        previous!==nothing && cp(previous,joinpath(direct,"previous.dmp"))
        open(joinpath(direct,"console.log"),"w") do io
            run(pipeline(Cmd(Cmd([environment_check(config).executable,"input.pqi","output.pqo","database.dat"]);dir=direct);stdin=devnull,stdout=io,stderr=io))
        end
        lines=filter(x->!isempty(strip(x)),readlines(joinpath(direct,"selected.tsv")));row=Dict(zip(split(lines[1]),split(only(lines[2:end]))))
        for key in vcat(["pH","temp","charge","solid_Fluorite","solid_Calcite"],["n_$e" for e in MineralTrace.PROCESS_ELEMENTS])
            maxdelta=max(maxdelta,abs(parse(Float64,row[key])-parse(Float64,step["selected"][key])))
        end
        previous=joinpath(direct,"state.dmp")
    end
    @test maxdelta<1e-10
    # Every state handoff is linked to the actual previous engine dump.
    handoffs=0
    for c in r.candidates,i in 2:length(c["steps"])
        p=c["steps"][i];prev=c["steps"][i-1]
        manifest=TOML.parsefile(joinpath(r.directory,p["archive"],"manifest.toml"))
        @test manifest["auxiliary_sha256"]["previous.dmp"]==prev["state_sha256"]
        input=read(joinpath(r.directory,p["archive"],"input.pqi"),String)
        @test occursin("EQUILIBRIUM_PHASES 1",input) && occursin("Fluorite",input) && occursin("Calcite",input)
        @test !occursin(r"(?m)^\s*pH\s",input)
        handoffs+=1
    end
    path=report(r);text=read(path,String)
    @test occursin("Actual mineral crystallization order remains undetermined",text)
    @test occursin("Range and discretization sensitivity",text)
    @test !occursin("<script",text)
    @test all(f->isfile(joinpath(r.directory,f)),["candidates.csv","steps.csv","balances.csv","analysis.json","sensitivity.json","response-groups.json","generated-candidates.toml","reproduce.jl"])
    write(joinpath(@__DIR__,"../data/validation/DISCOVERY_ENGINE_COMPARISON.md"),"# Direct-engine discovery comparison\n\nA discovered compatible-surrogate candidate was replayed directly through PHREEQC with its own preceding full solution dumps. Maximum absolute difference over pH, temperature, charge, all seven element inventories and both solid stocks: $maxdelta. All $handoffs saved-state handoffs in $(length(r.candidates)) candidates were checked by SHA-256; both phases were simultaneously accessible at every reaction step.\n\nThis validates engine/state consistency only, not experimental accuracy, nucleation or actual chronology. Workspace: $(r.directory). Database SHA-256: $(r.provenance["database_sha256"]).\n")
end
