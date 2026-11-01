function discovery_analysis(r::DiscoveryResult)
    cs=deepcopy(r.candidates)
    for c in cs
        for p in c["steps"];delete!(p,"archive");end
        haskey(c,"failed_archive") && delete!(c,"failed_archive")
        c["error"]=replace(c["error"],r.directory=>"<study>")
    end
    Dict("study"=>r.study.spec,"candidates"=>cs,"membership"=>r.membership,"sensitivity"=>r.sensitivity,"qualitative_response_groups"=>r.groups)
end

function mechanism_name(sequence)
    kinds=Set(op["kind"] for op in sequence)
    isempty(kinds) && return "Equilibrium-only control"
    labels=String[]
    "temperature" in kinds && push!(labels,count(op->op["kind"]=="temperature",sequence)>1 ? "Staged cooling" : "Cooling")
    "HCl" in kinds && push!(labels,"Acidification (HCl)")
    "NaOH" in kinds && push!(labels,"Alkalinization (NaOH)")
    join(labels," + ")
end

function report(r::DiscoveryResult)
    dir=r.directory;d=r.study.spec
    write(joinpath(dir,"analysis.json"),replace(json_value(discovery_analysis(r)),dir=>"<study>")*"\n")
    write(joinpath(dir,"results.json"),json_value(Dict("analysis"=>discovery_analysis(r),"candidates_with_archives"=>r.candidates,"provenance"=>r.provenance))*"\n")
    csv(v)="\""*replace(v===nothing ? "" : string(v),'"'=>"\"\"")*"\""
    open(joinpath(dir,"candidates.csv"),"w") do io
        println(io,"id,grids,mechanism,coordinates,operations,computational_status,conditional_mechanism_classification,actual_formation_order,qualitative_response_signature")
        for c in r.candidates
            grids=join(sort([g for (g,ids) in r.membership if c["id"] in ids]),";")
            println(io,join(csv.([c["id"],grids,mechanism_name(c["environmental_sequence"]),c["coordinates"],c["environmental_sequence"],c["computational_status"],c["screening"]["classification"],c["screening"]["formation_order_classification"],response_signature(c["screening"])]),','))
        end
    end
    open(joinpath(dir,"steps.csv"),"w") do io
        println(io,"candidate,index,operation,temperature_c,pH,mineral,SI,solid_gain_mol,remaining_solid_mol,charge_percent,net_charge_eq,mass_pass,charge_pass,direction_pass,archive")
        for c in r.candidates,p in c["steps"],m in d["minerals"]
            tr=p["phase_transfers"][m]
            println(io,join(csv.([c["id"],p["index"],p["operation_id"],p["temperature_c"],p["pH"],m,p["si"][m],tr["solid_gain_mol"],tr["remaining_mol"],p["charge_diagnostic"]["percent_error"],p["charge_diagnostic"]["net_charge_eq"],p["accounting"]["mass_pass"],p["accounting"]["charge_pass"],p["direction_pass"],p["archive"]]),','))
        end
    end
    open(joinpath(dir,"balances.csv"),"w") do io
        println(io,"candidate,operation,element,aqueous_mol,solid_mol,expected_total_mol,residual_mol,tolerance_mol,pass")
        for c in r.candidates,p in c["steps"],e in PROCESS_ELEMENTS
            b=p["accounting"]["elements"][e]
            println(io,join(csv.([c["id"],p["operation_id"],e,b["aqueous_mol"],b["solid_mol"],b["expected_total_mol"],b["residual_mol"],b["tolerance_mol"],b["pass"]]),','))
        end
    end
    write(joinpath(dir,"sensitivity.json"),json_value(r.sensitivity)*"\n")
    write(joinpath(dir,"response-groups.json"),json_value(r.groups)*"\n")
    # The first generated PathStudy holds the same user DAG; no reaction output generates edges.
    generated=generate_candidates(r.study);graph=evidence_svg(PathStudy(first(generated.candidates)["spec"]))
    write(joinpath(dir,"evidence.svg"),graph)
    rows=String[];sections=String[]
    for (i,c) in enumerate(r.candidates)
        screening=c["screening"];label=screening["classification"];id=c["id"]
        push!(rows,"<tr><td><a href='#candidate-$i'>$(html(id))</a></td><td>$(html(mechanism_name(c["environmental_sequence"])))</td><td>$(html(c["coordinates"]))</td><td>$(html(screening["responses"]))</td><td>$(html(label))</td><td>undetermined</td></tr>")
        plots=String[]
        for metric in ("pH","temperature","SI","solid_gain")
            svg=path_plot(c,metric,d["minerals"]);write(joinpath(dir,"candidate-$i-$metric.svg"),svg);push!(plots,svg)
        end
        checks=join(["<tr><td>$(html(q["constraint"]))</td><td>$(html(q["result"]))</td><td>$(html(q))</td></tr>" for q in screening["checks"]])
        ledger=join(["<tr><td>$(p["index"]) · $(html(p["operation_id"]))</td><td>$(html(p["active_phases"]))</td><td>$(html(p["phase_transfers"]))</td><td>$(html(p["accounting"]))</td><td>$(html(p["charge_diagnostic"]))</td></tr>" for p in c["steps"]])
        raw=join(["<a href='$(html(p["archive"]))/input.pqi'>$(html(p["operation_id"])) input</a> / <a href='$(html(p["archive"]))/output.pqo'>output</a> / <a href='$(html(p["archive"]))/state.dmp'>state dump</a>" for p in c["steps"]]," · ")
        haskey(c,"failed_archive") && (raw*=" · <a href='$(html(c["failed_archive"]))/output.pqo'>failed output</a>")
        push!(sections,"<details id='candidate-$i'><summary>$(html(id)) · $(html(label)) · $(html(mechanism_name(c["environmental_sequence"])))</summary><p>Computational status: $(html(c["computational_status"])). Actual formation chronology: undetermined.</p><pre>$(html(c["environmental_sequence"]))</pre>$(join(plots))<table><tr><th>Constraint</th><th>Result</th><th>Explanation/source</th></tr>$checks</table><h3>All-phase access and chemical accounting</h3><table><tr><th>Step</th><th>Active phases (invariant)</th><th>Solid transfers mol</th><th>Element balance mol and charge change eq</th><th>Charge diagnostic</th></tr>$ledger</table><p>$raw</p><pre>$(html(c["error"]))</pre></details>")
    end
    gridrows=join(["<tr><td>$(html(g["id"])) / $(html(g["role"]))</td><td>$(length(r.membership[g["id"]]))</td><td>$(html(Dict(k=>count(c->c["id"] in r.membership[g["id"]] && c["screening"]["classification"]==k,r.candidates) for k in ("compatible","incompatible","undetermined"))))</td><td>$(html(g))</td></tr>" for g in d["grids"]])
    groups=join(["<li>$(html(g["id"])): $(length(g["candidate_ids"])) paths. <code>$(html(g["qualitative_signature"]))</code><details><summary>Members</summary>$(html(g["candidate_ids"]))</details></li>" for g in r.groups])
    validationfile=joinpath(dir,"data","validation","EXPERIMENTAL_CASE_V070.md")
    isfile(validationfile) || (validationfile=joinpath(dir,"data","validation","EXPERIMENTAL_CASE_V060.md"))
    validation=isfile(validationfile) ? read(validationfile,String) : "Full independent experimental reaction-path validation remains incomplete. Engine agreement and mass conservation are separate validations."
    text="""<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>MineralTrace constraint-driven mechanism screening</title><style>body{font:15px/1.55 system-ui;max-width:1300px;margin:30px auto;padding:0 20px;color:#213240;background:#f6f8fa}section,header,details{background:white;border:1px solid #d6dfe6;border-radius:8px;margin:16px 0;padding:20px}summary{cursor:pointer;font-weight:650}svg{width:100%;height:auto}table{width:100%;border-collapse:collapse;font-size:12px}td,th{border:1px solid #ddd;padding:8px;text-align:left;overflow-wrap:anywhere}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#eef3f5;padding:12px;font-size:12px}a{color:#126b86}.warning{border-left:5px solid #b37421}</style>
    <header><p>MineralTrace · v$(html(r.provenance["package_version"]))</p><h1>$(html(d["title"]))</h1><p>Constraint-driven, finite environmental mechanism screening. $(length(r.candidates)) unique chemical candidates; every result comes from PHREEQC. All compatible candidates are retained.</p></header>
    <section class="warning"><h2>What is discovered — and what remains unknown</h2><p>Minerals are simultaneously accessible during initial equilibration and every environmental operation. Search does not toggle phases or use observed order to construct candidates. Cooling, explicit neutral reagent additions and common phase inventories cause chemical differences. The pre-reaction SOLUTION speciation is not an extra isolated stage: all candidates have the same documented initial equilibration.</p><p>The three classes below concern a declared equilibrium-increment surrogate: first post-baseline above-threshold solid gain/loss, compared with supplied event edges. It is a screening assumption, not independent observed formation. Baseline reactions, same-batch reactions, repeated mineral events and missing sources remain unresolved. Reversed or absent surrogate reactions reject that finite model test only.</p><p><strong>Actual mineral crystallization order remains undetermined for every candidate.</strong> Equilibrium alone cannot predict nucleation, reaction rates or geological time. A proxy-compatible path is not a confirmed or unique history; a proxy-incompatible path does not refute the actual observed sequence. Model applicability remains unverified, especially beyond 25 °C.</p><p>Closed aqueous plus retained-solid inventory, no gas exchange or mixing; externally imposed temperature, no energy balance; HCl/NaOH formula additions without carrier water. Initial stocks and reaction directions are fixed assumptions. SI is opportunity, solid gain is modeled equilibrium reaction, and user observations remain external evidence. No automatic evidence edges are created.</p></section>
    <section><h2>Generated mechanisms and calculated outcomes</h2><p>Threshold: $(d["search"]["reaction_threshold_mol"]) mol per operation. It is a user-declared detection rule, not an experimental uncertainty. Classification counts are not probabilities.</p><table><tr><th>Candidate</th><th>Environmental mechanism</th><th>Initial sampled coordinates</th><th>Detected reaction steps (1 = baseline)</th><th>Conditional mechanism screen</th><th>Actual formation order</th></tr>$(join(rows))</table></section>
    <section><h2>Independent user evidence</h2>$graph<pre>$(html(Dict("events"=>d["events"],"evidence"=>d["evidence"])))</pre></section>
    <section><h2>Range and discretization sensitivity</h2><table><tr><th>Grid / role</th><th>Paths</th><th>Conditional classes</th><th>Declared bounds and samples</th></tr>$gridrows</table><pre>$(html(r.sensitivity))</pre><p>The resolution comparison adds samples at unchanged bounds; the range comparison changes initial bounds with the baseline environmental samples. Shared chemical paths are content-identical and computed once. New/lost signatures describe sampled sensitivity only; unchanged results are not a convergence proof. Unsearched continuum, depth, thresholds, database/activity model and accessibility uncertainty remain outside this comparison.</p></section>
    <section><h2>Multiple mechanisms with the same qualitative response</h2><ul>$groups</ul><p>These are qualitative groups, not numerical equality of trajectories, unique inversions or posterior probabilities. All member paths and their actual pH, SI and reaction amounts are preserved.</p></section>
    <section><h2>Candidate calculations and hard accounting</h2>$(join(sections))</section>
    <section><h2>Three distinct validation levels</h2><p>Direct-engine agreement, element/charge accounting and independent experimental comparison must be assessed separately.</p><pre>$(html(validation))</pre></section>
    <section><h2>Inputs, search grammar and provenance</h2><pre>$(html(read(joinpath(dir,"discovery.toml"),String)))</pre><pre>$(html(r.provenance))</pre><p><a href="generated-candidates.toml">All generated explicit inputs</a> · <a href="candidates.csv">Candidates</a> · <a href="steps.csv">Steps</a> · <a href="balances.csv">Balances</a> · <a href="sensitivity.json">Sensitivity</a> · <a href="response-groups.json">Response groups</a> · <a href="analysis.json">Deterministic analysis</a> · <a href="results.json">Full provenance and archives</a></p><pre>PHREEQC_EXECUTABLE=/absolute/path/to/phreeqc julia --project=. reproduce.jl</pre><p>Run in this exported directory. HTML and figures are standalone; keep the full folder for audit and reproduction. Numerical conservation is a hard gate, not a score. Threshold exceedance in charge diagnostics requires review and is not physical impossibility; concentrations are never adjusted.</p></section></html>"""
    path=joinpath(dir,"report.html");write(path,text);path
end
