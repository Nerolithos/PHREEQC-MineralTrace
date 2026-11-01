function robustness_plane_svg(plane)
    points=plane["points"];xs=sort(unique(vcat([p["x"] for p in points],[p["x"] for p in plane["unsampled_cells"]])));ys=sort(unique(vcat([p["y"] for p in points],[p["y"] for p in plane["unsampled_cells"]])))
    X=x->100+600*(x-first(xs))/max(last(xs)-first(xs),1e-12);Y=y->350-260*(y-first(ys))/max(last(ys)-first(ys),1e-12)
    io=IOBuffer();print(io,"<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 850 480'><rect width='100%' height='100%' fill='white'/><g font-family='sans-serif' fill='#253747'><text x='55' y='28' font-size='20'>Computed points only · fixed environmental sequence and other inputs</text><path d='M100 70 V350 H720' stroke='#444' fill='none'/>")
    for x in xs;print(io,"<text x='$(X(x))' y='377' text-anchor='middle'>$(x)</text>");end
    for y in ys;print(io,"<text x='90' y='$(Y(y)+4)' text-anchor='end'>$(y)</text>");end
    colors=Dict("compatible"=>"#247d68","incompatible"=>"#b54f44","undetermined"=>"#a98023")
    for p in points
        x=X(p["x"]);y=Y(p["y"]);color=colors[p["classification"]]
        print(io,"<circle cx='$x' cy='$y' r='7' fill='$color'><title>$(html(p))</title></circle>")
    end
    for p in plane["unsampled_cells"]
        x=X(p["x"]);y=Y(p["y"]);print(io,"<path d='M$(x-5) $(y-5) L$(x+5) $(y+5) M$(x-5) $(y+5) L$(x+5) $(y-5)' stroke='#89949c'><title>Uncomputed grid combination, not incompatible</title></path>")
    end
    print(io,"<text x='100' y='410'>x: $(html(plane["x_parameter"]["parameter"])) ($(html(plane["x_parameter"]["units"]))) · y: $(html(plane["y_parameter"]["parameter"])) ($(html(plane["y_parameter"]["units"])))</text><text x='55' y='443'>Green: conditional compatible · red: incompatible surrogate · amber: undetermined · grey ×: uncomputed</text><text x='55' y='467'>White space between samples is uncomputed. No interpolation, phase boundary or geological chronology.</text></g></svg>")
    String(take!(io))
end

function report_robustness(r::DiscoveryResult,analysis)
    dir=r.directory
    write(joinpath(dir,"robustness.json"),json_value(analysis)*"\n")
    deterministic=deepcopy(analysis)
    for c in deterministic["candidates"]
        for p in c["steps"];delete!(p,"archive");end
        haskey(c,"failed_archive") && delete!(c,"failed_archive")
        c["error"]=replace(c["error"],dir=>"<study>")
    end
    write(joinpath(dir,"robustness-analysis.json"),json_value(deterministic)*"\n")
    open(io->TOML.print(io,analysis["plan"];sorted=true),joinpath(dir,"robustness.toml"),"w")
    csv(v)="\""*replace(string(v),'"'=>"\"\"")*"\""
    open(joinpath(dir,"threshold-sensitivity.csv"),"w") do io
        println(io,"threshold_mol,compatible,incompatible,undetermined,changed_candidate_count,chemistry_recomputed")
        for q in analysis["threshold_sensitivity"]
            println(io,join([q["threshold_mol"],q["counts"]["compatible"],q["counts"]["incompatible"],q["counts"]["undetermined"],length(q["flipped_candidate_ids"]),false],','))
        end
    end
    open(joinpath(dir,"parameter-sensitivity.csv"),"w") do io
        println(io,"parameter_id,parameter,value,units,candidate,classification,effect_category,net_solid_gain_mol")
        for q in analysis["one_at_a_time"],p in q["records"]
            println(io,join(csv.([q["parameter"]["id"],q["parameter"]["parameter"],p["value"],q["parameter"]["units"],p["candidate_id"],p["classification"],q["effect_category"],p["net_solid_gain_mol"]]),','))
        end
    end
    plane=analysis["sampled_plane"];svg=robustness_plane_svg(plane);write(joinpath(dir,"sampled-compatibility.svg"),svg)
    thresholds=join(["<tr><td>$(q["threshold_mol"])</td><td>$(html(q["counts"]))</td><td>$(length(q["flipped_candidate_ids"]))</td><td>$(html(q["flipped_candidate_ids"]))</td></tr>" for q in analysis["threshold_sensitivity"]])
    parameters=join(["<section><h3>$(html(q["parameter"]["id"])) · $(html(q["effect_category"]))</h3><p>Net solid gain spans (mol): $(html(q["net_amount_span_mol"])). Classification changed: $(html(q["classification_changed"])); reaction signature changed: $(html(q["reaction_signature_changed"])).</p><pre>$(html(q["records"]))</pre></section>" for q in analysis["one_at_a_time"]])
    raw=join(["<details><summary>$(html(c["id"])) · $(html(c["computational_status"]))</summary><p>$(html(c["coordinates"]))</p>"*join(["<p>Step $(p["index"]): <a href='$(html(p["archive"]))/input.pqi'>input</a> · <a href='$(html(p["archive"]))/output.pqo'>output</a> · <a href='$(html(p["archive"]))/state.dmp'>state</a></p>" for p in c["steps"]])*"</details>" for c in analysis["candidates"]])
    page="""<!doctype html><html><meta charset="utf-8"><title>MineralTrace robustness and sampled identifiability</title><style>body{font:16px/1.5 system-ui;max-width:1150px;margin:30px auto;padding:0 20px;color:#253747}section{padding:18px;border:1px solid #ddd;margin:15px 0}pre{white-space:pre-wrap;overflow-wrap:anywhere;font-size:12px;background:#f2f5f7;padding:12px}table{width:100%;border-collapse:collapse}td,th{padding:8px;border:1px solid #ddd;font-size:12px}svg{width:100%}</style><h1>Threshold robustness and local parameter sensitivity</h1><p>Anchor: $(html(analysis["plan"]["anchor_candidate"])). Source/assumption: $(html(analysis["plan"]["source_id"])). All mineral phases stay simultaneously accessible.</p><p><strong>Actual formation chronology remains undetermined.</strong> Classes concern the disclosed equilibrium-increment surrogate. Sample counts are not probabilities, sensitivity depends on the chosen ranges, and no unique history is inferred.</p><section><h2>Detection-threshold sensitivity</h2><p>The same verified PHREEQC states are reclassified. A detection threshold does not alter chemistry or represent experimental error; no reaction, input concentration or pH is recomputed/overwritten for this table.</p><table><tr><th>Threshold mol</th><th>Classes</th><th>Flips from original threshold</th><th>Exact candidate IDs</th></tr>$thresholds</table></section><section><h2>One parameter at a time</h2><p>Only the named initial parameter or reagent amount changes. Other conditions and phase permissions remain fixed; no compensating ion adjustment is made. Net solid gain includes common initial equilibration. Classification and chemical reaction-pattern changes are reported separately, including charge-review flags. The amount-change criterion is $(analysis["plan"]["amount_change_threshold_mol"]) mol, a declared reporting rule.</p>$parameters<p>These finite perturbations establish local sampled distinguishability, not global identifiability, intrinsic parameter importance or statistical confidence.</p></section><section><h2>Sampled compatibility plane</h2>$svg<p>Only paths with the same environmental sequence and all other chemistry equal to the anchor are pooled here. There are $(length(plane["points"])) actual computed points and $(length(plane["unsampled_cells"])) explicitly uncomputed Cartesian combinations. The continuum between all dots remains uncomputed.</p></section><section><h2>Audit and reproduction</h2><p><a href='report.html'>Full original discovery</a> · <a href='robustness.json'>Full robustness and raw states</a> · <a href='robustness-analysis.json'>Deterministic analysis</a> · <a href='threshold-sensitivity.csv'>Threshold CSV</a> · <a href='parameter-sensitivity.csv'>OAT CSV</a></p>$raw<pre>PHREEQC_EXECUTABLE=/absolute/path/to/phreeqc julia --project=. reproduce_robustness.jl</pre><p>Uses archived source, database and both configurations. Independent endpoint experiments and historical-reference attribution are separate evidence; this analysis does not validate kinetics or a natural specimen.</p></section></html>"""
    write(joinpath(dir,"robustness.html"),page)
    write(joinpath(dir,"reproduce_robustness.jl"),"using MineralTrace\ns=load_discovery(joinpath(@__DIR__,\"discovery.toml\"))\nc=PHREEQCConfig(database=joinpath(@__DIR__,\"database.dat\"))\nr=discover_paths(s,c;root=joinpath(@__DIR__,\"reproduced-robustness\"))\nreport(r)\na=analyze_robustness(r,load_robustness(joinpath(@__DIR__,\"robustness.toml\")),c)\nprintln(report_robustness(r,a))\n")
    joinpath(dir,"robustness.html")
end
