using MineralTrace
if length(ARGS)!=2
    println(stderr,"Usage: julia --project=. scripts/paths.jl PATHS.toml OUTPUT_DIRECTORY");exit(2)
end
try
    study=load_paths(ARGS[1]);result=compare_paths(study;root=ARGS[2]);println("Report: ",report(result))
    for p in result.candidates
        println(p["id"],": ",p["compatibility"]["classification"],"; ",p["compatibility"]["qualification"])
    end
    any(p->p["computational_status"]!="success",result.candidates) && exit(1)
catch e
    e isa InterruptException && rethrow();showerror(stderr,e);println(stderr);exit(1)
end
