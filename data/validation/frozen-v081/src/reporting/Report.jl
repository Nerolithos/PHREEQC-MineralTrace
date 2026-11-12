html(x)=replace(x isa AbstractDict || x isa AbstractVector ? json_value(x) : string(x),'&'=>"&amp;",'<'=>"&lt;",'>'=>"&gt;",'"'=>"&quot;",'\''=>"&#39;")
function json_value(x)
    x === nothing && return "null"
    x isa Bool && return x ? "true" : "false"
    x isa Real && return isfinite(x) ? string(x) : "null"
    x isa AbstractDict && return "{"*join([json_value(string(k))*":"*json_value(v) for (k,v) in sort(collect(x);by=p->string(first(p)))],",")*"}"
    x isa AbstractVector && return "["*join(json_value.(x),",")*"]"
    "\""*join([c=='"' ? "\\\"" : c=='\\' ? "\\\\" : Int(c)<0x20 ? "\\u"*string(Int(c);base=16,pad=4) : string(c) for c in string(x)])*"\""
end
function cell_edges(v)
    [v[1]; [(v[i]+v[i+1])/2 for i in 1:length(v)-1]; v[end]]
end
function si_color(v,limit)
    a=clamp(v/limit,-1,1); t=abs(a)
    rgb=a<0 ? (round(Int,247-210t),round(Int,249-150t),round(Int,250-75t)) : (round(Int,247-55t),round(Int,249-205t),round(Int,250-200t))
    "rgb($(join(rgb,',')))"
end

"""Render sampled SI cells and linearly interpolated SI=0 contours. No interpolation over failures."""
function figure_svg(r::ScanResult, mineral::String)
    axes=r.study.spec["axes"]; xs=Float64.(axes[1]["values"]); nx=length(xs)
    W=760; H=480; l=80; top=65; w=580; h=310
    io=IOBuffer()
    print(io,"<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 $W $H' role='img'><title>$(html(mineral)) sampled parameter scan</title><rect width='100%' height='100%' fill='white'/><g font-family='sans-serif' font-size='13' fill='#1c2736'>")
    title=mineral=="joint" ? "Joint SI compatibility at sampled points" : "$mineral saturation index"
    print(io,"<text x='$l' y='27' font-size='19'>$(html(title))</text>")
    numeric=[p["si"][mineral] for p in r.samples if mineral!="joint" && p["status"]!="failed"]
    limit=isempty(numeric) ? 1. : max(maximum(abs.(numeric)),0.01)
    if length(axes)==2
        ys=Float64.(axes[2]["values"]); ny=length(ys); xe=cell_edges(xs); ye=cell_edges(ys)
        X=x->l+w*(x-xe[1])/(xe[end]-xe[1]); Y=y->top+h-h*(y-ye[1])/(ye[end]-ye[1])
        for p in r.samples
            ix=p["ix"]; iy=p["iy"]; status=p["status"]
            color=status=="failed" ? "#c9cdd2" : mineral=="joint" ? (status=="compatible" ? "#168b76" : "#f1ddd4") : si_color(p["si"][mineral],limit)
            txt="$(p["coordinates"]); status=$status; "*(status=="failed" ? p["error"] : "SI=$(p["si"]); warnings=$(join(p["warnings"],"; "))")
            print(io,"<rect x='$(X(xe[ix]))' y='$(Y(ye[iy+1]))' width='$(X(xe[ix+1])-X(xe[ix]))' height='$(Y(ye[iy])-Y(ye[iy+1]))' fill='$color' stroke='white' stroke-width='.6'><title>$(html(txt))</title></rect>")
            if status=="failed"
                cx=X(xs[ix]); cy=Y(ys[iy]); print(io,"<path d='M $(cx-4) $(cy-4) l 8 8 m -8 0 l 8 -8' stroke='#333' fill='none'/>")
            elseif !isempty(p["warnings"])
                print(io,"<circle cx='$(X(xs[ix]))' cy='$(Y(ys[iy]))' r='2.5' fill='#111'><title>Chemical/engine warning</title></circle>")
            end
        end
        if mineral!="joint"
            for iy in 1:ny-1, ix in 1:nx-1
                ps=[r.samples[(j-1)*nx+i] for (i,j) in ((ix,iy),(ix+1,iy),(ix+1,iy+1),(ix,iy+1))]
                any(p->p["status"]=="failed",ps) && continue
                vals=[p["si"][mineral] for p in ps]; corners=[(xs[ix],ys[iy]),(xs[ix+1],ys[iy]),(xs[ix+1],ys[iy+1]),(xs[ix],ys[iy+1])]
                hits=Tuple{Float64,Float64}[]
                for (a,b) in ((1,2),(2,3),(3,4),(4,1))
                    if (vals[a]<=0<vals[b]) || (vals[b]<=0<vals[a])
                        t=-vals[a]/(vals[b]-vals[a]); push!(hits,((1-t)*corners[a][1]+t*corners[b][1],(1-t)*corners[a][2]+t*corners[b][2]))
                    end
                end
                # Ambiguous saddle cells (four crossings) are left undrawn; do not invent connectivity.
                length(hits)==2 && print(io,"<path d='M $(X(hits[1][1])) $(Y(hits[1][2])) L $(X(hits[2][1])) $(Y(hits[2][2]))' fill='none' stroke='#111' stroke-width='2'/>")
            end
        end
        for x in xs
            print(io,"<text x='$(X(x))' y='$(top+h+22)' text-anchor='middle' font-size='11'>$(html(x))</text>")
        end
        for y in ys
            print(io,"<text x='$(l-9)' y='$(Y(y)+4)' text-anchor='end' font-size='11'>$(html(y))</text>")
        end
        print(io,"<text x='15' y='50'>$(html(axes[2]["parameter"])) [$(html(axes[2]["units"]))]</text>")
        if mineral!="joint"
            for i in 0:49
                value=limit*(1-2*(i+0.5)/50)
                print(io,"<rect x='684' y='$(top+h*i/50)' width='12' height='$(h/50+0.2)' fill='$(si_color(value,limit))'/>")
            end
            for (v,y) in ((limit,top),(0.,top+h/2),(-limit,top+h))
                print(io,"<text x='702' y='$(y+4)' font-size='11'>$(round(v;digits=2))</text>")
            end
        end

    else
        X=x->l+w*(x-xs[1])/(xs[end]-xs[1])
        lim=mineral=="joint" ? 1.5 : limit*1.12
        Y=y->top+h/2-h*y/(2lim)
        print(io,"<path d='M $l $(Y(0)) h $w' stroke='#444' stroke-dasharray='5 4'/>")
        prev=nothing
        for p in r.samples
            x=X(xs[p["ix"]]); st=p["status"]
            if st=="failed"
                print(io,"<path d='M $(x-5) $(top+h-5) l 10 10 m -10 0 l 10 -10' stroke='#555'><title>Failed</title></path>")
                prev=nothing; continue
            end
            v=mineral=="joint" ? (st=="compatible" ? 1.0 : -1.0) : p["si"][mineral]; y=Y(v)
            prev!==nothing && mineral!="joint" && print(io,"<path d='M $(prev[1]) $(prev[2]) L $x $y' stroke='#267b9a' fill='none'/>")
            print(io,"<circle cx='$x' cy='$y' r='4' fill='$(st=="compatible" ? "#168b76" : "#a94132")'><title>$(html(p["coordinates"])) SI=$(html(p["si"])) warnings=$(html(p["warnings"]))</title></circle>")
            print(io,"<text x='$x' y='$(top+h+22)' text-anchor='middle' font-size='11'>$(xs[p["ix"]])</text>")
            prev=(x,y)
        end
        for v in (-lim,0,lim)
            print(io,"<text x='$(l-8)' y='$(Y(v)+4)' text-anchor='end'>$(round(v;digits=3))</text>")
        end
    end
    print(io,"<text x='$l' y='425'>$(html(axes[1]["parameter"])) [$(html(axes[1]["units"]))]</text>")
    legend=mineral=="joint" ? "Teal: SI-compatible; peach/red: incompatible; gray/X: failed. Black dots: warnings." : "Blue: negative SI; white: zero; red: positive SI. Black line: SI=0 interpolation."
    if length(axes)==1
        legend=mineral=="joint" ? "Joint: +1 SI-compatible, -1 incompatible; X failed. Review warnings in the table." : "Teal points: SI-compatible; red: incompatible; X: failed. Lines interpolate SI samples."
    end
    print(io,"<text x='20' y='450' font-size='11'>$(html(legend))</text><text x='20' y='467' font-size='11'>Cells represent samples, not a proven continuous feasible region. SI scale ±$(round(limit;digits=3)).</text></g></svg>")
    String(take!(io))
end

function scan_summary(r::ScanResult)
    points=filter(p->p["status"]=="compatible",r.samples)
    ranges=Dict(a["parameter"] => (isempty(points) ? Any[] : [minimum(p["coordinates"][a["parameter"]] for p in points),maximum(p["coordinates"][a["parameter"]] for p in points)]) for a in r.study.spec["axes"])
    sensitivity=Dict{String,Any}(); nx=length(r.study.spec["axes"][1]["values"])
    for (i,a) in enumerate(r.study.spec["axes"])
        slopes=Float64[]; name=a["parameter"]; span=last(a["values"])-first(a["values"])
        for p in r.samples
            qidx=i==1 ? (p["ix"]<nx ? (p["iy"]-1)*nx+p["ix"]+1 : 0) : (p["iy"]<length(a["values"]) ? p["iy"]*nx+p["ix"] : 0)
            qidx==0 && continue; q=r.samples[qidx]
            (p["status"]=="failed" || q["status"]=="failed") && continue
            for m in r.study.spec["minerals"]
                push!(slopes,abs(q["si"][m]-p["si"][m])/abs(q["coordinates"][name]-p["coordinates"][name])*span)
            end
        end
        sensitivity[name]=isempty(slopes) ? nothing : sum(slopes)/length(slopes)
    end
    ranked=sort([k for (k,v) in sensitivity if v!==nothing];by=k->(-sensitivity[k],k))
    Dict("sensitivity_rank"=>ranked,"compatible"=>length(points),"incompatible"=>count(p->p["status"]=="incompatible",r.samples),"failed"=>count(p->p["status"]=="failed",r.samples),"warnings"=>count(p->!isempty(p["warnings"]),r.samples),"sampled_compatible_bounds"=>ranges,"normalized_sensitivity"=>sensitivity,
        "identifiability"=>isempty(points) ? "No compatible sampled points; unsampled conditions remain undetermined." : length(points)>1 ? "Multiple compatible grid points: parameters are not uniquely identified at these tolerances." : "One compatible sampled point does not establish uniqueness between or beyond grid points.")
end

function report(r::ScanResult)
    dir=r.directory; d=r.study.spec; summary=scan_summary(r)
    contribution=constraint_contribution(r.study,r.samples)
    feasibility=feasibility_summary(r)
    document=Dict("constraint_contribution"=>contribution,"feasibility"=>feasibility,"study"=>d,"provenance"=>r.provenance,"summary"=>summary,"samples"=>r.samples)
    write(joinpath(dir,"results.json"),json_value(document)*"\n")
    analysis=Dict("study"=>d,"constraint_contribution"=>contribution,"feasibility"=>feasibility,
        "points"=>[Dict("coordinates"=>p["coordinates"],"si"=>p["si"],"evaluation"=>p["evaluation"],"charge_audit"=>get(p,"charge_audit",Dict()),"charge_diagnostic"=>get(p,"charge_diagnostic",Dict())) for p in r.samples])
    # Runtime paths/timestamps stay in results.json; this normalized scientific payload is deterministic.
    write(joinpath(dir,"analysis.json"),replace(json_value(analysis),r.directory=>"<study>")*"\n")
    cols=vcat([a["parameter"] for a in d["axes"]],["status"],d["minerals"],["warning_count","archive","error","computational_status","chemical_quality_status","model_applicability_status","observation_status","final_status","inclusion_exclusion_reasons","charge_percent","charge_eq","charge_eq_per_kgw","charge_context"])
    csv(v)="\""*replace(string(v),'"'=>"\"\"")*"\""
    open(joinpath(dir,"grid.csv"),"w") do io
        println(io,join(csv.(cols),','))
        for p in r.samples
            fields=vcat([p["coordinates"][a["parameter"]] for a in d["axes"]],[p["status"]],[get(p["si"],m,"") for m in d["minerals"]],[length(p["warnings"]),p["archive"],p["error"]],[p["evaluation"][k] for k in ("computational_status","chemical_quality_status","model_applicability_status","observation_status","final_status")],[join(p["evaluation"]["reasons"],"; ")],[get(get(p,"charge_diagnostic",Dict()),k,"") for k in ("percent_error","net_charge_eq","net_charge_eq_per_kgw","context")])
            println(io,join(csv.(fields),','))
        end
    end
    evidencecols=["id","parameter","type","units","source_id","classification","stage_id","lower","upper","value","tolerance"]
    open(joinpath(dir,"constraints.csv"),"w") do io
        println(io,join(csv.(evidencecols),','))
        for c in get(d,"constraints",Any[])
            println(io,join(csv.([get(c,k,"") for k in evidencecols]),','))
        end
    end
    open(joinpath(dir,"constraint-evaluations.csv"),"w") do io
        println(io,"coordinates,constraint_id,classification,value_status,effective_status,source_status")
        for p in r.samples, q in p["evaluation"]["constraints"]
            println(io,join(csv.([json_value(p["coordinates"]),q["id"],q["classification"],q["value_status"],q["effective_status"],q["source_status"]]),','))
        end
    end
    open(joinpath(dir,"constraint-contribution.csv"),"w") do io
        println(io,"track,id,before,after,removed,without_count,added_count")
        for (track,seq,loo) in (("SI_and_chemistry",contribution["sequential"],contribution["leave_one_out"]),("final_policy",contribution["final_sequential"],contribution["final_leave_one_out"]))
            for (q,l) in zip(seq,loo)
                println(io,join(csv.([track,q["id"],q["before"],q["after"],q["removed"],l["without_count"],l["added_count"]]),','))
            end
        end
    end
    figures=String[]
    for m in vcat(d["minerals"],["joint"])
        svg=figure_svg(r,m); write(joinpath(dir,"$m.svg"),svg); push!(figures,svg)
    end
    for mask in ("chemical","model","observations","final","warnings","exclusions","computational")
        svg=mask_svg(r,mask);write(joinpath(dir,"$mask.svg"),svg);push!(figures,svg)
    end
    table=IOBuffer(); print(table,"<table><tr><th>Coordinates</th><th>Status (SI only)</th><th>SI</th><th>Computation / chemistry / model / observation / final</th><th>Exclusion or qualification reasons</th><th>Charge percent / eq per kgw / context</th><th>Warnings / error</th><th>Raw archive</th></tr>")
    for p in r.samples
        print(table,"<tr><td>$(html(p["coordinates"]))</td><td>$(html(p["status"]))</td><td>$(html(p["si"]))</td><td>$(html(join([p["evaluation"][k] for k in ("computational_status","chemical_quality_status","model_applicability_status","observation_status","final_status")]," / ")))</td><td>$(html(join(p["evaluation"]["reasons"],"; ")))</td><td>$(html([get(get(p,"charge_diagnostic",Dict()),k,"unavailable") for k in ("percent_error","net_charge_eq_per_kgw","context")]))</td><td>$(html(join(p["warnings"],"; ")*p["error"]))</td><td><a href='$(html(p["archive"]))/manifest.toml'>$(html(p["archive"]))</a></td></tr>")
    end
    print(table,"</table>")
    label=d["mode"]=="HypothesisExplorer" ? "Conditional on assumed fluid composition ranges" : "Conditional on supplied fluid analysis; scanned values remain user-declared assumptions"
    boundsrows=join(["<tr><td>$(html(a["parameter"])) [$(html(a["units"]))]</td><td>$(html(summary["sampled_compatible_bounds"][a["parameter"]]))</td><td>$(html(summary["normalized_sensitivity"][a["parameter"]]))</td></tr>" for a in d["axes"]])
    text="""<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>MineralTrace study</title>
    <style>body{font:16px/1.55 system-ui,sans-serif;max-width:1120px;margin:40px auto;padding:0 22px;color:#20303c;background:#f5f7fa}header,section{background:white;padding:24px;margin:20px 0;border:1px solid #dce2e8;border-radius:10px}h1{line-height:1.2}svg{width:100%;height:auto}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#f2f5f7;padding:16px;font-size:12px}table{border-collapse:collapse;width:100%;font-size:12px}td,th{padding:8px;border:1px solid #dce2e8;text-align:left;overflow-wrap:anywhere}.notice{border-left:5px solid #bd6d28;padding-left:14px}a{color:#126b86}</style>
    <header><p>MineralTrace · Mineral Formation Constraint Explorer</p><h1>$(html(join(d["minerals"]," + "))) constraint study</h1><p class="notice">$(html(label))</p><p>$(summary["compatible"]) SI-compatible · $(summary["incompatible"]) incompatible · $(summary["failed"]) failed · $(summary["warnings"]) with warnings</p><p>$(html(summary["identifiability"]))</p></header>
    <section><h2>Quality gates and final candidate region</h2><p><strong>Final inclusion: $(feasibility["counts"]["final_feasible"]) sampled points; $(feasibility["final_status_counts"]["included_conditional"]) conditional. Evaluation mode: $(html(feasibility["evaluation_mode"])).</strong></p><pre>$(html(feasibility))</pre><p>Strict mode requires verified applicability and documented evidence. Exploratory inclusion is explicitly conditional: model applicability is still unverified. Charge failures are excluded in both modes. No point is a confirmed formation environment.</p><p>Computational success, chemical admissibility, model applicability and observations are separate statuses. A charge threshold is a configurable diagnostic requirement, not a universal water-quality standard or validation of the activity model. Exceedances are policy exclusions, not proof of physical impossibility. Hypothetical and partial fluids do not provide a complete analytical charge-balance error. Stage assignments are user evidence, not inferred chronology.</p></section>
    <section><h2>Constraint contribution</h2><pre>$(html(contribution))</pre><p>Baseline = raw SI-compatible AND chemistry-pass points, before evidence and the applicability gate. The separate final track additionally applies model eligibility, so strict mode can have zero final baseline even when SI/chemistry candidates exist. Sequential counts follow TOML constraint order. Leave-one-out removes exactly one constraint while retaining all others; redundancy and conflicts are relative to this grid. Counts and fractions are not physical probabilities.</p><h3>Evidence definitions</h3><pre>$(html(get(d,"constraints",Any[])))</pre><p>Missing source identifiers remain absent. Observations are user-provided records, not independently authenticated by this software. Missing sources prevent strict inclusion; exploratory use is labelled conditional.</p></section>
    <section><h2>Interpretation and limits</h2><ul>$(join(["<li>$(html(w))</li>" for w in r.provenance["warnings"]]))</ul><p>Classification: fluid origin = $(html(d["fluid"]["origin"])); all scan axes and same-stage equilibrium = Assumption; PHREEQC SI = Calculation; compatibility = conditional Inference; unsampled states and actual geological history = Undetermined.</p><p>Incompatible means outside declared SI tolerances under this model, not geologically excluded under all possible fluids.</p><p>No precipitation, dissolution, kinetics, or formation order is simulated in this speciation scan.</p></section>
    <section><h2>Sampled bounds and sensitivity</h2><table><tr><th>Axis</th><th>Sampled compatible min/max</th><th>Normalized SI sensitivity</th></tr>$boundsrows</table><p>Sensitivity ranking (largest first): $(html(join(summary["sensitivity_rank"],", "))).</p><p>Bounds enclose sampled compatible points, not a continuous confidence interval. Sensitivity is mean absolute adjacent-point SI slope multiplied by the full axis span, averaged across minerals. It depends on chosen ranges and is not information gain or statistical identifiability.</p></section>
    $(join(["<section>$svg</section>" for svg in figures]))
    <section><h2>Complete inputs and assumptions</h2><p>Fixed values for scanned variables are replaced only at the declared coordinates. Unlisted aqueous elements are excluded from this simplified model; no missing concentrations are estimated.</p><pre>$(html(read(joinpath(dir,"study.toml"),String)))</pre></section>
    <section><h2>Source versions and reproduction</h2><pre>$(html(json_value(r.provenance)))</pre><p>This HTML contains all plots, input settings and point results; no network or server is needed to read it. Keep the full folder to inspect raw archives or reproduce the computation.</p><p><a href="grid.csv">Grid CSV</a> · <a href="results.json">Full JSON</a> · <a href="study.toml">Study TOML</a> · <a href="provenance.toml">Provenance</a></p><pre>PHREEQC_EXECUTABLE=/absolute/path/to/phreeqc julia --project=. reproduce.jl</pre><p>Run from the archived study folder with Julia installed. Archived database and source code are used. Check executable hash against provenance; a different build is not the identical computational environment.</p></section>
    <section><h2>All sample points</h2>$(String(take!(table)))</section></html>"""
    path=joinpath(dir,"report.html"); write(path,text); path
end

function feasibility_summary(r::ScanResult)
    ev=[p["evaluation"] for p in r.samples]
    remaining=[p for p in r.samples if p["evaluation"]["regions"]["final_feasible"]]
    Dict("included_grid_components"=>grid_components(r.samples),"evaluation_mode"=>get(get(r.study.spec,"evaluation",Dict()),"mode","exploratory"),
        "counts"=>Dict(k=>count(e->e["regions"][k]===true,ev) for k in ("raw_si","chemically_admissible","observation_constrained","final_feasible","unverified")),
        "final_status_counts"=>Dict(k=>count(e->e["final_status"]==k,ev) for k in ("included","included_conditional","excluded","unverified")),
        "remaining_sampled_ranges"=>Dict(a["parameter"]=>isempty(remaining) ? Any[] : [minimum(p["coordinates"][a["parameter"]] for p in remaining),maximum(p["coordinates"][a["parameter"]] for p in remaining)] for a in r.study.spec["axes"]),
        "identifiability"=>isempty(remaining) ? "No included sampled points; this is not proof of global impossibility." : length(remaining)>1 ? "Multiple included sampled points; no unique parameters identified." : "One included sampled point does not establish uniqueness.")
end

function mask_svg(r::ScanResult,mask)
    axes=r.study.spec["axes"];xs=Float64.(axes[1]["values"]);xe=cell_edges(xs)
    two=length(axes)==2;ys=two ? Float64.(axes[2]["values"]) : [0.,1.];ye=cell_edges(ys)
    X=x->80+580*(x-xe[1])/(xe[end]-xe[1]);Y=y->370-280*(y-ye[1])/(ye[end]-ye[1])
    io=IOBuffer();print(io,"<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 760 460' role='img'><title>$(html(mask)) mask</title><rect width='100%' height='100%' fill='white'/><g font-family='sans-serif' font-size='12'><text x='80' y='30' font-size='19'>$(html(mask)) mask — separate from SI</text>")
    for p in r.samples
        e=p["evaluation"]
        state=mask=="warnings" ? (!isempty(p["warnings"]) ? "warning" : "pass") : mask=="exclusions" ? (e["final_status"]=="excluded" ? "fail" : e["final_status"]=="unverified" ? "unknown" : "pass") : mask=="chemical" ? e["chemical_quality_status"] : mask=="model" ? e["model_applicability_status"] : mask=="observations" ? (e["regions"]["observation_constrained"]===nothing ? "unknown" : e["regions"]["observation_constrained"] ? "pass" : "fail") : mask=="computational" ? (e["computational_status"]=="success" ? "pass" : "fail") : (e["final_status"]=="included" ? "pass" : e["final_status"]=="included_conditional" ? "conditional" : e["final_status"]=="excluded" ? "fail" : "unknown")
        color=state in ("pass","verified") ? "#168b76" : state in ("fail","invalid") ? "#b94b40" : state in ("warning","conditional") ? "#e6b54a" : "#c9cdd2"
        ix=p["ix"];iy=p["iy"];x=X(xe[ix]);width=X(xe[ix+1])-x;y=two ? Y(ye[iy+1]) : 110.;height=two ? Y(ye[iy])-y : 190.
        print(io,"<rect x='$x' y='$y' width='$width' height='$height' fill='$color' stroke='white'><title>$(html(p["coordinates"])): $state; $(html(e["reasons"]))</title></rect>")
    end
    for x in xs
        print(io,"<text x='$(X(x))' y='395' text-anchor='middle'>$(html(x))</text>")
    end
    if two
        for y in ys
            print(io,"<text x='70' y='$(Y(y)+4)' text-anchor='end'>$(html(y))</text>")
        end
    end
    print(io,"<text x='80' y='60'>$(two ? html(axes[2]["parameter"])*" ["*html(axes[2]["units"])*"]" : "one-dimensional samples")</text><text x='80' y='418'>$(html(axes[1]["parameter"])) [$(html(axes[1]["units"]))]</text><text x='20' y='445'>Green: pass/included; red: fail/excluded; amber: warning/conditional; gray: unverified.</text></g></svg>")
    String(take!(io))
end
