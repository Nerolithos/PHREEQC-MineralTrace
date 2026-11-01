using MineralTrace
# SYNTHETIC / SIMULATED: demonstrates an interpreted evidence graph, not a specimen history.
events = [FormationEvent("Fluorite-I","Fluorite"), FormationEvent("Calcite-I","Calcite"),
          FormationEvent("Fluorite-II","Fluorite")]
evidence = [Evidence("Fluorite-I","Calcite-I",:overgrowth;
    source="SYNTHETIC / SIMULATED example", reliability="illustration only",
    interpretation="Assume calcite overgrowth formed after Fluorite-I; no actual texture supplied.")]
println(analyze(EvidenceGraph(events,evidence)))
