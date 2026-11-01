using MineralTrace
fluid = FluidState(temperature_c=25,pH=7,
    totals=Dict("Ca"=>1e-3,"F"=>2e-3,"C(4)"=>1e-3,"Na"=>1e-3),
    label="SYNTHETIC / SIMULATED; chosen demonstration totals, not measured")
result = forward(PHREEQCConfig(),fluid;root=joinpath(@__DIR__,"../results"))
println("Calculation archive: ",result.directory)
println(result.rows)
println("Status: ",result.manifest["status"])
foreach(w -> println("WARNING: ",w), result.manifest["warnings"])
println("Activities are log10 activities (la_*); SI > 0 does not imply precipitation.")
println("This calculation does not establish a formation environment or geological history.")
