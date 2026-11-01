# Includes known failing historical Example 1 comparison; does not suppress failure.
ENV["MINERALTRACE_INTEGRATION"] = "1"
ENV["MINERALTRACE_LEGACY_BENCHMARK"] = "1"
include(joinpath(@__DIR__,"../test/runtests.jl"))
