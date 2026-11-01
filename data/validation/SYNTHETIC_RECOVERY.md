# Off-grid synthetic SI-signature recovery

SYNTHETIC / SIMULATED; no specimen or experimental data. This test matches forward SI signatures, not an equilibrium observation or geological history.

Hidden point: Dict("pH" => 7.35, "temperature" => 42.5). Search coordinates: temperature [40,45] °C and pH [7.3,7.4]; hidden values are off both axes.

PHREEQC-generated target SI: Dict("Fluorite" => -0.07364901089458, "Calcite" => -0.4053521190541). Declared signature tolerance 0.15 SI per mineral. Matched points: Dict{String, Any}[Dict("pH" => 7.3, "temperature" => 40.0), Dict("pH" => 7.3, "temperature" => 45.0), Dict("pH" => 7.4, "temperature" => 40.0), Dict("pH" => 7.4, "temperature" => 45.0)].

The true point is enclosed by matched grid coordinates; it is not recovered exactly, and multiple matches are reported. This checks consistency and bracketing only. Chemical warnings and the fixed assumed fluid remain applicable.

Search archive: /Users/Lithos/Documents/GitHub/PHREEQC-MineralTrace/results/study-TKapL5. Target archive: /Users/Lithos/Documents/GitHub/PHREEQC-MineralTrace/results/run-JnYD2m. Database SHA-256: 59373961d648dfbf68a40744060c1d64f57ecbec98f4f5fb89f3a1b4213ccd10.
