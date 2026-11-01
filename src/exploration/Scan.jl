struct ScanResult
    study::MineralStudy
    samples::Vector{Dict{String,Any}}
    directory::String
    provenance::Dict{String,Any}
end
"""Strict |SI| < user tolerance; missing values are undetermined, never incompatible."""
function compatibility(si, tolerances)
    !isempty(tolerances) && all(v->v isa Real && isfinite(v) && v>0,values(tolerances)) || throw(ArgumentError("positive finite nonempty tolerances required"))
    any(m->!haskey(si,m) || isnothing(si[m]) || !isfinite(si[m]),keys(tolerances)) && return "failed"
    all(m->abs(si[m]) < tolerances[m],keys(tolerances)) ? "compatible" : "incompatible"
end

function scan(s::MineralStudy, c::PHREEQCConfig=PHREEQCConfig(); root="results")
    env=environment_check(c) # missing installation is a study-level error, not fabricated grid results
    mkpath(root); dir=abspath(mktempdir(root;prefix="study-",cleanup=false))
    open(io->TOML.print(io,s.spec;sorted=true),joinpath(dir,"study.toml"),"w")
    cp(env.database,joinpath(dir,"database.dat"))
    # Archive the actual Julia implementation needed for reproduction.
    cp(dirname(@__DIR__),joinpath(dir,"src"))
    project=dirname(dirname(@__DIR__))
    cp(joinpath(project,"Project.toml"),joinpath(dir,"Project.toml"))
    cp(joinpath(project,"Manifest.toml"),joinpath(dir,"Manifest.toml"))
    mkpath(joinpath(dir,"data"))
    cp(joinpath(project,"data","sources"),joinpath(dir,"data","sources"))
    mkpath(joinpath(dir,"data","validation"))
    for f in ("EXAMPLE1_INVESTIGATION.md","CAF_C_BENCHMARK.md","ex1-current-engine.toml","DATABASE_REVIEW.md","CHEMICAL_QUALITY_AUDIT.md","SCIENTIFIC_VALIDATION.md","independent-reference-checks.toml","independent-parameter-results.md","chemical-quality-audit.csv","v020-scan-regression.toml")
        isfile(joinpath(project,"data","validation",f)) && cp(joinpath(project,"data","validation",f),joinpath(dir,"data","validation",f))
    end
    upstream=joinpath(project,"data","validation","upstream-v3.8.6")
    isdir(upstream) && cp(upstream,joinpath(dir,"data","validation","upstream-v3.8.6"))
    write(joinpath(dir,"reproduce.jl"),"using MineralTrace\ns = load_study(joinpath(@__DIR__,\"study.toml\"))\nc = PHREEQCConfig(database=joinpath(@__DIR__,\"database.dat\"),timeout_seconds=$(c.timeout_seconds))\nr = scan(s,c;root=joinpath(@__DIR__,\"reproduced\"))\nprintln(report(r))\n")
    axes=s.spec["axes"]; xs=axes[1]["values"]; ys=length(axes)==2 ? axes[2]["values"] : [nothing]
    frozen=PHREEQCConfig(executable=env.executable,database=joinpath(dir,"database.dat"),timeout_seconds=c.timeout_seconds)
    samples=Dict{String,Any}[]
    for (iy,y) in enumerate(ys), (ix,x) in enumerate(xs)
        coords=Dict{String,Any}(axes[1]["parameter"]=>x)
        length(axes)==2 && (coords[axes[2]["parameter"]]=y)
        point=Dict{String,Any}("ix"=>ix,"iy"=>iy,"coordinates"=>coords,"status"=>"failed","si"=>Dict{String,Float64}(),"warnings"=>String[],"archive"=>"","error"=>"")
        input=study_input(s,coords)
        point["database_sha256"]=env.database_sha256
        point["input_sha256"]=bytes2hex(sha256(codeunits(input)))
        try
            res=run_phreeqc(frozen,input;root=dir,
                required=vcat(["si_$m" for m in s.spec["minerals"]],["pct_err"]),
                sources=[s.spec["fluid"]["source"]],metadata=Dict("study"=>"../study.toml","coordinates"=>coords,"classification"=>"Calculation"))
            length(res.rows)==1 || error("expected exactly one initial speciation row")
            point["si"]=Dict(m=>parse(Float64,res.rows[1]["si_$m"]) for m in s.spec["minerals"])
            point["status"]=compatibility(point["si"],s.spec["tolerances"])
            point["warnings"]=res.manifest["warnings"]
            point["archive"]=relpath(res.directory,dir)
            point["selected"]=res.rows[1]
        catch e
            e isa InterruptException && rethrow()
            # Runtime configuration errors/programming bugs are not PHREEQC failed points.
            e isa CalculationError || rethrow()
            point["error"]=sprint(showerror,e)
            point["archive"]=relpath(e.directory,dir)
        end
        phases_available=all(m->occursin(Regex("(?m)^"*m*"\\s*\$"),read(frozen.database,String)),s.spec["minerals"])
        point["evaluation"]=evaluate_constraints(s,point;database_sha256=env.database_sha256,database_phases_available=phases_available)
        if haskey(point,"selected")
            context=get(s.spec["fluid"],"charge_context",s.spec["fluid"]["origin"]=="Observation" ? "partial_analysis" : "hypothetical")
            row=point["selected"]
            point["charge_diagnostic"]=charge_diagnostic(parse(Float64,row["pct_err"]),parse(Float64,row["charge"]),parse(Float64,row["mass_H2O"]);threshold_percent=get(get(s.spec,"evaluation",Dict()),"max_charge_error_percent",0.1),context)
            point["charge_audit"]=species_charge_audit(joinpath(dir,point["archive"],"output.pqo"))
        end
        push!(samples,point)
    end
    provenance=Dict{String,Any}("timestamp_utc"=>string(now(UTC)),"package_version"=>string(pkgversion(@__MODULE__)),"julia_version"=>string(VERSION),"database_name"=>basename(env.database),"database_sha256"=>env.database_sha256,
        "executable"=>env.executable,"executable_sha256"=>bytes2hex(sha256(read(env.executable))),"warnings"=>copy(STUDY_WARNINGS),"indexing"=>"x axis varies fastest; sample[(iy-1)*nx+ix]",
        "source_id"=>s.spec["fluid"]["source"],"input_origin"=>s.spec["fluid"]["origin"],"seed"=>"not applicable","timeout_seconds"=>c.timeout_seconds)
    banners=unique([TOML.parsefile(joinpath(dir,p["archive"],"manifest.toml"))["engine_banner"] for p in samples if isfile(joinpath(dir,p["archive"],"manifest.toml")) && haskey(TOML.parsefile(joinpath(dir,p["archive"],"manifest.toml")),"engine_banner")])
    provenance["engine_banners"]=banners
    provenance["official_engine_source"]="https://www.usgs.gov/software/phreeqc-version-3"
    provenance["validation_status"]="Version-matched official Example 1 and independent published parameter screening available; historical table discrepancy retained; complete aqueous model and natural-deposit validation remain unverified."
    provenance["evaluation_policy"]=get(s.spec,"evaluation",Dict("mode"=>"exploratory","max_charge_error_percent"=>0.1,"origin"=>"explicitly disclosed legacy v0.2 default policy"))
    provenance["study_sha256"]=bytes2hex(sha256(read(joinpath(dir,"study.toml"))))
    source_hashes=Dict{String,String}()
    for (folder,_,files) in walkdir(joinpath(dir,"src")), f in files
        file=joinpath(folder,f); source_hashes[relpath(file,dir)]=bytes2hex(sha256(read(file)))
    end
    provenance["source_sha256"]=source_hashes
    evidence_hashes=Dict{String,String}()
    for (folder,_,files) in walkdir(joinpath(dir,"data")), f in files
        file=joinpath(folder,f);evidence_hashes[relpath(file,dir)]=bytes2hex(sha256(read(file)))
    end
    provenance["evidence_sha256"]=evidence_hashes
    if env.database_sha256 != "59373961d648dfbf68a40744060c1d64f57ecbec98f4f5fb89f3a1b4213ccd10"
        push!(provenance["warnings"],"Database differs from the audited PHREEQC 3.8.6-17100 phreeqc.dat; activity model, species and temperature applicability have not been reviewed.")
    end
    open(io->TOML.print(io,provenance;sorted=true),joinpath(dir,"provenance.toml"),"w")
    result=ScanResult(s,samples,dir,provenance)
    open(io->TOML.print(io,toml_safe(Dict("samples"=>samples));sorted=true),joinpath(dir,"samples.toml"),"w")
    result
end

"""Match forward SI signatures for synthetic recovery, separate from equilibrium masks."""
function signature_matches(r::ScanResult,target::AbstractDict,tolerances::AbstractDict)
    !isempty(target) && all(v->v isa Real && isfinite(v),values(target)) || throw(ArgumentError("finite nonempty target SI required"))
    Set(keys(target)) == Set(keys(tolerances)) || throw(ArgumentError("target/tolerance keys differ"))
    all(v->isfinite(v)&&v>0,values(tolerances)) || throw(ArgumentError("positive tolerances required"))
    [p for p in r.samples if p["status"] != "failed" && all(m->haskey(p["si"],m) && isfinite(target[m]) && abs(p["si"][m]-target[m]) < tolerances[m],keys(target))]
end

toml_safe(x::AbstractDict)=Dict(k=>toml_safe(v) for (k,v) in x if v!==nothing)
toml_safe(x::AbstractVector)=[toml_safe(v) for v in x if v!==nothing]
toml_safe(x)=x
