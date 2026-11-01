"""A formation event, not a mineral species. Repeated minerals need distinct IDs."""
struct FormationEvent
    id::String
    mineral::String
    description::String
    function FormationEvent(id, mineral; description="")
        isempty(strip(id)) && throw(ArgumentError("event ID is required"))
        isempty(strip(mineral)) && throw(ArgumentError("mineral is required"))
        new(id, mineral, description)
    end
end

"""An explicitly interpreted temporal constraint. Spatial contact alone is insufficient."""
struct Evidence
    earlier::String
    later::String
    kind::Symbol
    source::String
    reliability::String
    interpretation::String
    function Evidence(earlier, later, kind; source, reliability, interpretation)
        kind in (:overgrowth, :inclusion, :crosscutting, :replacement, :zoning, :literature) ||
            throw(ArgumentError("unsupported evidence type: $kind"))
        any(isempty ∘ strip, (source, reliability, interpretation)) &&
            throw(ArgumentError("source, reliability and interpretation are required"))
        new(earlier, later, kind, source, reliability, interpretation)
    end
end
