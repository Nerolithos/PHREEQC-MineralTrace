function path_plot(candidate,metric,minerals)
    steps=candidate["steps"]
    isempty(steps) && return "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 800 100'><text x='20' y='50' font-family='sans-serif'>No computed states available; inspect the archived calculation failure.</text></svg>"
    title=metric=="pH" ? "pH along explicitly ordered operations" : metric=="temperature" ? "Controlled temperature path" : metric=="SI" ? "Post-operation saturation indices" : "Signed equilibrium solid gain per operation"
    labels=metric in ("pH","temperature") ? [metric] : minerals
    series=[(label,[metric=="pH" ? p["pH"] : metric=="temperature" ? p["temperature_c"] : metric=="SI" ? p["si"][label] : get(get(p["phase_transfers"],label,Dict()),"solid_gain_mol",nothing) for p in steps]) for label in labels]
    values=Float64[v for (_,ys) in series for v in ys if v!==nothing]
    low=isempty(values) ? -1. : minimum(values);high=isempty(values) ? 1. : maximum(values);pad=max((high-low)*0.08,abs(high)*0.02,1e-12);lo=low-pad;hi=high+pad
    X=x->90+580*x/max(length(steps)-1,1);Y=y->325-235*(y-lo)/(hi-lo)
    units=metric=="temperature" ? "degC" : metric=="solid_gain" ? "mol (positive precipitation, negative dissolution)" : metric
    io=IOBuffer();print(io,"<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 800 470' role='img'><title>$(html(title))</title><rect width='100%' height='100%' fill='white'/><g font-family='sans-serif' font-size='12' fill='#20303c'><text x='90' y='27' font-size='18'>$(html(title))</text><text x='20' y='60'>$(html(units))</text>")
    for f in (0.,0.25,0.5,0.75,1.)
        v=lo+(hi-lo)*f;y=Y(v);print(io,"<path d='M 90 $y H 670' stroke='#dce2e8'/><text x='82' y='$(y+4)' text-anchor='end'>$(round(v;sigdigits=3))</text>")
    end
    for (i,(name,ys)) in enumerate(series)
        color=i==1 ? "#146f91" : "#b14b40";previous=nothing
        for (j,value) in enumerate(ys)
            if value===nothing
                print(io,"<text x='$(X(j-1))' y='337' text-anchor='middle'>?</text>");previous=nothing;continue
            end
            x=X(j-1);y=Y(value)
            previous!==nothing && print(io,"<path d='M $(previous[1]) $(previous[2]) L $x $y' stroke='$color' fill='none' stroke-width='2'/>")
            print(io,"<circle cx='$x' cy='$y' r='3.5' fill='$color'><title>$(html(steps[j]["operation_id"])) $(html(name))=$value</title></circle>");previous=(x,y)
        end
        print(io,"<text x='$(90+220*(i-1))' y='414' fill='$color'>$(html(name))</text>")
    end
    for (j,p) in enumerate(steps)
        print(io,"<text x='$(X(j-1))' y='354' text-anchor='middle'>$(p["index"])</text>")
    end
    print(io,"<text x='90' y='385'>Operation index (not elapsed geological time)</text><text x='20' y='449'>Actual PHREEQC states; lines are guides. ? = undefined SI; no invented values fill gaps.</text></g></svg>")
    String(take!(io))
end

function evidence_svg(s::PathStudy)
    order=topological_order(s.graph);width=max(800,200length(order));pos=Dict(id=>i for (i,id) in enumerate(order))
    io=IOBuffer();print(io,"<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 $width 230' role='img'><title>User-supplied evidence DAG</title><defs><marker id='arrow' markerWidth='10' markerHeight='7' refX='9' refY='3.5' orient='auto'><path d='M0,0 L10,3.5 L0,7' fill='#475d68'/></marker></defs><rect width='100%' height='100%' fill='white'/><g font-family='sans-serif' font-size='14'><text x='20' y='25'>Level 3: independently supplied event evidence, never generated from SI</text>")
    for e in s.graph.evidence
        x1=30+200*(pos[e.earlier]-1)+135;x2=30+200*(pos[e.later]-1)
        print(io,"<path d='M $x1 110 Q $((x1+x2)/2) 45 $x2 110' fill='none' stroke='#475d68' stroke-width='2' marker-end='url(#arrow)'><title>$(html(e.source)): $(html(e.interpretation))</title></path>")
    end
    for event in s.spec["events"]
        x=30+200*(pos[event["id"]]-1)
        print(io,"<rect x='$x' y='95' width='135' height='57' rx='7' fill='#e6f0f4' stroke='#7596a7'/><text x='$(x+10)' y='117'>$(html(event["id"]))</text><text x='$(x+10)' y='138' font-size='12'>$(html(event["mineral"]))</text>")
    end
    print(io,"<text x='20' y='205' font-size='12'>Only source-backed user temporal edges are shown. A compatible model does not authenticate observations.</text></g></svg>")
    String(take!(io))
end

function report(r::PathComparison)
    d=r.study.spec;dir=r.directory
    analyses=Dict{String,Any}[]
    for candidate in r.candidates
        clean=deepcopy(candidate)
        for p in clean["steps"];delete!(p,"archive");end
        haskey(clean,"failed_archive") && delete!(clean,"failed_archive")
        clean["error"]=replace(clean["error"],dir=>"<study>")
        push!(analyses,clean)
    end
    payload=Dict("study"=>d,"candidates"=>analyses,"evidence_analysis"=>Dict("determined"=>[collect(p) for p in analyze(r.study.graph).determined],"undetermined"=>[collect(p) for p in analyze(r.study.graph).undetermined]))
    write(joinpath(dir,"analysis.json"),replace(json_value(payload),dir=>"<study>")*"\n")
    write(joinpath(dir,"results.json"),json_value(Dict("study"=>d,"candidates"=>r.candidates,"provenance"=>r.provenance))*"\n")
    csv(v)="\""*replace(v===nothing ? "" : string(v),'"'=>"\"\"")*"\""
    open(joinpath(dir,"steps.csv"),"w") do io
        println(io,"candidate,index,operation,kind,temperature_c,pH,mineral,SI,active,solid_gain_mol,remaining_solid_mol,mass_pass,charge_pass,charge_percent,charge_eq_per_kgw,archive")
        for c in r.candidates,p in c["steps"],m in d["minerals"]
            transfer=get(p["phase_transfers"],m,Dict())
            println(io,join(csv.([c["id"],p["index"],p["operation_id"],p["kind"],p["temperature_c"],p["pH"],m,p["si"][m],get(transfer,"active",false),get(transfer,"solid_gain_mol",nothing),get(transfer,"remaining_mol",nothing),p["accounting"]["mass_pass"],p["accounting"]["charge_pass"],p["charge_diagnostic"]["percent_error"],p["charge_diagnostic"]["net_charge_eq_per_kgw"],p["archive"]]),','))
        end
    end
    open(joinpath(dir,"balances.csv"),"w") do io
        println(io,"candidate,operation,element,aqueous_mol,solid_mol,expected_total_mol,residual_mol,tolerance_mol,pass")
        for c in r.candidates,p in c["steps"],e in PROCESS_ELEMENTS
            b=p["accounting"]["elements"][e]
            println(io,join(csv.([c["id"],p["operation_id"],e,b["aqueous_mol"],b["solid_mol"],b["expected_total_mol"],b["residual_mol"],b["tolerance_mol"],b["pass"]]),','))
        end
    end
    graph=evidence_svg(r.study);write(joinpath(dir,"evidence.svg"),graph)
    sections=String[]
    for (i,c) in enumerate(r.candidates)
        parts=String[]
        for metric in ("temperature","pH","SI","solid_gain")
            svg=path_plot(c,metric,d["minerals"]);write(joinpath(dir,"candidate-$(i)-$metric.svg"),svg);push!(parts,svg)
        end
        definition=only(p for p in d["paths"] if p["id"]==c["id"])
        diagram=join(["$(op["id"]) [$(op["kind"]); active=$(join(op["active_phases"],","))]" for op in definition["operations"]]," → ")
        checks=join(["<tr><td>$(html(get(q,"constraint","")))</td><td>$(html(get(q,"result","")))</td><td>$(html(q))</td></tr>" for q in c["compatibility"]["checks"]])
        ledger=join(["<tr><td>$(p["index"]) · $(html(p["operation_id"]))</td><td>$(p["temperature_c"]) / $(p["pH"])</td><td>$(html(Dict(m=>v["remaining_mol"] for (m,v) in p["phase_transfers"])))</td><td>$(p["charge_diagnostic"]["net_charge_eq"]) / $(p["accounting"]["charge_change_eq"])</td><td>$(html(Dict(e=>b["residual_mol"] for (e,b) in p["accounting"]["elements"])))</td><td>$(p["accounting"]["mass_pass"]) / $(p["accounting"]["charge_pass"]) / $(p["direction_pass"])</td></tr>" for p in c["steps"]])
        ledger="<h3>Closed-inventory checks</h3><table><tr><th>Operation</th><th>T degC / pH</th><th>Remaining solid mol, including isolated stocks</th><th>Net charge / change (eq)</th><th>Element residuals (mol)</th><th>Mass / charge / direction pass</th></tr>$ledger</table>"
        raw=join(["<a href='$(html(p["archive"]))/input.pqi'>$(html(p["operation_id"])) input</a> / <a href='$(html(p["archive"]))/output.pqo'>raw output</a> / <a href='$(html(p["archive"]))/state.dmp'>saved solution</a>" for p in c["steps"]]," · ")
        haskey(c,"failed_archive") && (raw*=" · <a href='$(html(c["failed_archive"]))/output.pqo'>failed raw output</a>")
        push!(sections,"<section><h2>$(html(c["id"])) — $(html(c["compatibility"]["classification"]))</h2><p>$(html(c["compatibility"]["qualification"]))</p><p>Computational status: $(html(c["computational_status"])); model applicability: unverified.</p><pre>$(html(diagram))</pre>$(join(parts))$ledger<h3>Exact evidence constraints and correspondences</h3><table><tr><th>Constraint</th><th>Result</th><th>Source and explanation</th></tr>$checks</table><p>$raw</p><pre>$(html(c["error"]))</pre></section>")
    end
    validation=joinpath(dir,"data","validation","REACTIVE_PATH_VALIDATION.md")
    validationtext=isfile(validation) ? read(validation,String) : "Independent experimental pathway validation remains incomplete; see registered sources and case limitations."
    text="""<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>MineralTrace reactive path comparison</title><style>body{font:16px/1.55 system-ui;max-width:1150px;margin:32px auto;padding:0 22px;color:#20303c;background:#f5f7fa}section,header{background:white;border:1px solid #dce2e8;border-radius:9px;padding:24px;margin:18px 0}svg{width:100%;height:auto}pre{white-space:pre-wrap;overflow-wrap:anywhere;font-size:12px;background:#f0f4f6;padding:14px}table{width:100%;border-collapse:collapse;font-size:12px}td,th{border:1px solid #ddd;padding:8px;text-align:left;overflow-wrap:anywhere}a{color:#126b86}</style>
    <header><p>MineralTrace · Reactive Mineral Path Explorer</p><h1>$(html(d["title"]))</h1><p>Finite user-defined candidate paths tested against explicit evidence. Classification is conditional model compatibility, never confirmed geological history.</p><p>Evaluation mode: $(html(d["evaluation_mode"])). Model applicability remains unverified.</p></header>
    <section><h2>Three separate evidence levels</h2><ol><li>Saturation opportunity: post-operation SI, not a nucleation or formation time.</li><li>Equilibrium reaction: signed solid change under specified phase inventories, permissions and boundary; not elapsed time or kinetic precipitation.</li><li>Observed formation: independently supplied specimen evidence and explicit user correspondences; no observed event is generated by the model.</li></ol><p>Positive solid gain = precipitation; negative = dissolution. No phase is activated implicitly. Inactive solids are retained in the closed inventory but isolated from reaction until explicitly reactivated. Initial solid stock is an assumption, not modeled creation.</p><p>All steps use actual PHREEQC saved solution state, not reconstructed totals with overwritten pH. Atom and net-charge closure and direction permissions are hard constraints, never traded against evidence fit.</p><p>The boundary is closed to element transfer except declared reagent additions, not thermally isolated: an external thermostat imposes temperature, and heat/enthalpy balance is not modeled. There is no implicit gas exchange, mixing, rock reservoir, carrier-water addition, kinetic law or continuous optimization. Phase equilibrium may be metastable if other phases are disabled. No unlisted event assignments are searched or invented. Any ordering encoded by phase permissions or bindings remains a user assumption, not an independently predicted chronology. The teaching example deliberately varies this activation order; the model additionally checks whether the specified reactions actually occur.</p><p>Charge threshold exceedance means a declared diagnostic needs review, not physical impossibility. Multiple compatible candidates remain multiple hypotheses, not probabilities.</p></section>
    <section><h2>User evidence DAG</h2>$graph<pre>$(html(Dict("events"=>d["events"],"evidence"=>d["evidence"])))</pre></section>
    $(join(sections))
    <section><h2>Independent validation and remaining limits</h2><pre>$(html(validationtext))</pre><p>Existing engine regression and numerical conservation do not establish full experimental or natural-deposit validation. Species/activity completeness and the 25–80 °C exploration range remain unverified. Strict mode retains that uncertainty.</p></section>
    <section><h2>Full assumptions, inputs and provenance</h2><pre>$(html(read(joinpath(dir,"paths.toml"),String)))</pre><pre>$(html(r.provenance))</pre><p><a href="steps.csv">Stepwise SI and solid changes</a> · <a href="balances.csv">All aqueous + solid element balances</a> · <a href="results.json">Full JSON</a> · <a href="analysis.json">Deterministic analysis JSON</a></p><pre>PHREEQC_EXECUTABLE=/absolute/path/to/phreeqc julia --project=. reproduce.jl</pre><p>Run from this exported folder. The HTML is standalone; preserve the entire directory for original calculations, full solution-state dumps, database and archived source.</p></section></html>"""
    path=joinpath(dir,"report.html");write(path,text);path
end
