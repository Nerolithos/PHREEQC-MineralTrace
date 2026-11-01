using MineralTrace
length(ARGS)==3 || error("Usage: julia --project=. scripts/robustness.jl DISCOVERY.toml ROBUSTNESS.toml OUTPUT_DIRECTORY")
s=load_discovery(ARGS[1]);plan=load_robustness(ARGS[2]);c=PHREEQCConfig()
r=discover_paths(s,c;root=ARGS[3]);report(r)
a=analyze_robustness(r,plan,c);println("Robustness report: ",report_robustness(r,a))
println("Actual formation order: undetermined; uncomputed space is not classified.")
any(x->x["computational_status"]!="success",a["candidates"]) && exit(1)
