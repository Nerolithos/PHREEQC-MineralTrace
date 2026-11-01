using MineralTrace
if length(ARGS)!=2
    println(stderr,"Usage: julia --project=. scripts/discover.jl DISCOVERY.toml OUTPUT_DIRECTORY");exit(2)
end
try
    study=load_discovery(ARGS[1]);result=discover_paths(study;root=ARGS[2]);println("Report: ",report(result))
    for label in ("compatible","incompatible","undetermined")
        println(label," (conditional equilibrium surrogate): ",count(c->c["screening"]["classification"]==label,result.candidates))
    end
    println("Actual formation chronology: undetermined; no unique history inferred.")
    any(c->c["computational_status"]!="success",result.candidates) && exit(1)
catch e
    e isa InterruptException && rethrow();showerror(stderr,e);println(stderr);exit(1)
end
