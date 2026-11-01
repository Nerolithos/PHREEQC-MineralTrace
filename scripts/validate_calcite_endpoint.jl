using MineralTrace, TOML, SHA
project=isfile(joinpath(@__DIR__,"Project.toml")) ? (@__DIR__) : dirname(@__DIR__)
root=length(ARGS)>0 ? ARGS[1] : joinpath(project,"results")
c=isfile(joinpath(project,"database.dat")) ? PHREEQCConfig(database=joinpath(project,"database.dat")) : PHREEQCConfig();env=environment_check(c)
expected="59373961d648dfbf68a40744060c1d64f57ecbec98f4f5fb89f3a1b4213ccd10"
env.database_sha256==expected || error("Predeclared endpoint challenge requires the locked unmodified database")
observations=joinpath(project,"data/validation/reflect-2023/observations.csv")
bytes2hex(sha256(read(observations)))=="2e8df44966f958f0959c4f252124e8a0b55c5b4b3e4889a5799a328a0d12d805" || error("Frozen observation file changed; declare a new protocol rather than rebaseline")
mkpath(root);dir=abspath(mktempdir(root;prefix="calcite-validation-",cleanup=false))
for file in ("src","Project.toml","Manifest.toml","data");cp(joinpath(project,file),joinpath(dir,file));end
cp(env.database,joinpath(dir,"database.dat"))
c=PHREEQCConfig(executable=env.executable,database=joinpath(dir,"database.dat"),timeout_seconds=c.timeout_seconds)
points=[split(line,',') for line in readlines(observations)[2:end]]
comparisons=Dict{String,Any}[];runs=Dict{String,Any}[]
for p in points
    id=p[1];T=parse(Float64,p[2]);pressure=parse(Float64,p[3]);measured=parse(Float64,p[4]);base=nothing;controls=Dict{String,Any}[]
    # Primary prediction plus independent stock/reservoir and stated pressure/temperature uncertainty controls.
    scenarios=[("primary",T,pressure,10.,10.),("stock_upper",T,pressure,40.,10.),("reservoir_upper",T,pressure,10.,20.),("pressure_low",T,pressure-0.7,10.,10.),("pressure_high",T,pressure+0.7,10.,10.),("temperature_low",T-0.1,pressure,10.,10.),("temperature_high",T+0.1,pressure,10.,10.)]
    for (name,temp,pc,stock,gas) in scenarios
        e=CalciteCO2Endpoint(Dict("temperature_c"=>temp,"solution_pressure_bar"=>pc+0.03,"pco2_bar"=>pc,"water_kg"=>0.8,"calcite_g"=>stock,"co2_reservoir_mol"=>gas,"source_id"=>"REFLECT-D23-2023","allow_unvalidated_conditions"=>true,"initial_recipe"=>"degassed_deionised_water_modelled_as_pure_water"))
        r=calcite_endpoint(e,c;root=dir);r["point_id"]=id;r["scenario"]=name
        r["archive"]=relpath(r["archive"],dir);r["initialization_archive"]=relpath(r["initialization_archive"],dir)
        push!(runs,r);push!(controls,r);name=="primary" && (base=r)
    end
    for basis in ("water","solution")
        key="solubility_g_per_kg_$basis";predicted=base[key]
        push!(comparisons,Dict("id"=>id,"temperature_c"=>T,"pco2_bar"=>pressure,"mass_basis"=>basis,"measured_digitized_g_per_kg"=>measured,"predicted_g_per_kg"=>predicted,"signed_error_g_per_kg"=>predicted-measured,"relative_error_percent"=>100*(predicted-measured)/measured,"digitization_bound_g_per_kg"=>0.03,"per_point_experimental_uncertainty"=>nothing,"primary_archive"=>base["archive"],"control_prediction_min"=>minimum(r[key] for r in controls),"control_prediction_max"=>maximum(r[key] for r in controls)))
    end
end
payload=Dict("comparison_scope"=>"independent digitized equilibrium endpoint challenge, not complete run reconstruction or time-path validation","fitted_parameters"=>Any[],"comparisons"=>comparisons,"runs"=>runs)
write(joinpath(dir,"results.json"),MineralTrace.json_value(payload)*"\n")
deterministic=deepcopy(payload)
for row in deterministic["comparisons"];delete!(row,"primary_archive");end
for row in deterministic["runs"]
    for key in ("archive","initialization_archive","manifest");delete!(row,key);end
end
deterministic["provenance"]=Dict{String,Any}("database_sha256"=>env.database_sha256,"executable_sha256"=>bytes2hex(sha256(read(env.executable))),"observation_sha256"=>bytes2hex(sha256(read(observations))),"source_pdf_sha256"=>bytes2hex(sha256(read(joinpath(project,"data/sources/REFLECT-D23-2023.pdf")))),"script_sha256"=>bytes2hex(sha256(read(@__FILE__))),"package_version"=>string(pkgversion(MineralTrace)),"julia_version"=>string(VERSION))
deterministic["provenance"]["protocol_sha256"]=bytes2hex(sha256(read(joinpath(project,"data/sources/REFLECT-D23-2023.json"))))
deterministic["provenance"]["source_sha256"]=Dict(relpath(joinpath(folder,f),project)=>bytes2hex(sha256(read(joinpath(folder,f)))) for (folder,_,files) in walkdir(joinpath(project,"src")) for f in files)
write(joinpath(dir,"analysis.json"),MineralTrace.json_value(deterministic)*"\n")
open(joinpath(dir,"comparison.csv"),"w") do io
    println(io,"id,temperature_c,pco2_bar,mass_basis,measured_digitized_g_per_kg,predicted_g_per_kg,signed_error_g_per_kg,relative_error_percent,digitization_bound_g_per_kg,per_point_experimental_uncertainty,control_prediction_min,control_prediction_max")
    for q in comparisons
        println(io,join([q["id"],q["temperature_c"],q["pco2_bar"],q["mass_basis"],q["measured_digitized_g_per_kg"],q["predicted_g_per_kg"],q["signed_error_g_per_kg"],q["relative_error_percent"],0.03,"not reported",q["control_prediction_min"],q["control_prediction_max"]],','))
    end
end
rows=join(["<tr><td>$(q["id"])</td><td>$(q["pco2_bar"])</td><td>$(q["mass_basis"])</td><td>$(q["measured_digitized_g_per_kg"])</td><td>$(q["predicted_g_per_kg"])</td><td>$(q["relative_error_percent"])</td><td>$(q["control_prediction_min"]) – $(q["control_prediction_max"])</td></tr>" for q in comparisons])
# Plot individual measured points and predictions; no measured path or interpolated phase boundary is invented.
svg=IOBuffer();print(svg,"<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 850 480'><rect width='100%' height='100%' fill='white'/><g font-family='sans-serif' fill='#23384a'><text x='70' y='28' font-size='20'>Independent calcite endpoints · 24 °C, pure-water recipe</text><path d='M70 60 V360 H780' stroke='#333' fill='none'/>")
X=p->70+710*p/55;Y=v->360-280*v/4
for v in 0.:1.:4.;print(svg,"<text x='45' y='$(Y(v)+4)'>$v</text><path d='M70 $(Y(v)) H780' stroke='#ddd'/>");end
for p in 0.:10.:50.;print(svg,"<text x='$(X(p))' y='385'>$p</text>");end
for q in comparisons
    x=X(q["pco2_bar"])
    if q["mass_basis"]=="water"
        y=Y(q["measured_digitized_g_per_kg"]);print(svg,"<circle cx='$x' cy='$y' r='5' fill='#242d35'/><path d='M$(x-7) $(Y(q["measured_digitized_g_per_kg"]-0.03)) H$(x+7) M$x $(Y(q["measured_digitized_g_per_kg"]-0.03)) V$(Y(q["measured_digitized_g_per_kg"]+0.03)) M$(x-7) $(Y(q["measured_digitized_g_per_kg"]+0.03)) H$(x+7)' stroke='#242d35'/>")
    end
    color=q["mass_basis"]=="water" ? "#b34e34" : "#197b9d";y=Y(q["predicted_g_per_kg"])
    print(svg,"<rect x='$(x-4)' y='$(y-4)' width='8' height='8' fill='$color'/>")
end
print(svg,"<text x='70' y='410'>CO2 partial pressure (bar); vertical axis: CaCO3-equivalent g/kg</text><text x='70' y='436'>Black: digitized measurements ± extraction bound only · red: kg water · blue: kg solution</text><text x='70' y='464' font-size='11'>Measurements: Tjelta et al. (2023), REFLECT D2.3 Fig.22 · DOI 10.48440/gfz.4.8.2023.001 · CC BY 4.0, digitized</text></g></svg>")
plot=String(take!(svg));write(joinpath(dir,"comparison.svg"),plot)
html="""<!doctype html><html><meta charset="utf-8"><title>Independent calcite endpoint challenge</title><style>body{max-width:1100px;margin:35px auto;padding:0 20px;font:16px/1.5 system-ui;color:#23384a}table{width:100%;border-collapse:collapse;font-size:12px}td,th{padding:7px;border:1px solid #ccc}svg{width:100%}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#f1f5f7;padding:16px}</style><h1>Independent calcite endpoint challenge</h1><p>Original REFLECT D2.3 (2023), DOI 10.48440/gfz.4.8.2023.001. All five measured 24 °C, 0 wt% NaCl markers from Figure 22 were digitized and frozen before predictions. No thermodynamic parameter was fitted.</p><p><strong>This is a bounded endpoint comparison, not full experimental reconstruction, whole-path, rate, pH or formation-order validation.</strong> The g/kg basis and exact per-point solid loading are not specified. Both mass normalizations and the reported solid-loading range are retained. Per-point uncertainty is missing; extraction bounds and general method precision are separate.</p>$plot<table><tr><th>Point</th><th>pCO2 bar</th><th>kg basis</th><th>Measured g/kg (digitized)</th><th>Prediction</th><th>Signed error %</th><th>Declared controls min–max</th></tr>$rows</table><p>Controls: stock 10–40 g, numerical gas buffer 10–20 mol, pCO2 ±0.7 bar and T ±0.1 °C. They are individual controls, not a statistical joint confidence interval. Actual nonexhaustion, elemental inventories and charge are checked in each calculation. A numerical buffer is not the measured headspace amount.</p><p>pH is predicted only; no measured pH or mineral weight change is invented. EDTA measures total dissolved calcium, not just free Ca2+. Reservoir exchange is included in C/O accounting. Initial pure-water charge neutralization affects only model water, not measured ion concentrations. Main discovery remains no-gas; this narrow fixed-pCO2 endpoint profile is separate.</p><p><a href="comparison.csv">All signed errors</a> · <a href="results.json">Raw calculations, balances and provenance</a> · <a href="data/sources/REFLECT-D23-2023.pdf">Original CC-BY source</a> · <a href="data/sources/REFLECT-D23-2023.json">Predeclared protocol and limits</a></p><pre>$(MineralTrace.html(read(joinpath(project,"data/validation/reflect-2023/PROTOCOL.md"),String)))</pre></html>"""
write(joinpath(dir,"report.html"),html)
cp(@__FILE__,joinpath(dir,"validate_calcite_endpoint.jl"))
write(joinpath(dir,"reproduce.jl"),"include(joinpath(@__DIR__,\"validate_calcite_endpoint.jl\"))\n")
# The script works both under scripts/ and in an exported folder.
println("Report: ",joinpath(dir,"report.html"))
println("Model disagreement is reported, never converted to a passing calibration test.")
