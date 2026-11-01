using MineralTrace
if length(ARGS)!=2
    println(stderr,"Usage: julia --project=. scripts/titrate.jl PROCESS.toml OUTPUT_DIRECTORY");exit(2)
end
try
    p=load_process(ARGS[1]);r=simulate(p;root=ARGS[2]);println("Report: ",report(r))
    println("Status: ",r.provenance["status"])
    println("pH: ",[s["pH"] for s in r.steps])
    println("Charge diagnostics are conditional on initial analysis/specification; they are not universal quality standards.")
    any(s->!s["mass_balance_pass"]||!s["charge_conservation_pass"],r.steps) && exit(1)
catch e
    e isa InterruptException && rethrow();showerror(stderr,e);println(stderr);exit(1)
end
