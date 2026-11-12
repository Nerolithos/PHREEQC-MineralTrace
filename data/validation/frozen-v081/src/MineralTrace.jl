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
include("pathways/PathStudy.jl")
include("pathways/PathSimulation.jl")
include("pathways/PathReport.jl")
include("discovery/DiscoveryStudy.jl")
include("discovery/DiscoverySimulation.jl")
include("discovery/DiscoveryReport.jl")
include("validation/CalciteEndpoint.jl")
include("validation/ModelProfiles.jl")
include("robustness/Robustness.jl")
include("robustness/RobustnessReport.jl")
export comparison_statistics
export ModelProfile, EvidenceRegistry, load_model_profiles, load_evidence_registry, evaluate_applicability, audit_database, bar_to_atm, atm_to_bar
export RobustnessPlan, load_robustness, analyze_robustness, report_robustness
export CalciteCO2Endpoint, calcite_endpoint
export DiscoveryStudy, DiscoveryResult, load_discovery, generate_candidates, discover_paths
export PathStudy, PathComparison, load_paths, compare_paths
export charge_diagnostic, AcidBaseTitration, ProcessResult, load_process, process_input, simulate
export EvidenceConstraint, evaluate_constraints, constraint_contribution, charge_equivalents
export MineralStudy, ScanResult, load_study, scan, report, signature_matches, compatibility
export FormationEvent, Evidence, EvidenceGraph, CycleConflict, analyze, topological_order
export FluidState, PHREEQCConfig, DependencyError, CalculationError, environment_check
export solution_input, run_phreeqc, forward, read_selected
end
