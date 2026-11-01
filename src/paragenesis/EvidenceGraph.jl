struct EvidenceGraph
    events::Vector{FormationEvent}
    evidence::Vector{Evidence}
    function EvidenceGraph(events, evidence)
        ids = [e.id for e in events]
        length(unique(ids)) == length(ids) || throw(ArgumentError("duplicate event IDs"))
        for e in evidence
            e.earlier in ids && e.later in ids || throw(ArgumentError("unknown event in evidence"))
        end
        new(collect(events), collect(evidence))
    end
end
struct CycleConflict <: Exception
    evidence::Vector{Evidence}
end
Base.showerror(io::IO, e::CycleConflict) = print(io, "Conflicting temporal evidence: ",
    join(["$(x.earlier) → $(x.later) [$(x.source)]" for x in e.evidence], "; "))

function reachability(g::EvidenceGraph)
    n = length(g.events)
    ids = Dict(e.id => i for (i,e) in enumerate(g.events))
    r = falses(n,n)
    for e in g.evidence
        r[ids[e.earlier],ids[e.later]] = true
    end
    for k in 1:n, i in 1:n, j in 1:n
        r[i,j] |= r[i,k] && r[k,j]
    end
    r, ids
end

"""Return all evidence participating in cycles; never remove conflicting edges."""
function cycle_evidence(g::EvidenceGraph)
    r, ids = reachability(g)
    [e for e in g.evidence if r[ids[e.later],ids[e.earlier]]]
end

function topological_order(g::EvidenceGraph)
    conflicts = cycle_evidence(g)
    isempty(conflicts) || throw(CycleConflict(conflicts))
    remaining = [e.id for e in g.events]
    order = String[]
    while !isempty(remaining)
        ready = findfirst(id -> !any(e -> e.later == id && e.earlier in remaining, g.evidence), remaining)
        push!(order, popat!(remaining, ready))
    end
    order
end

"""A topological order is one legal ordering, not a uniquely established history."""
function analyze(g::EvidenceGraph)
    conflicts = cycle_evidence(g)
    isempty(conflicts) || throw(CycleConflict(conflicts))
    r, _ = reachability(g)
    ids = [e.id for e in g.events]
    determined = [(ids[i],ids[j]) for i in eachindex(ids) for j in eachindex(ids) if r[i,j]]
    undetermined = [(ids[i],ids[j]) for i in eachindex(ids) for j in i+1:length(ids) if !r[i,j] && !r[j,i]]
    (; order=topological_order(g), determined, undetermined)
end
