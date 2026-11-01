using MineralTrace, TOML
# Primary data are independently registered in fluorite-experimental-case-v050.json.
input="""
SOLUTION 1 Phase-parameter reference query, not a reconstructed experimental fluid
    temp 25
    pressure 1
    pH 7
SELECTED_OUTPUT
    -file selected.tsv
    -reset false
    -high_precision true
USER_PUNCH
    -headings fluorite_logK
    -start
    10 PUNCH LK_PHASE("Fluorite")
    -end
END
"""
r=run_phreeqc(PHREEQCConfig(),input;root=joinpath(@__DIR__,"../results"),required=["fluorite_logK"],sources=["BROWN-ROBERSON-1977"])
actual=parse(Float64,r.rows[1]["fluorite_logK"]);reference=-10.58;uncertainty=0.17
record=Dict("source_id"=>"BROWN-ROBERSON-1977","observable"=>"zero-ionic-strength phase log10 K at 25 C","reference"=>reference,"reported_analytical_uncertainty"=>uncertainty,"calculation"=>actual,"signed_delta"=>actual-reference,"within_reported_uncertainty"=>abs(actual-reference)<=uncertainty,"database_sha256"=>r.manifest["database_sha256"],"raw_archive"=>r.directory,"scope"=>"Derived equilibrium parameter comparison only; full experimental reaction path rejected because initial carbon and gas boundary cannot be reproduced without assumptions. No fluid measurements were filled in.")
open(io->TOML.print(io,record;sorted=true),joinpath(@__DIR__,"../data/validation/fluorite-experimental-comparison-v050.toml"),"w")
println(record)
