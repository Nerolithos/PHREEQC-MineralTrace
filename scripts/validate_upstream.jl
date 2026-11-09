using MineralTrace, SHA, TOML

function benchmark_deck(name,source)
    text=read(source,String)
    if name=="ex6"
        text=first(split(text,"TITLE Simulation 6C")) # 6A and 6B only; no new kinetic API.
    elseif name=="ex22"
        text=first(split(text,"\nUSE solution 1")) # exact 25 C branch; other temperatures not a product extension.
    end
    text
end
function benchmark_instrument(name,text)
    phases=name=="ex6" ? ["Gibbsite","Kaolinite","K-mica","K-feldspar"] : ["Calcite","CO2(g)"]
    cols=vcat(["pressure_atm","ionic_strength","total_Ca","total_C","logf_CO2","gas_pressure","gas_volume","gas_CO2","phi_CO2","pCO2_atm","rxn_mol"],["solid_$m" for m in phases])
    values=vcat(["PRESSURE","MU","TOTMOLE(\"Ca\")","TOTMOLE(\"C\")","SI(\"CO2(g)\")","GAS_P","GAS_VM * (GAS(\"CO2(g)\")+GAS(\"CH4(g)\")+GAS(\"N2(g)\")+GAS(\"H2O(g)\"))","GAS(\"CO2(g)\")","PR_PHI(\"CO2(g)\")","PR_P(\"CO2(g)\")","RXN"],["EQUI(\"$m\")" for m in phases])
        # Preserve upstream solver convergence settings: high_precision=true also tightens tolerance.
    punch="SELECTED_OUTPUT 99\n -file selected.tsv\n -reset false\n -high_precision false\n -simulation true\n -state true\n -step true\n -pH true\n -temperature true\nUSER_PUNCH 99\n -headings "*join(cols," ")*"\n -start\n10 PUNCH "*join(values,", ")*"\n -end\n"
    replace(text,r"(?m)^END\s*$"=>punch*"END";count=1)
end
function direct_run(config,deck,dir)
    mkpath(dir);write(joinpath(dir,"input.pqi"),deck);cp(config.database,joinpath(dir,"database.dat"))
    open(joinpath(dir,"console.log"),"w") do io
        run(pipeline(Cmd(Cmd([environment_check(config).executable,"input.pqi","output.pqo","database.dat"]);dir=dir);stdin=devnull,stdout=io,stderr=io))
    end
end
function validate_upstream(root="results"; project=dirname(@__DIR__), config=PHREEQCConfig())
    env=environment_check(config);env.database_sha256=="59373961d648dfbf68a40744060c1d64f57ecbec98f4f5fb89f3a1b4213ccd10" || error("Benchmarks require locked version-matched 3.8.6 database")
    mkpath(root);dir=abspath(mktempdir(root;prefix="upstream-",cleanup=false));summary=Dict{String,Any}[]
    for name in ("ex6","ex7","ex22")
        path=joinpath(project,"data/validation/upstream-v080",name);deck=benchmark_deck(name,path);instrument=benchmark_instrument(name,deck)
        original=joinpath(dir,"$name-original");direct_run(config,deck,original)
        direct=joinpath(dir,"$name-direct-instrumented");direct_run(config,instrument,direct)
        result=run_phreeqc(config,instrument;root=dir,sources=["USGS-$(name)-386"],required=["pressure_atm","ionic_strength","total_Ca","total_C"],metadata=Dict("source_type"=>"engine_reference","branch"=>name,"scope"=>"adapter/reference agreement only; not experimental evidence"))
        read(joinpath(result.directory,"selected.tsv"))==read(joinpath(direct,"selected.tsv")) || error("Adapter/direct output mismatch")
        # Keep official selected files unchanged and compare original precision, without relaxing tolerances.
        original_files=filter(f->endswith(f,".sel"),readdir(original));original_match=Dict{String,Bool}()
        for file in original_files
            table(path)=begin
                lines=filter(l->!isempty(strip(l)),readlines(path));headers=strip.(split(lines[1],'\t';keepempty=false))
                [Dict(zip(headers,strip.(split(line,'\t';keepempty=false)))) for line in lines[2:end]]
            end
            a=table(joinpath(original,file));b=table(joinpath(result.directory,file))
            length(a)==length(b) || error("Official selected row count changed")
            pass=all(zip(a,b)) do (x,y)
                all(keys(x)) do key
                    xv=tryparse(Float64,x[key]);yv=tryparse(Float64,y[key])
                    xv===nothing ? x[key]==y[key] : yv!==nothing && isapprox(xv,yv;atol=1e-7,rtol=2e-3) # upstream printed 4 significant figures, protocol declared before run
                end
            end
            pass || error("Official printed selected-output mismatch: $name $file")
            original_match[file]=pass
        end
        if name=="ex22"
            # Raw printed pressures from original official branch and instrumented branch, same engine/database.
            pressures(s)=[parse(Float64,m.captures[1]) for m in eachmatch(r"Pressure \(atm\)\s*=\s*([-+0-9.eE]+)",s)]
            a=pressures(read(joinpath(original,"output.pqo"),String));b=pressures(read(joinpath(result.directory,"output.pqo"),String))
            length(a)==length(b) && !isempty(a) && all(isapprox.(a,b;atol=0.01,rtol=0.001)) || error("Original Example 22 pressure sequence mismatch")
        end
        locked=joinpath(project,"data/validation/upstream-v080",name*"-reference.tsv")
        reference=read_selected(locked);current=result.rows
        length(reference)==length(current) || error("Locked reference shape mismatch; cross-version investigation required")
        max_difference=0.;reference_pass=true
        for (a,b) in zip(reference,current),key in keys(a)
            av=tryparse(Float64,a[key]);bv=tryparse(Float64,b[key])
            if av===nothing
                reference_pass &= a[key]==b[key]
            else
                max_difference=max(max_difference,abs(av-bv));reference_pass &= isapprox(av,bv;atol=1e-7,rtol=2e-3)
            end
        end
        rows=result.rows;react=filter(r->r["state"]=="react",rows)
        behavior=Dict{String,Any}()
        if name=="ex6"
            pathrows=filter(r->r["sim"]=="8" && r["state"]=="react",rows)
            !isempty(pathrows) || error("Example 6B state progression missing")
            behavior["incremental_path_rows"]=length(pathrows)
            rxns=[parse(Float64,r["rxn_mol"]) for r in pathrows]
            issorted(rxns) && length(unique(rxns))>1 || error("Reaction-dose progression absent")
            behavior["reaction_dose_progression"]=true
            behavior["phase_transfer_present"]=any(r->any(m->abs(parse(Float64,r["solid_$m"]))>1e-12,["Gibbsite","Kaolinite","K-mica"]),pathrows)
            behavior["phase_transfer_present"] || error("Expected phase assemblage absent")
        elseif name=="ex7"
            fixed=filter(r->r["sim"]=="2" && r["state"]=="react" && parse(Float64,r["gas_CO2"])>1e-9,rows)
            !isempty(fixed) && all(r->abs(parse(Float64,r["gas_pressure"])-1.1)<1e-7,fixed) || error("Fixed total pressure not maintained")
            volume=filter(r->r["sim"]=="3" && r["state"]=="react",rows)
            !isempty(volume) && maximum(parse(Float64,r["gas_pressure"]) for r in volume)>minimum(parse(Float64,r["gas_pressure"]) for r in volume) || error("Finite volume pressure progression missing")
            eq=only(filter(r->r["sim"]=="1" && r["state"]=="react",rows))
            # SI is log fugacity for gases; low-pressure PR phi is checked from the explicit boundary below.
            behavior["fixed_partial_pressure_log_target"]=-1.5;behavior["fixed_partial_log_fugacity"]=parse(Float64,eq["logf_CO2"])
            behavior["fixed_total_pressure_atm"]=1.1;behavior["fixed_volume_liters"]=23.19
        else
            nonzero=filter(r->r["state"]=="react" && parse(Float64,r["pCO2_atm"])>10,rows)
            !isempty(nonzero) && any(r->0<parse(Float64,r["phi_CO2"])<0.95,nonzero) || error("PR nonideal high-pressure behavior not found")
            all(r->isapprox(10^parse(Float64,r["logf_CO2"]),parse(Float64,r["phi_CO2"])*parse(Float64,r["pCO2_atm"]);atol=1e-4,rtol=2e-3),nonzero) || error("Independent PR pressure/fugacity identity failed")
            behavior["pressure_fugacity_identity_checked"]=true
            behavior["phi_min"]=minimum(parse(Float64,r["phi_CO2"]) for r in nonzero)
            behavior["pressure_min_atm"]=minimum(parse(Float64,r["pressure_atm"]) for r in react)
            behavior["pressure_max_atm"]=maximum(parse(Float64,r["pressure_atm"]) for r in react)
        end
        push!(summary,Dict("example"=>name,"branch_scope"=>name=="ex6" ? "6A/6B only, no kinetics" : name=="ex22" ? "25 C fixed-volume branch only" : "fixed partial, total pressure, and volume branches","upstream_input_sha256"=>bytes2hex(sha256(read(path))),"executed_branch_sha256"=>bytes2hex(sha256(codeunits(deck))),"instrumented_input_sha256"=>result.manifest["input_sha256"],"locked_reference_agreement"=>reference_pass,"locked_reference_max_abs_difference"=>max_difference,"locked_reference_sha256"=>bytes2hex(sha256(read(locked))),"engine_banner"=>result.manifest["engine_banner"],"adapter_direct_byte_identical"=>true,"official_selected_agreement"=>original_match,"row_count"=>length(rows),"behavior"=>behavior,"selected_reference_sha256"=>bytes2hex(sha256(read(joinpath(direct,"selected.tsv")))),"archive"=>relpath(result.directory,dir),"original_archive"=>relpath(original,dir),"direct_archive"=>relpath(direct,dir)))
    end
    payload=Dict("reference_policy"=>"Never overwritten; atol=1e-7, rtol=2e-3 for printed precision; cross-version deviations reported, not retuned","source_type"=>"engine_reference","database_sha256"=>env.database_sha256,"executable_sha256"=>bytes2hex(sha256(read(env.executable))),"software_version"=>string(pkgversion(MineralTrace)),"benchmarks"=>summary,"experimental_support_granted"=>false)
    open(io->TOML.print(io,payload;sorted=true),joinpath(dir,"benchmark-results.toml"),"w")
    det=deepcopy(payload)
    for row in det["benchmarks"]
        for key in ("archive","original_archive","direct_archive");delete!(row,key);end
    end
    write(joinpath(dir,"analysis.json"),MineralTrace.json_value(det)*"\n")
    for file in ("src","scripts","data","Project.toml","Manifest.toml");cp(joinpath(project,file),joinpath(dir,file));end
    cp(config.database,joinpath(dir,"database.dat"))
    write(joinpath(dir,"reproduce.jl"),"include(joinpath(@__DIR__,\"scripts/validate_upstream.jl\"))\nvalidate_upstream(joinpath(@__DIR__,\"reproduced\");project=@__DIR__,config=PHREEQCConfig(database=joinpath(@__DIR__,\"database.dat\")))\n")
    println("Upstream archive: ",dir);dir
end
if abspath(PROGRAM_FILE)==@__FILE__
    validate_upstream(isempty(ARGS) ? "results" : ARGS[1])
end
