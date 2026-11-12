# External measurement prediction challenge; database-calibration holdout qualification stays explicit.
using MineralTrace, SHA, TOML

function verify_holdout_freeze(project,config)
    base=joinpath(project,"data/validation/holdout-ferreira-2025")
    receipt=TOML.parsefile(joinpath(base,"FREEZE.toml"))
    for (file,expected) in receipt["files_sha256"]
        bytes2hex(sha256(read(joinpath(project,file))))==expected || error("Frozen input/source changed: $file; declare a new protocol, do not rebaseline")
    end
    env=environment_check(config)
    env.database_sha256==receipt["database_sha256"] || error("Frozen production database mismatch")
    bytes2hex(sha256(read(env.executable)))==receipt["executable_sha256"] || error("Frozen engine mismatch; a different engine is a separate comparison")
    receipt
end

function audited_holdout_endpoint(spec,config,root)
    r=calcite_endpoint(CalciteCO2Endpoint(spec),config;root)
    input=read(joinpath(r["archive"],"input.pqi"),String)
    input=replace(input," logf_CO2\n"=>" logf_CO2 pressure_atm ionic_strength la_Ca2 la_CO2\n")
    input=replace(input,"LA(\"CO2\")-LK_PHASE(\"CO2(g)\")"=>"LA(\"CO2\")-LK_PHASE(\"CO2(g)\"), PRESSURE, MU, LA(\"Ca+2\"), LA(\"CO2\")")
    direct=run_phreeqc(config,input;root,required=["pressure_atm","ionic_strength","ca_mol_kgw","n_Ca","n_C","n_H","n_O"],sources=["FERREIRA-2025-25C"],metadata=Dict("purpose"=>"extra telemetry, identical chemistry and solver settings"))
    row=only(filter(q->q["state"]=="react",direct.rows))
    all(k->abs(parse(Float64,row[k])-parse(Float64,r["selected"][k]))<1e-10,["ca_mol_kgw","n_Ca","n_C","n_H","n_O","pH","solid_Calcite","reservoir_CO2"]) || error("Instrumented replay changed endpoint")
    abs(parse(Float64,row["pressure_atm"])-spec["solution_pressure_bar"]/1.01325)<1e-8 || error("Actual aqueous pressure differs")
    r["selected"]=row;r["telemetry_archive"]=direct.directory;r
end

function validate_holdout(root="results";project=dirname(@__DIR__),config=PHREEQCConfig())
    frozen=verify_holdout_freeze(project,config);env=environment_check(config)
    protocol=TOML.parsefile(joinpath(project,"data/validation/holdout-ferreira-2025/PROTOCOL.toml"))
    observations=readlines(joinpath(project,"data/validation/holdout-ferreira-2025/observations.csv"))[2:end]
    length(observations)==5 || error("All five selected measurements required")
    mkpath(root);dir=abspath(mktempdir(root;prefix="external-holdout-",cleanup=false))
    cp(env.database,joinpath(dir,"database.dat"));cfg=PHREEQCConfig(executable=env.executable,database=joinpath(dir,"database.dat"))
    rows=Dict{String,Any}[];runs=Dict{String,Any}[]
    for line in observations
        v=split(line,',');id=v[1];T=parse(Float64,v[2])-273.15;p=parse(Float64,v[3])/100;obs=parse(Float64,v[4]);sd=parse(Float64,v[5]);u=parse(Float64,v[6]);base=nothing
        # All choices are frozen before predictions. They are controls, not a residual search.
        scenarios=[("primary",T,p,10.,10.,0.0317),("stock_upper",T,p,40.,10.,0.0317),("reservoir_upper",T,p,10.,20.,0.0317),("pressure_low",T,p-0.027,10.,10.,0.0317),("pressure_high",T,p+0.027,10.,10.,0.0317),("temperature_low",T-0.05,p,10.,10.,0.0317),("temperature_high",T+0.05,p,10.,10.,0.0317),("omit_vapor_pressure",T,p,10.,10.,0.)]
        controls=Dict{String,Any}[]
        for (name,temp,pc,stock,gas,vapor) in scenarios
            spec=Dict("temperature_c"=>temp,"solution_pressure_bar"=>pc+vapor,"pco2_bar"=>pc,"water_kg"=>1.,"calcite_g"=>stock,"co2_reservoir_mol"=>gas,"source_id"=>"FERREIRA-2025-25C","allow_unvalidated_conditions"=>true,"initial_recipe"=>"degassed_deionised_water_modelled_as_pure_water")
            r=audited_holdout_endpoint(spec,cfg,dir);r["point_id"]=id;r["scenario"]=name
            for key in ("archive","initialization_archive","telemetry_archive");r[key]=relpath(r[key],dir);end
            r["predicted_total_Ca_mmol_kg_water"]=1000*parse(Float64,r["selected"]["ca_mol_kgw"])
            push!(runs,r);push!(controls,r);name=="primary" && (base=r)
        end
        pred=base["predicted_total_Ca_mmol_kg_water"]
        push!(rows,Dict("id"=>id,"temperature_c"=>T,"pco2_kpa"=>p*100,"observed_total_Ca_mmol_kg_water"=>obs,"duplicate_sd_mmol_kg_water"=>sd,"reported_standard_u_mmol_kg_water"=>u,"predicted_total_Ca_mmol_kg_water"=>pred,"signed_error_mmol_kg_water"=>pred-obs,"signed_relative_error"=>(pred-obs)/obs,"control_min_mmol_kg_water"=>minimum(r["predicted_total_Ca_mmol_kg_water"] for r in controls),"control_max_mmol_kg_water"=>maximum(r["predicted_total_Ca_mmol_kg_water"] for r in controls),"pH_calculated"=>base["pH_prediction"],"pH_measured"=>nothing,"DIC_calculated_mmol_kg_water"=>1000*parse(Float64,base["selected"]["n_C"])/parse(Float64,base["selected"]["mass_H2O"]),"DIC_measured"=>nothing,"phi_CO2"=>base["gas_fugacity_coefficient"],"primary_archive"=>base["telemetry_archive"]))
    end
    stats=comparison_statistics([r["observed_total_Ca_mmol_kg_water"] for r in rows],[r["predicted_total_Ca_mmol_kg_water"] for r in rows])
    delete!(stats,"pointwise_experimental_uncertainty") # Replace generic UNKNOWN with the actually reported, separate sources below.
    stats["reported_standard_uncertainty_mmol_kg_water"]=0.15
    stats["duplicate_standard_deviation_mmol_kg_water"]=[r["duplicate_sd_mmol_kg_water"] for r in rows]
    stats["uncertainty_policy"]="No joint interval/weighted acceptance; duplicate SD, u(m), u(P), u(T), boundary idealization and numerical tolerance remain distinct"
    positives=count(r->r["signed_error_mmol_kg_water"]>0,rows);negatives=count(r->r["signed_error_mmol_kg_water"]<0,rows)
    stats["error_sign_counts"]=Dict("positive"=>positives,"negative"=>negatives,"zero"=>5-positives-negatives)
    payload=Dict("study_id"=>protocol["study_id"],"comparison_status"=>"external_experimental_prediction_completed","holdout_qualification"=>protocol["holdout_qualification"],"independent_of_REFLECT"=>true,"independent_of_database_calibration"=>"UNKNOWN","no_fitted_parameters"=>true,"experimental_validation_granted"=>false,"statistics"=>stats,"comparisons"=>rows,"runs"=>runs,"freeze_receipt"=>frozen,"database_audit"=>audit_database(cfg.database),"model_protocol"=>protocol)
    for file in ("src","scripts","data","Project.toml","Manifest.toml");cp(joinpath(project,file),joinpath(dir,file));end
    thesis=joinpath(project,"results/holdout-source-review/PENHA-2022.pdf")
    if isfile(thesis)
        cp(thesis,joinpath(dir,"PENHA-2022-source-review.pdf"))
    end
    write(joinpath(dir,"results.json"),MineralTrace.json_value(payload)*"\n")
    deterministic=deepcopy(payload)
    for r in deterministic["runs"]
        for key in ("archive","initialization_archive","telemetry_archive","manifest");delete!(r,key);end
    end
    for r in deterministic["comparisons"];delete!(r,"primary_archive");end
    write(joinpath(dir,"analysis.json"),MineralTrace.json_value(deterministic)*"\n")
    fields=["id","temperature_c","pco2_kpa","observed_total_Ca_mmol_kg_water","duplicate_sd_mmol_kg_water","reported_standard_u_mmol_kg_water","predicted_total_Ca_mmol_kg_water","signed_error_mmol_kg_water","signed_relative_error","control_min_mmol_kg_water","control_max_mmol_kg_water","pH_calculated","DIC_calculated_mmol_kg_water","phi_CO2"]
    open(joinpath(dir,"comparison.csv"),"w") do io
        println(io,join(fields,','));for r in rows;println(io,join([r[k] for k in fields],','));end
    end
    write(joinpath(dir,"reproduce.jl"),"include(joinpath(@__DIR__,\"scripts/validate_holdout.jl\"))\nvalidate_holdout(joinpath(@__DIR__,\"reproduced\");project=@__DIR__,config=PHREEQCConfig(database=joinpath(@__DIR__,\"database.dat\")))\n")
    holdout_report(dir,payload)
    println("External experiment report: ",joinpath(dir,"report.html"));dir
end

function holdout_report(dir,payload)
    rows=payload["comparisons"];X=p->80+650*(p-90)/140;Y=m->390-300*m/15
    svg=IOBuffer();print(svg,"<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 850 550'><rect width='100%' height='100%' fill='white'/><g font-family='sans-serif' fill='#23384a'><text x='80' y='30' font-size='20'>External Ca endpoint challenge · 25 °C · pure water</text><path d='M80 70 V390 H730' stroke='#333' fill='none'/>")
    for m in 0:3:15;print(svg,"<path d='M80 $(Y(m)) H730' stroke='#ddd'/><text x='50' y='$(Y(m)+5)'>$m</text>");end
    for p in (100,125,150,175,200,225);print(svg,"<text x='$(X(p)-10)' y='415'>$p</text>");end
    for r in rows
        x=X(r["pco2_kpa"]);o=r["observed_total_Ca_mmol_kg_water"];sd=r["duplicate_sd_mmol_kg_water"];pred=r["predicted_total_Ca_mmol_kg_water"]
        print(svg,"<circle cx='$x' cy='$(Y(o))' r='5' fill='#263b50'/><path d='M$x $(Y(o-sd)) V$(Y(o+sd)) M$(x-6) $(Y(o-sd)) H$(x+6) M$(x-6) $(Y(o+sd)) H$(x+6)' stroke='#263b50'/><rect x='$(x-5)' y='$(Y(pred)-5)' width='10' height='10' fill='#bb4b38'/>")
    end
    print(svg,"<text x='80' y='448'>pCO2 (kPa); vertical: total Ca as CaCO3-equivalent mmol/kg water</text><text x='80' y='477'>Black: published means ± duplicate SD · red: frozen PHREEQC prediction</text><text x='80' y='501'>Separate reported u(m)=0.15 mmol/kg; not combined with duplicate SD.</text><text x='80' y='531' font-size='11'>Ferreira et al. (2025), Table 3 · DOI 10.1021/acs.jced.4c00670 · CC BY 4.0 · data transcribed</text></g></svg>")
    plot=String(take!(svg));write(joinpath(dir,"comparison.svg"),plot)
    table=join(["<tr><td>$(r["id"])</td><td>$(r["pco2_kpa"])</td><td>$(r["observed_total_Ca_mmol_kg_water"])</td><td>$(r["duplicate_sd_mmol_kg_water"])</td><td>$(r["predicted_total_Ca_mmol_kg_water"])</td><td>$(r["signed_error_mmol_kg_water"])</td><td>$(100*r["signed_relative_error"])</td><td>$(r["control_min_mmol_kg_water"])–$(r["control_max_mmol_kg_water"])</td><td><a href='$(r["primary_archive"])/input.pqi'>deck</a></td></tr>" for r in rows])
    page="""<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>MineralTrace v0.8.1 independent-source experiment</title><style>body{max-width:1100px;margin:32px auto;padding:0 20px;font:15px/1.6 system-ui;color:#23384a}svg{width:100%;height:auto}table{border-collapse:collapse;width:100%;font-size:12px}td,th{padding:7px;border:1px solid #ccd3da}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#f1f5f7;padding:15px}.warning{border-left:5px solid #b87920;padding:12px;background:#fff4dd}</style><h1>Independent-source external experimental prediction</h1><p class="warning"><b>Comparison completed; strict database-calibration holdout qualification remains UNKNOWN.</b> This source is independent of REFLECT and no parameters were fitted in MineralTrace. Some related data were public in a 2022 thesis before later database revisions. Absence of a citation does not prove calibration independence; no experimental validation or strict-path qualification is granted.</p><p>OBSERVED: all five 298.15 K pure-water means from Ferreira et al. (2025), Table 3. AAS calcium in sampled, settled, acidified liquid is interpreted as reported solubility; a filtration cutoff was not specified. Duplicate SD and the separately reported standard uncertainties are retained. pH and DIC below are CALCULATED, with no independent measured endpoint values in this subset.</p>$plot<table><tr><th>Point</th><th>pCO2 kPa</th><th>Observed mmol/kg</th><th>Duplicate SD</th><th>Prediction</th><th>Signed error</th><th>Relative %</th><th>One-at-a-time controls min–max</th><th>Raw input</th></tr>$table</table><h2>Descriptive errors and uncertainty</h2><pre>$(MineralTrace.html(payload["statistics"]))</pre><p>Controls are not joint confidence intervals or model optimization. u(m)=0.15 mmol/kg, u(P)=2.7 kPa and u(T)=0.05 K are reported standard estimated uncertainties; duplicate SD uses n=2 and is not a new acceptance threshold. Numerical closure is checked separately. Model discrepancy and unverified experimental boundaries are not folded into a Gaussian validation score.</p><h2>Frozen model and boundaries</h2><pre>$(MineralTrace.html(payload["model_protocol"]))</pre><p>ASSUMED numerical water/solid/gas normalization is not an invented experimental loading. Excess solid and nonexhausted gas are checked; stock and reservoir controls quantify endpoint insensitivity. Actual pressure and ionic strength, Ca, DIC, pH and fugacity telemetry are in results.json. The pressure and temperature domains differ from REFLECT; no matched-condition cross-experiment causal inference is made.</p><h2>Sources, lineage and reproducibility</h2><p><a href="data/sources/FERREIRA-2025-PUBLISHER-TRANSCRIPT.txt">Primary-publisher retrieval transcript</a> · <a href="data/validation/holdout-ferreira-2025/SOURCE_AUDIT.md">Source/lineage audit</a> · <a href="data/validation/holdout-ferreira-2025/FREEZE.toml">Pre-prediction freeze receipt</a> · <a href="comparison.csv">All values</a> · <a href="analysis.json">Deterministic result</a> · <a href="results.json">Raw provenance</a></p><p>The transcript is not an original publisher PDF fingerprint. A related 2022 thesis is a source audit, not an independent second replication. Author-fitted Pitzer and OLI correlations were not used. Preserve source identities, all frozen files and engine settings.</p><pre>PHREEQC_EXECUTABLE=/absolute/path/to/phreeqc julia --project=. reproduce.jl</pre></html>"""
    write(joinpath(dir,"report.html"),page)
end
if abspath(PROGRAM_FILE)==@__FILE__
    # Package upgrades must not silently update the pre-prediction runtime.
    frozen_project=normpath(joinpath(@__DIR__,"../data/validation/frozen-v081"))
    output=isempty(ARGS) ? abspath("results") : abspath(ARGS[1])
    run(`$(Base.julia_cmd()) --startup-file=no --project=$frozen_project $(joinpath(frozen_project,"scripts/validate_holdout.jl")) $output`)
end
