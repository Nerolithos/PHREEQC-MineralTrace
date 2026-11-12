# Launch the exact v0.8.1 package and prediction protocol; never rebaseline its freeze.
project=normpath(joinpath(@__DIR__,"../data/validation/frozen-v081"))
output=isempty(ARGS) ? abspath("results") : abspath(ARGS[1])
run(`$(Base.julia_cmd()) --startup-file=no --project=$project $(joinpath(project,"scripts/validate_holdout.jl")) $output`)
