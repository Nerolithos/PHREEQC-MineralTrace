struct DependencyError <: Exception
    message::String
end
struct CalculationError <: Exception
    message::String
    directory::String
end
Base.showerror(io::IO, e::DependencyError) = print(io, e.message)
Base.showerror(io::IO, e::CalculationError) = print(io, e.message, "; archived at ", e.directory)

Base.@kwdef struct PHREEQCConfig
    executable::String = get(ENV, "PHREEQC_EXECUTABLE", "phreeqc")
    database::String = get(ENV, "PHREEQC_DATABASE", "")
    timeout_seconds::Float64 = 60.0
end

function environment_check(c::PHREEQCConfig)
    exe = Sys.which(c.executable)
    isnothing(exe) && throw(DependencyError("PHREEQC CLI missing: $(c.executable). See README installation instructions; no fallback engine is used."))
    isfile(c.database) || throw(DependencyError("PHREEQC database missing: set PHREEQC_DATABASE to an official phreeqc.dat file."))
    isfinite(c.timeout_seconds) && c.timeout_seconds > 0 || throw(ArgumentError("timeout must be positive and finite"))
    (; executable=abspath(exe), database=abspath(c.database), database_sha256=bytes2hex(sha256(read(c.database))))
end

"""Explicit totals in mol/kgw at 1 atm; temperatures above 25 °C require explicit exploratory opt-in.
Totals are user-supplied assumptions, never measurements by default. No charge adjustment.
"""
struct FluidState
    temperature_c::Float64
    pH::Float64
    totals::Dict{String,Float64}
    label::String
    function FluidState(; temperature_c, pH, totals, label, allow_unvalidated_temperature=false)
        isfinite(temperature_c) && 25 <= temperature_c <= 80 || throw(ArgumentError("exploratory temperature bounds are 25–80 °C"))
        (temperature_c == 25 || allow_unvalidated_temperature) || throw(ArgumentError("non-reference temperatures require explicit allow_unvalidated_temperature=true; applicability remains unvalidated"))
        isfinite(pH) && 0 <= pH <= 14 || throw(ArgumentError("invalid pH"))
        isempty(strip(label)) && throw(ArgumentError("label must identify the input origin"))
        isempty(totals) && throw(ArgumentError("explicit fluid composition required"))
        allowed = ("Ca", "F", "C(4)", "Na", "Cl")
        for (k,v) in totals
            k in allowed || throw(ArgumentError("unsupported total: $k"))
            isfinite(v) && v >= 0 || throw(ArgumentError("totals must be finite nonnegative mol/kgw"))
        end
        new(temperature_c, pH, Dict{String,Float64}(totals), label)
    end
end

function solution_input(f::FluidState)
    lines = ["TITLE MineralTrace forward calculation", "SOLUTION 1", "    temp $(f.temperature_c)",
             "    pressure 1", "    pH $(f.pH)", "    units mol/kgw", "    water 1"]
    append!(lines, ["    $k $(f.totals[k])" for k in sort(collect(keys(f.totals)))])
    append!(lines, ["SELECTED_OUTPUT 1", "    -file selected.tsv", "    -reset false",
        "    -high_precision true", "    -pH true", "    -temperature true",
        "    -charge_balance true", "    -percent_error true", "    -totals Ca F C(4)",
        "    -activities H+ Ca+2 F- CO3-2", "    -saturation_indices Fluorite Calcite", "END"])
    join(lines, "\n") * "\n"
end

"""Parse whitespace-delimited SELECTED_OUTPUT. Preserve labels and reject incomplete rows."""
function read_selected(path; required=String[])
    isfile(path) || throw(ArgumentError("SELECTED_OUTPUT file missing"))
    lines = filter(x -> !isempty(strip(x)), readlines(path))
    length(lines) >= 2 || throw(ArgumentError("SELECTED_OUTPUT has no calculation rows"))
    headers = String.(split(lines[1]))
    length(unique(headers)) == length(headers) || throw(ArgumentError("duplicate selected-output headers"))
    all(x -> x in headers, required) || throw(ArgumentError("required columns missing: $required"))
    rows = Dict{String,String}[]
    for line in lines[2:end]
        fields = String.(split(line))
        length(fields) == length(headers) || throw(ArgumentError("incomplete selected-output row"))
        row = Dict(zip(headers,fields))
        for k in required
            v = tryparse(Float64, row[k])
            (!isnothing(v) && isfinite(v) && v > -999) || throw(ArgumentError("undefined or nonfinite result for $k"))
        end
        push!(rows,row)
    end
    rows
end

"""Run trusted PHREEQC input in a new directory, preserving input, database, logs and manifest.
Raw input is an expert API and can use PHREEQC file-writing directives. Do not pass untrusted decks.
Warnings are retained and result in a distinct status; all execution failures throw with an archive path.
"""
function run_phreeqc(c::PHREEQCConfig, input::AbstractString; root="results", required=String[], sources=String[], metadata=Dict{String,Any}(), auxiliary_files=Dict{String,String}())
    env = environment_check(c)
    reserved=("input.pqi","output.pqo","database.dat","selected.tsv","manifest.toml","stdout.log","stderr.log")
    for (name,path) in auxiliary_files
        basename(name)==name && !(name in ("",".","..")) && !(name in reserved) && isfile(path) || throw(ArgumentError("invalid auxiliary input $name"))
    end
    mkpath(root)
    dir = abspath(mktempdir(root; prefix="run-", cleanup=false))
    write(joinpath(dir,"input.pqi"), input)
    cp(env.database, joinpath(dir,"database.dat"))
    for (name,path) in auxiliary_files
        cp(path,joinpath(dir,name))
    end
    manifest = Dict{String,Any}("status"=>"started", "timestamp_utc"=>string(now(UTC)),
        "package_version"=>string(pkgversion(@__MODULE__)), "julia_version"=>string(VERSION),
        "executable"=>env.executable, "executable_sha256"=>bytes2hex(sha256(read(env.executable))),
        "database_name"=>basename(env.database), "database_sha256"=>env.database_sha256,
        "input_sha256"=>bytes2hex(sha256(codeunits(input))), "sources"=>sources,
        "metadata"=>metadata, "random_seed"=>"not applicable", "warnings"=>String[])
    manifest["auxiliary_sha256"]=Dict(name=>bytes2hex(sha256(read(joinpath(dir,name)))) for name in keys(auxiliary_files))
    save() = open(io -> TOML.print(io, manifest), joinpath(dir,"manifest.toml"), "w")
    save()
    try
        cmd = Cmd(Cmd([env.executable, "input.pqi", "output.pqo", "database.dat"]); dir=dir)
        manifest["command"] = collect(cmd)
        process = open(joinpath(dir,"stdout.log"),"w") do out
            open(joinpath(dir,"stderr.log"),"w") do err
                p = run(pipeline(cmd; stdin=devnull, stdout=out, stderr=err); wait=false)
                deadline = time() + c.timeout_seconds
                while process_running(p) && time() < deadline
                    sleep(0.05)
                end
                if process_running(p)
                    kill(p, Base.SIGKILL)
                    wait(p)
                    error("PHREEQC timeout after $(c.timeout_seconds) seconds")
                end
                wait(p)
                p
            end
        end
        manifest["exit_code"] = process.exitcode
        logs = join([isfile(joinpath(dir,f)) ? read(joinpath(dir,f),String) : "" for f in ("output.pqo","stdout.log","stderr.log")], "\n")
        banner = match(r"(?im)^.*PHREEQC[^\n]*", logs)
        manifest["engine_banner"] = isnothing(banner) ? "not detected" : String(banner.match)
        manifest["warnings"] = unique(filter(l -> occursin(r"(?i)warning|converg",l), split(logs,'\n')))
        success(process) || error("PHREEQC exited with code $(process.exitcode)")
        occursin(r"(?im)^\s*ERROR", logs) && error("PHREEQC reported an error")
        isfile(joinpath(dir,"output.pqo")) && filesize(joinpath(dir,"output.pqo")) > 0 || error("raw output missing")
        rows = read_selected(joinpath(dir,"selected.tsv"); required)
        for row in rows
            if haskey(row,"pct_err")
                imbalance = tryparse(Float64,row["pct_err"])
                if !isnothing(imbalance) && abs(imbalance) > 0.1
                    push!(manifest["warnings"], "Charge imbalance $(imbalance)% exceeds diagnostic threshold 0.1%; composition was not adjusted.")
                end
            end
        end
        manifest["status"] = isempty(manifest["warnings"]) ? "completed" : "completed_with_warnings"
        save()
        (; directory=dir, rows, manifest)
    catch e
        manifest["status"] = "failed"
        manifest["error"] = sprint(showerror,e)
        save()
        throw(CalculationError(manifest["error"],dir))
    end
end

function forward(c::PHREEQCConfig, f::FluidState; root="results")
    run_phreeqc(c, solution_input(f); root,
        required=["si_Fluorite","si_Calcite","la_Ca+2","la_F-","la_CO3-2","pct_err"],
        metadata=Dict("classification"=>"Calculation", "input_origin"=>f.label,
            "units"=>"mol/kgw", "temperature_c"=>f.temperature_c, "pH"=>f.pH,
            "pressure_atm"=>1, "totals"=>f.totals,
            "limitations"=>"Database applicability not fully reviewed; SI > 0 does not imply precipitation; no geological history inferred."))
end
