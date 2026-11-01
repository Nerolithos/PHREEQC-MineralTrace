# Direct CLI reference capture, deliberately bypassing run_phreeqc/its parser.
using MineralTrace, TOML, SHA
c=PHREEQCConfig(); env=environment_check(c)
root=joinpath(@__DIR__,"../data/validation")
original=read(joinpath(root,"usgs-ex1.pqi"),String)
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
dir=abspath(mktempdir(joinpath(@__DIR__,"../results");prefix="example1-direct-",cleanup=false))
write(joinpath(dir,"input.pqi"),input); cp(env.database,joinpath(dir,"database.dat"))
cmd=Cmd(Cmd([env.executable,"input.pqi","output.pqo","database.dat"]);dir)
open(joinpath(dir,"console.log"),"w") do io
    run(pipeline(cmd;stdin=devnull,stdout=io,stderr=io))
end
# Standalone splitting here is independent of adapter read_selected.
lines=readlines(joinpath(dir,"selected.tsv")); heads=split(lines[1]); vals=parse.(Float64,split(lines[2])); direct=Dict(zip(heads,vals))
res=run_phreeqc(c,input;root=joinpath(@__DIR__,"../results"),required=["si_Calcite","si_Gypsum","si_Anhydrite"],sources=["USGS-EX1-TABLE11"])
reference=TOML.parsefile(joinpath(root,"ex1-reference.toml"))
reg=Dict{String,Any}("description"=>"Current engine regression, captured by direct CLI; not independent scientific validation", "database_sha256"=>env.database_sha256,"engine_sha256"=>bytes2hex(sha256(read(env.executable))),"input_sha256"=>bytes2hex(sha256(codeunits(input))),"absolute_tolerance"=>1e-10,"direct_archive"=>relpath(dir,dirname(root)),"si"=>Dict(m=>direct["si_$m"] for m in keys(reference["si"])))
# Never silently replace a baseline. A deliberate new file is needed to rebaseline.
path=joinpath(root,"ex1-current-engine.toml")
isfile(path) && error("Regression baseline already exists; refusing to overwrite $path")
open(io->TOML.print(io,reg),path,"w")
rows=String[]
for m in sort(collect(keys(reference["si"])))
    actual=direct["si_$m"]; expected=reference["si"][m]; delta=actual-expected
    push!(rows,"| $m | $expected | $actual | $delta | $(abs(delta)) | $(abs(delta)/abs(expected)) | $(parse(Float64,res.rows[1]["si_$m"])-actual) |")
end
raw=read(joinpath(dir,"output.pqo"),String)
phase_lines=filter(l->occursin(r"^\s*(Calcite|Gypsum|Anhydrite)\s+[-0-9]",l),split(raw,'\n'))
text="""# Example 1 discrepancy investigation — 2026-11-01

## Reproduced comparison

Official historical reference: [USGS Example 1, table 11](https://water.usgs.gov/water-resources/software/PHREEQC/documentation/phreeqc3-html/phreeqc3-63.htm).

| Phase | Historical SI | Direct current CLI SI | Signed Δ | Absolute Δ | Relative absolute Δ / abs(reference) | Adapter minus direct CLI |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
$(join(rows,"\n"))

Relative SI error is listed as requested, but SI is logarithmic; it is not a concentration error or statistical uncertainty.

## Checks actually performed

- Official release 3.8.6-17100 example deck is retained byte-for-byte in usgs-ex1.pqi. Input temperature 25 °C, pH 8.22, pe 8.451, density 1.023, ppm units and redox coupling agree with the documented deck on inspection. No charge adjustment was added.
- Only SELECTED_OUTPUT was inserted before END; output columns are explicitly si_Calcite, si_Gypsum and si_Anhydrite, not molality or log activity.
- This script ran the executable directly, then independently split SELECTED_OUTPUT; it also ran the same deck through the adapter. The last column above measures their difference.
- Historical table is rounded to 0.01 SI units. Original tolerance 0.01 remains unchanged; the observed differences exceed rounding precision.
- Current database SHA-256: $(env.database_sha256). Direct input SHA-256: $(reg["input_sha256"]). Engine banner and full output are in the raw archives.
- Current raw SI table (SI, log IAP, log K):

```
$(join(phase_lines,"\n"))
```

The historical table lists Calcite log K -8.48, Gypsum -4.58, Anhydrite -4.28. Current raw output contains effective log K and log IAP values differing from the historical table; temperature expressions and aqueous activity parameters are plausible contributors. **The exact causal parameter has not been isolated.** The exact database snapshot and executable behind the historical web table have not been obtained, so a version mismatch is a hypothesis, not an established explanation.

## Separate validation tracks

1. Historical Reference Test: scripts/benchmark.jl retains the original values and fails visibly when outside 0.01; no tolerances were broadened.
2. Current Engine Regression Test: ex1-current-engine.toml was captured directly from this locked binary/database. Adapter output is checked against it, with exact database and input hashes. A changed binary hash is disclosed; a changed database hash fails the locked test. This checks stability and adapter behavior, not independent scientific truth.
3. Ca–F–C tests independently check element balances, SI identity using engine-reported activities/log K, concentration/pH trends and temperature response. They are consistency tests, not experimental calibration.

Direct raw archive: $(relpath(dir,abspath(joinpath(@__DIR__,"..")))). Adapter raw archive: $(relpath(res.directory,abspath(joinpath(@__DIR__,"..")))). Both remain available in results locally.

The investigation is bounded to this release and the documented historical values. Remaining task: obtain an explicitly matched historical engine/database reference, then isolate changes without mixing databases.
"""
write(joinpath(root,"EXAMPLE1_INVESTIGATION.md"),text)
println(path)
