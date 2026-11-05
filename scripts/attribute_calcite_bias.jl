# Frozen-observation, one-choice-at-a-time endpoint diagnostics. No fitting or discovery extension.
using MineralTrace, SHA, TOML
const OBS_HASH = "2e8df44966f958f0959c4f252124e8a0b55c5b4b3e4889a5799a328a0d12d805"
const BASE_HASH = "59373961d648dfbf68a40744060c1d64f57ecbec98f4f5fb89f3a1b4213ccd10"

function diagnostic_databases(base, pitzer, dest)
    bytes2hex(sha256(read(base))) == BASE_HASH || error("Locked baseline database required")
    bytes2hex(sha256(read(pitzer))) == "06ab2debc0cdb333598118df953165499c2f762a79de5f2df55dec6b78b02589" || error("Locked USGS Pitzer database required")
    text=read(base,String)
    # Remove only the CO2 critical-property block. Henry/Calcite constants are untouched.
    block=match(r"(?ms)^CO2\(g\)\n.*?(?=^H2O\(g\))",text)
    isnothing(block) && error("Expected CO2 block missing")
    ideal=replace(block.match,r"(?m)^\s*-(?:T_c|P_c|Omega)[^\n]*\n"=>"")
    count(occursin.(Ref(r"(?m)^\s*-(?:T_c|P_c|Omega)"),split(block.match,'\n')))==3 || error("Unexpected CO2 EOS schema")
    write(joinpath(dest,"ideal-co2.dat"),replace(text,block.match=>ideal;count=1))
    # Isolate a declared charged-ion activity choice, preserving all constants/species and neutral gamma.
    ions=Set(["H+","OH-","Ca+2","HCO3-","CO3-2","CaHCO3+","CaOH+"])
    lines=split(text,'\n'); active="";removed=String[];out=String[];in_species=false
    for line in lines
        strip(line)=="SOLUTION_SPECIES" && (in_species=true)
        strip(line)=="PHASES" && (in_species=false)
        plain=strip(first(split(line,'#')))
        if in_species && occursin('=',plain)
            active=strip(last(split(plain,'=')))
        end
        if in_species && active in ions && occursin(r"^-gamma\s",plain)
            push!(removed,active);continue
        end
        push!(out,line)
    end
    isempty(removed) && error("No charged-ion activity parameters found")
    write(joinpath(dest,"davies-ions.dat"),join(out,'\n'))
    cp(base,joinpath(dest,"phreeqc.dat"));cp(pitzer,joinpath(dest,"pitzer.dat"))
    Dict("davies_ions_with_removed_gamma"=>sort(unique(removed)),"ideal_removed_properties"=>["T_c","P_c","Omega"])
end

function attribution_input(e, stock; pressure_atm=nothing)
    input=MineralTrace.endpoint_input(e)
    # Instrument actual solution pressure, ionic strength, activities and pressure-adjusted constants.
    input=replace(input," logf_CO2\n"=>" logf_CO2 pressure_atm ionic_strength gamma_Ca gamma_HCO3 lk_Calcite lk_CO2\n")
    input=replace(input,"LA(\"CO2\")-LK_PHASE(\"CO2(g)\")"=>"LA(\"CO2\")-LK_PHASE(\"CO2(g)\"), PRESSURE, MU, 10^(LA(\"Ca+2\")-LM(\"Ca+2\")), 10^(LA(\"HCO3-\")-LM(\"HCO3-\")), LK_PHASE(\"Calcite\"), LK_PHASE(\"CO2(g)\")")
    p=isnothing(pressure_atm) ? e.spec["solution_pressure_bar"]/1.01325 : pressure_atm
    input*"\nREACTION_PRESSURE 1\n $p\nEQUILIBRIUM_PHASES 1\n Calcite 0 $stock\n CO2(g) $(log10(e.spec["pco2_bar"]/1.01325)) 10\nSAVE solution 1\nSAVE equilibrium_phases 1\nDUMP\n -file state.dmp\n -solution 1\n -equilibrium_phases 1\nEND\n"
end


function attribution_report(dir, results, scenarios)
    colors=["#152f46","#c43d32","#bc7700","#16845d","#774ca1","#64748b","#0083a8"]
    svg=IOBuffer();print(svg,"<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 980 760'><rect width='100%' height='100%' fill='white'/><g font-family='sans-serif' fill='#23384a'><text x='65' y='30' font-size='20'>REFLECT frozen endpoints: controlled model sensitivities</text>")
    for (panel,basis) in enumerate(("water","solution"))
        x0=panel==1 ? 65 : 545;y0=70;w=365;h=390
        X=p->x0+w*p/55;Y=v->y0+h-h*(v+5)/60
        print(svg,"<text x='$x0' y='58'>Signed discrepancy (%) · kg $basis</text><path d='M$x0 $y0 V$(y0+h) H$(x0+w)' stroke='#222' fill='none'/>")
        for y in 0:10:50
            print(svg,"<path d='M$x0 $(Y(y)) H$(x0+w)' stroke='#ddd'/><text x='$(x0-30)' y='$(Y(y)+4)'>$y</text>")
        end
        for p in 0:10:50;print(svg,"<text x='$(X(p)-7)' y='$(y0+h+22)'>$p</text>");end
        for (k,(name,_,_)) in enumerate(scenarios),r in results
            r["scenario"]==name || continue
            print(svg,"<circle cx='$(X(r["pco2_bar"]))' cy='$(Y(100*r["delta_$basis"]))' r='4' fill='$(colors[k])'/>")
        end
        print(svg,"<text x='$x0' y='510'>pCO2 (bar); points only, no interpolated curve</text>")
    end
    for (k,(name,_,_)) in enumerate(scenarios)
        y=535+24*k;print(svg,"<circle cx='70' cy='$y' r='4' fill='$(colors[k])'/><text x='85' y='$(y+5)' font-size='14'>$name</text>")
    end
    print(svg,"<text x='65' y='742' font-size='12'>REFLECT D2.3 Fig.22 · DOI 10.48440/gfz.4.8.2023.001 · digitized · missing pointwise uncertainty</text></g></svg>")
    plot=String(take!(svg));write(joinpath(dir,"comparison.svg"),plot)
    rows=join(["<tr><td>$(r["point_id"])</td><td>$(r["scenario"])</td><td>$(round(r["prediction_water_g_kg"];digits=6))</td><td>$(round(100*r["delta_water"];digits=3))</td><td>$(round(r["prediction_solution_g_kg"];digits=6))</td><td>$(round(100*r["delta_solution"];digits=3))</td><td>$(round(r["prediction_change_water_percent"];digits=4))</td><td><a href='$(r["archive"])/input.pqi'>deck</a></td></tr>" for r in results])
    choices=join(["<li><b>$name</b>: $(MineralTrace.html(meaning))</li>" for (name,_,meaning) in scenarios])
    page="""<!doctype html><html lang="en"><meta charset="utf-8"><title>MineralTrace v0.7.1: discrepancy attribution</title><style>body{max-width:1150px;margin:32px auto;padding:0 20px;font:16px/1.6 system-ui;color:#23384a}svg{width:100%;height:auto}table{border-collapse:collapse;width:100%;font-size:12px}td,th{padding:7px;border:1px solid #ccd3da}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#f1f5f7;padding:16px}</style><h1>Calcite endpoint discrepancy: controlled attribution</h1><p>Five unchanged independent 24 °C observations, seven declared choices, no fitted parameters. This report measures model sensitivity; it does not select an optimum model or validate rates, pH or chronology.</p><p>Baseline high bias persists on both mass bases. Ideal CO2 and charged-ion Davies changes increase predictions. Whole Pitzer-profile predictions decrease, but constants, species and interactions change together: this is a candidate explanation requiring independently held-out data, not an isolated activity-model attribution. Aqueous pressure perturbations are small in this narrow test.</p>$plot<h2>Declared controls</h2><ul>$choices</ul><p>Ideal-gas and 1-atm decoupling cases are limiting diagnostics, not physically accepted high-pressure reconstructions. No parameter combinations are optimized. Mass-basis ambiguity and missing per-point uncertainties remain; zero discrepancy is not a pass criterion.</p><table><tr><th>Point</th><th>Choice</th><th>g/kg water</th><th>Error % water</th><th>g/kg solution</th><th>Error % solution</th><th>Prediction change % water</th><th>Raw input</th></tr>$rows</table><h2>Three separate quality tracks</h2><p>Engine: instrumented baseline reproduces the endpoint API and actual solution pressure is checked. Chemical: Ca/C/H/O, net charge, residual solid and reservoir checked at every endpoint. Empirical: discrepancies remain reported, with no empirical acceptance threshold invented. Numerical/threshold robustness under a fixed model does not establish experimental accuracy.</p><p><a href="comparison.csv">All numerical differences</a> · <a href="results.json">Selected outputs, balances and raw archives</a> · <a href="analysis.json">Deterministic analysis and hashes</a> · <a href="reproduce.jl">Reproduce</a></p><p>The original REFLECT source, frozen observations, protocol and limitations must be read together. A second held-out experimental series has not been quantitatively tested. Model status: challenged / discrepancy unresolved.</p></html>"""
    write(joinpath(dir,"report.html"),page)
end

function attribute_calcite_bias(root; project=dirname(@__DIR__), config=PHREEQCConfig(), pitzer=joinpath(dirname(config.database),"pitzer.dat"))
    obs=joinpath(project,"data/validation/reflect-2023/observations.csv")
    bytes2hex(sha256(read(obs)))==OBS_HASH || error("Frozen observations changed")
    env=environment_check(config);mkpath(root);dir=abspath(mktempdir(root;prefix="calcite-attribution-",cleanup=false))
    dbdir=joinpath(dir,"databases");mkpath(dbdir)
    patches=diagnostic_databases(env.database,pitzer,dbdir)
    # All choices declared before this batch; no combinations, residual minimization or parameter search.
    scenarios=[("baseline","phreeqc.dat","native PR; measured pCO2; aqueous P=pCO2+0.03 bar"),
      ("ideal_CO2_limit","ideal-co2.dat","ideal-gas limiting diagnostic; inaccurate at high pressure, not a replacement"),
      ("davies_charged_ions","davies-ions.dat","Davies for listed ions only; same constants and neutral-species activity"),
      ("pitzer_profile","pitzer.dat","whole USGS Pitzer profile; bundled constants/species/interactions, not an isolated activity effect"),
      ("aqueous_pressure_upper","phreeqc.dat","aqueous total P +0.2 bar at fixed pCO2; conservative one-sided sensor stress, not a confidence interval"),
      ("omit_vapor_pressure","phreeqc.dat","aqueous P=pCO2; neglect 0.03 bar vapor contribution only"),
      ("aqueous_1atm_limit","phreeqc.dat","aqueous 1 atm with pressurized gas: nonphysical decoupling diagnostic only")]
    results=Dict{String,Any}[]
    for cells in [split(line,',') for line in readlines(obs)[2:end]]
        id=cells[1];t=parse(Float64,cells[2]);p=parse(Float64,cells[3]);measured=parse(Float64,cells[4]);base=nothing
        for (name,db,meaning) in scenarios
            d=Dict("temperature_c"=>t,"solution_pressure_bar"=>p+0.03,"pco2_bar"=>p,"water_kg"=>0.8,"calcite_g"=>10.,"co2_reservoir_mol"=>10.,"source_id"=>"REFLECT-D23-2023","allow_unvalidated_conditions"=>true,"initial_recipe"=>"degassed_deionised_water_modelled_as_pure_water")
            e=CalciteCO2Endpoint(d);c=PHREEQCConfig(executable=env.executable,database=joinpath(dbdir,db))
            # Native endpoint provides independent accounting and the exact same database formula weight.
            r=calcite_endpoint(e,c;root=dir)
            pa=name=="aqueous_pressure_upper" ? (p+0.23)/1.01325 : name=="omit_vapor_pressure" ? p/1.01325 : name=="aqueous_1atm_limit" ? 1. : (p+0.03)/1.01325
            stock=10/parse(Float64,r["selected"]["gfw_Calcite"])
            deck=attribution_input(e,stock;pressure_atm=pa)
            run=run_phreeqc(c,deck;root=dir,required=["pressure_atm","ionic_strength","n_Ca","n_C","n_H","n_O","logf_CO2"],sources=["REFLECT-D23-2023"],metadata=Dict("scenario"=>name,"interpretation"=>meaning))
            q=only(filter(q->q["state"]=="react",run.rows));initial=only(filter(q->q["state"]=="i_soln",run.rows));v(k)=parse(Float64,q[k])
            abs(v("pressure_atm")-pa)<1e-8 || error("Actual aqueous pressure differs from declared pressure")
            balances=Dict{String,Any}()
            for (atom,ns,ng) in (("Ca",1,0),("C",1,1),("H",0,0),("O",3,2))
                expected=parse(Float64,initial["n_$atom"])+ns*stock+ng*10
                residual=v("n_$atom")+ns*v("solid_Calcite")+ng*v("reservoir_CO2")-expected
                tol=1e-8+1e-10*abs(expected);abs(residual)<=tol || error("Element accounting failed")
                balances[atom]=Dict("residual_mol"=>residual,"tolerance_mol"=>tol,"pass"=>true)
            end
            charge=v("charge")-parse(Float64,initial["charge"])
            abs(charge)<1e-9 && v("solid_Calcite")>1e-8 && v("reservoir_CO2")>1e-6 && abs(v("si_Calcite"))<1e-7 || error("Charge/endpoint boundary failure")
            water=v("n_Ca")*v("gfw_Calcite")/v("mass_H2O");solution=v("n_Ca")*v("gfw_Calcite")/(v("rho_kg_L")*v("volume_L"))
            if name=="baseline"
                abs(water-r["solubility_g_per_kg_water"])<1e-9 || error("Instrumented replay differs from v0.7 endpoint")
                base=(water,solution)
            end
            push!(results,Dict("point_id"=>id,"scenario"=>name,"meaning"=>meaning,"pco2_bar"=>p,"observed_g_kg"=>measured,"prediction_water_g_kg"=>water,"prediction_solution_g_kg"=>solution,
              "delta_water"=>(water-measured)/measured,"delta_solution"=>(solution-measured)/measured,"prediction_change_water_percent"=>100*(water/base[1]-1),"prediction_change_solution_percent"=>100*(solution/base[2]-1),
              "phi_CO2"=>10^v("logf_CO2")/(p/1.01325),"selected"=>q,"balances"=>balances,"charge_change_eq"=>charge,"boundary_attained"=>true,"archive"=>relpath(run.directory,dir),"native_endpoint_archive"=>relpath(r["archive"],dir),"database_sha256"=>run.manifest["database_sha256"]))
        end
    end
    cp(obs,joinpath(dir,"observations.csv"));cp(@__FILE__,joinpath(dir,"attribute_calcite_bias.jl"))
    for f in ("src","Project.toml","Manifest.toml");cp(joinpath(project,f),joinpath(dir,f));end
    mkpath(joinpath(dir,"data/validation/reflect-2023"));cp(obs,joinpath(dir,"data/validation/reflect-2023/observations.csv"))
    provenance=Dict("observation_sha256"=>OBS_HASH,"baseline_database_sha256"=>BASE_HASH,"executable_sha256"=>bytes2hex(sha256(read(env.executable))),"script_sha256"=>bytes2hex(sha256(read(@__FILE__))),"package_version"=>string(pkgversion(MineralTrace)),"julia_version"=>string(VERSION),"protocol_sha256"=>bytes2hex(sha256(read(joinpath(project,"data/validation/v071/PROTOCOL.md")))),"source_audit_sha256"=>bytes2hex(sha256(read(joinpath(project,"data/validation/v071/SOURCE_AUDIT.md")))),"source_pdf_sha256"=>bytes2hex(sha256(read(joinpath(project,"data/sources/REFLECT-D23-2023.pdf")))),"patches"=>patches,"fitted_parameters"=>Any[],"model_applicability"=>"challenged_discrepancy_unresolved","source_sha256"=>Dict(relpath(joinpath(d,f),project)=>bytes2hex(sha256(read(joinpath(d,f)))) for (d,_,fs) in walkdir(joinpath(project,"src")) for f in fs))
    payload=Dict("provenance"=>provenance,"results"=>results,"scenario_order"=>first.(scenarios))
    write(joinpath(dir,"results.json"),MineralTrace.json_value(payload)*"\n")
    det=deepcopy(payload);for r in det["results"];delete!(r,"archive");delete!(r,"native_endpoint_archive");end
    write(joinpath(dir,"analysis.json"),MineralTrace.json_value(det)*"\n")
    keys=["point_id","scenario","pco2_bar","observed_g_kg","prediction_water_g_kg","prediction_solution_g_kg","delta_water","delta_solution","prediction_change_water_percent","prediction_change_solution_percent","phi_CO2","database_sha256"]
    open(joinpath(dir,"comparison.csv"),"w") do io
        println(io,join(keys,','));for r in results;println(io,join([r[k] for k in keys],','));end
    end
    write(joinpath(dir,"reproduce.jl"),"include(joinpath(@__DIR__,\"attribute_calcite_bias.jl\"))\nattribute_calcite_bias(joinpath(@__DIR__,\"reproduced\"); project=@__DIR__,config=PHREEQCConfig(database=joinpath(@__DIR__,\"databases/phreeqc.dat\")),pitzer=joinpath(@__DIR__,\"databases/pitzer.dat\"))\n")
    attribution_report(dir,results,scenarios)
    for f in ("PROTOCOL.md","SOURCE_AUDIT.md");cp(joinpath(project,"data/validation/v071",f),joinpath(dir,f));end
    mkpath(joinpath(dir,"data/sources"));cp(joinpath(project,"data/sources/REFLECT-D23-2023.pdf"),joinpath(dir,"data/sources/REFLECT-D23-2023.pdf"))
    mkpath(joinpath(dir,"data/validation/v071"))
    for f in ("PROTOCOL.md","SOURCE_AUDIT.md");cp(joinpath(project,"data/validation/v071",f),joinpath(dir,"data/validation/v071",f));end
    println("Attribution archive: ",dir)
    dir
end
if abspath(PROGRAM_FILE)==@__FILE__
    attribute_calcite_bias(isempty(ARGS) ? "results" : ARGS[1])
end
