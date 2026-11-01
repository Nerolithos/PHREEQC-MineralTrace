module MineralTrace
using Dates, SHA, TOML
include("models/FormationEvent.jl")
include("paragenesis/EvidenceGraph.jl")
include("thermodynamics/PHREEQCAdapter.jl")
include("exploration/Study.jl")
include("constraints/Constraints.jl")
include("thermodynamics/ChargeDiagnostics.jl")
include("exploration/Scan.jl")
include("reporting/Report.jl")
include("processes/Titration.jl")
include("processes/ProcessReport.jl")
export charge_diagnostic, AcidBaseTitration, ProcessResult, load_process, process_input, simulate
export EvidenceConstraint, evaluate_constraints, constraint_contribution, charge_equivalents
export MineralStudy, ScanResult, load_study, scan, report, signature_matches, compatibility
export FormationEvent, Evidence, EvidenceGraph, CycleConflict, analyze, topological_order
export FluidState, PHREEQCConfig, DependencyError, CalculationError, environment_check
export solution_input, run_phreeqc, forward, read_selected
end
