function process_figure(r::ProcessResult,kind)
    steps=r.steps;elements=PROCESS_ELEMENTS
    if kind=="pH"
        title="pH evolution";units="pH";series=[("pH",[s["pH"] for s in steps])]
    elseif kind=="SI"
        title="Monitored mineral saturation indices";units="SI";series=[(m,[s["si"][m] for s in steps]) for m in r.process.spec["minerals"]]
    elseif kind=="species"
        title="Dissolved carbonate species";units="mol/kgw";series=[(name,[parse(Float64,s["selected"]["m_$name"]) for s in steps]) for name in ("HCO3-","CO3-2","CO2")]
    elseif kind=="charge_percent"
        title="Charge residual: percentage diagnostic";units="percent";series=[("charge error",[s["charge_diagnostic"]["percent_error"] for s in steps])]
    elseif kind=="charge_equivalents"
        title="Signed charge residual in equivalent units";units="eq/kgw";series=[("net charge",[s["charge_diagnostic"]["net_charge_eq_per_kgw"] for s in steps])]
    else
        title="Element inventory residuals: actual minus expected";units="mol";series=[(e,[s["element_balance"][e]["residual_mol"] for s in steps]) for e in elements]
    end
    xs=[s["cumulative_added_mol"] for s in steps];xmax=maximum(xs);xspan=xmax==0 ? 1. : xmax
    ys=vcat([y for (_,y) in series]...);low=minimum(ys);high=maximum(ys);pad=max((high-low)*0.08,max(abs(low),abs(high))*0.03,1e-12);lo=low-pad;hi=high+pad
    X=x->80+580*x/xspan;Y=y->350-270*(y-lo)/(hi-lo)
    colors=["#176c91","#b74040","#2d8666","#aa6b19","#8755aa","#60717c","#b44983"]
    io=IOBuffer();print(io,"<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 780 520' role='img'><title>$(html(title))</title><rect width='100%' height='100%' fill='white'/><g font-family='sans-serif' font-size='12' fill='#20303c'><text x='80' y='28' font-size='19'>$(html(title))</text><text x='20' y='57'>$(html(units))</text>")
    for f in (0.,0.25,0.5,0.75,1.)
        v=lo+(hi-lo)*f;y=Y(v)
        print(io,"<path d='M 80 $y H 660' stroke='#dce2e8'/><text x='72' y='$(y+4)' text-anchor='end'>$(round(v;sigdigits=3))</text>")
    end
    for x in (xmax==0 ? [0.] : [xmax*f for f in (0.,0.25,0.5,0.75,1.)])
        print(io,"<text x='$(X(x))' y='373' text-anchor='middle'>$(round(x;sigdigits=3))</text>")
    end
    for (i,(label,values)) in enumerate(series)
        color=colors[mod1(i,length(colors))];coords=join(["$(X(x)),$(Y(y))" for (x,y) in zip(xs,values)]," ")
        print(io,"<polyline points='$coords' fill='none' stroke='$color' stroke-width='2'/>")
        for (s,x,y) in zip(steps,xs,values)
            print(io,"<circle cx='$(X(x))' cy='$(Y(y))' r='3' fill='$color'><title>step $(s["step"]); added cumulative $x mol; $(html(label)) = $y</title></circle>")
        end
        print(io,"<text x='$(80+200mod(i-1,3))' y='$(430+21div(i-1,3))' fill='$color'>$(html(label))</text>")
    end
    print(io,"<text x='80' y='400'>Cumulative $(html(r.process.spec["titrant"]["identity"])) formula addition [mol]</text><text x='20' y='505'>Actual PHREEQC steps; connecting lines are guides, not kinetic trajectories or measured data.</text></g></svg>")
    String(take!(io))
end

function report(r::ProcessResult)
    dir=r.directory;d=r.process.spec
    assumptions=["Closed aqueous formula-addition process at fixed temperature and pressure; only the initial pH is imposed. Subsequent pH is calculated by PHREEQC REACTION.",
        "HCl/NaOH are neutral formula additions with explicit atom stoichiometry. No carrier-water volume, dilution, gas exchange, solids, precipitation, dissolution, sorption or kinetics is simulated.",
        "Minerals are monitored by SI only. Supersaturation is not observed or guaranteed precipitation. No formation environment or chronology is inferred.",
        "The initial charge residual is not silently corrected. Neutral additions should conserve its absolute equivalents even if percentage error changes.",
        "0.1% is a configurable legacy diagnostic threshold, not a universal water-quality standard. Threshold violations do not prove physical impossibility.",
        "Model/species and activity-temperature applicability remain unverified; CaF+ is inactive in the locked database. Explicit initial totals are a simplified chemical inventory, not automatically a complete natural-fluid analysis.",
        "Engine validation and chemical accounting are not experimental validation. No suitable full experimental comparison was completed in this sprint; see the registered reference review and missing-input reasons."]
    summary=Dict("reaction_steps"=>length(r.steps)-1,"all_mass_balance_checks_pass"=>all(s->s["mass_balance_pass"],r.steps),"all_charge_conservation_checks_pass"=>all(s->s["charge_conservation_pass"],r.steps),"charge_diagnostic_exceedances"=>count(s->s["charge_diagnostic"]["diagnostic_status"]=="exceeds_declared_threshold",r.steps),"experimental_comparison"=>"not_completed_insufficient_verified_inputs_for_supported_process")
    casepath=joinpath(dir,"data","validation","experimental-case-v040.json")
    reference=isfile(casepath) ? read(casepath,String) : "No reference registry available in this archive."
    document=Dict("process"=>d,"summary"=>summary,"steps"=>r.steps,"provenance"=>r.provenance,"assumptions"=>assumptions,"reference_case_json"=>reference)
    write(joinpath(dir,"results.json"),json_value(document)*"\n")
    write(joinpath(dir,"analysis.json"),json_value(Dict("process"=>d,"steps"=>r.steps,"summary"=>summary,"assumptions"=>assumptions,"reference_case_json"=>reference))*"\n")
    csv(v)="\""*replace(string(v),'"'=>"\"\"")*"\""
    selected_columns=sort(collect(keys(r.steps[1]["selected"])))
    columns=vcat(["step","added_mol","cumulative_added_mol","pH","net_charge_eq","net_charge_eq_per_kgw","net_charge_meq_per_kgw","percent_error","charge_change_eq","charge_conservation_pass","mass_balance_pass"],["SI_$m" for m in d["minerals"]],["residual_$(e)_mol" for e in PROCESS_ELEMENTS],["selected_$k" for k in selected_columns])
    open(joinpath(dir,"steps.csv"),"w") do io
        println(io,join(csv.(columns),','))
        for s in r.steps
            vals=vcat([s["step"],s["added_mol"],s["cumulative_added_mol"],s["pH"],s["charge_diagnostic"]["net_charge_eq"],s["charge_diagnostic"]["net_charge_eq_per_kgw"],s["charge_diagnostic"]["net_charge_meq_per_kgw"],s["charge_diagnostic"]["percent_error"],s["charge_change_eq"],s["charge_conservation_pass"],s["mass_balance_pass"]],[s["si"][m] for m in d["minerals"]],[s["element_balance"][e]["residual_mol"] for e in PROCESS_ELEMENTS],[s["selected"][k] for k in selected_columns])
            println(io,join(csv.(vals),','))
        end
    end
    open(joinpath(dir,"balances.csv"),"w") do io
        println(io,"step,element,expected_mol,actual_mol,residual_mol,tolerance_mol,pass")
        for s in r.steps,e in PROCESS_ELEMENTS
            b=s["element_balance"][e];println(io,join(csv.([s["step"],e,b["expected_mol"],b["actual_mol"],b["residual_mol"],b["tolerance_mol"],b["pass"]]),','))
        end
    end
    open(joinpath(dir,"charge-species.csv"),"w") do io
        println(io,"step,species,molality_mol_per_kgw,charge,signed_eq_per_kgw,precision")
        for s in r.steps, species in s["rounded_charge_inventory"]["species"]
            println(io,join(csv.([s["step"],species["name"],species["molality_mol_per_kgw"],species["charge"],species["signed_eq_per_kgw"],"rounded raw species table"]),','))
        end
    end
    figures=String[]
    for kind in ("pH","SI","species","charge_percent","charge_equivalents","mass_balance")
        svg=process_figure(r,kind);write(joinpath(dir,"$kind.svg"),svg);push!(figures,svg)
    end
    rows=join(["<tr><td>$(s["step"])</td><td>$(s["added_mol"])</td><td>$(s["cumulative_added_mol"])</td><td>$(s["pH"])</td><td>$(html(s["si"]))</td><td>$(s["charge_diagnostic"]["percent_error"])</td><td>$(s["charge_diagnostic"]["net_charge_eq_per_kgw"])</td><td>$(s["mass_balance_pass"]) / $(s["charge_conservation_pass"])</td></tr>" for s in r.steps])
    raw=html(r.provenance["raw_archive"])
    body="""<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>MineralTrace chemical process</title><style>body{font:16px/1.55 system-ui;max-width:1100px;margin:36px auto;padding:0 20px;background:#f5f7fa;color:#20303c}section,header{background:white;padding:24px;margin:18px 0;border:1px solid #dce2e8;border-radius:9px}svg{width:100%;height:auto}pre{white-space:pre-wrap;overflow-wrap:anywhere;font-size:12px;background:#f0f3f5;padding:14px}table{border-collapse:collapse;width:100%;font-size:12px}td,th{border:1px solid #ddd;padding:7px;overflow-wrap:anywhere}a{color:#126b86}</style>
    <header><p>MineralTrace v$(html(r.provenance["package_version"])) · controlled chemical process</p><h1>$(html(d["titrant"]["identity"])) acid–base titration</h1><p>Initial origin: $(html(d["initial"]["origin"])); $(html(d["initial"]["label"]))</p><pre>$(html(summary))</pre></header>
    <section><h2>Model and charge semantics</h2><ul>$(join(["<li>$(html(a))</li>" for a in assumptions]))</ul><pre>$(html(r.steps[1]["charge_diagnostic"]))</pre></section>
    $(join(["<section>$svg</section>" for svg in figures]))
    <section><h2>Initial composition and explicit reaction additions</h2><pre>$(html(read(joinpath(dir,"process.toml"),String)))</pre><p>Atoms per formula: $(html(TITRANT_ATOMS[d["titrant"]["identity"]])). Each amount is incremental mol, not molarity or a volume. Ca/F/C/Na/Cl initial inventories are checked against declared mol/kgw × initial kg water. H/O use the engine initial inventory as baseline, then independently count added reagent atoms, including water; molalities are not assumed to be moles when water mass changes.</p></section>
    <section><h2>Step results</h2><table><tr><th>Step</th><th>Added mol</th><th>Cumulative mol</th><th>pH</th><th>SI</th><th>Charge %</th><th>Charge eq/kgw</th><th>Mass / charge conservation</th></tr>$rows</table><p>Conservation compares initial aqueous inventories plus known reagent atoms with actual inventories at each step, and net equivalents with initial net equivalents. No balance is silently forced by editing initial totals.</p><a href="steps.csv">All species and step results CSV</a> · <a href="balances.csv">Every element balance CSV</a> · <a href="charge-species.csv">All rounded species charge contributions</a></section>
    <section><h2>Three distinct validation levels</h2><p>Engine: direct CLI comparison is tested separately. Chemistry: atom/charge accounting shown above is independently checked against declared additions. Experiment: not completed; scalar log K checks from earlier versions do not substitute for a measured titration curve.</p><pre>$(html(reference))</pre></section>
    <section><h2>Provenance and reproduction</h2><pre>$(html(r.provenance))</pre><p><a href="reaction.pqi">PHREEQC deck</a> · <a href="$raw/output.pqo">Raw PHREEQC output</a> · <a href="results.json">Full JSON</a> · <a href="analysis.json">Deterministic scientific payload</a></p><pre>PHREEQC_EXECUTABLE=/absolute/path/to/phreeqc julia --project=. reproduce.jl</pre><p>Run from the archived process folder. Keep the full folder for raw results, source code, database and reproduction. The HTML figures and tables can be read independently offline.</p></section></html>"""
    path=joinpath(dir,"report.html");write(path,body);path
end
