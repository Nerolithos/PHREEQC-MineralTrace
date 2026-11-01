using MineralTrace
usage="""
MineralTrace — Mineral Formation Constraint Explorer
Usage:
  julia --project=. scripts/mineraltrace.jl --check STUDY.toml
  julia --project=. scripts/mineraltrace.jl STUDY.toml OUTPUT_DIRECTORY

Edit only a TOML configuration, not Julia source. See examples/fluorite_calcite.toml.
Set PHREEQC_EXECUTABLE and PHREEQC_DATABASE for a genuine calculation.
"""
if ARGS == ["--help"] || isempty(ARGS)
    println(usage); exit(isempty(ARGS) ? 2 : 0)
end
if length(ARGS) != 2
    println(stderr,usage);exit(2)
end
try
    if ARGS[1] == "--check"
        study=load_study(ARGS[2])
        println("Valid study: ",study.spec["mode"],"; ",prod(length(a["values"]) for a in study.spec["axes"])," sample points; units and bounds checked.")
        println("Validation does not certify chemistry or database applicability.")
        exit(0)
    end
    study=load_study(ARGS[1])
    result=scan(study;root=ARGS[2])
    println("Report: ",report(result))
    println("Counts: ",MineralTrace.scan_summary(result))
    println("Final evaluation: ",MineralTrace.feasibility_summary(result))
    println("Raw SI compatibility is separate from chemical admissibility and final inclusion; review all reasons.")
    any(p->p["status"]=="failed",result.samples) && exit(1)
catch e
    e isa InterruptException && rethrow()
    showerror(stderr,e); println(stderr); exit(1)
end
