# Database snapshots and diagnostic derivatives

The two original files are byte-preserved from the official [PHREEQC 3.8.6-17100 source distribution](https://water.usgs.gov/water-resources/software/PHREEQC/phreeqc-3.8.6-17100.tar.gz), directory `database/`. They retain their own scientific references and source terms; the project's MIT code license does not relicense them. The [build instructions](../../../../docs/REFERENCE.md#安装依赖) identify the tested engine.

| File | Role | SHA-256 |
| --- | --- | --- |
| phreeqc.dat | Unmodified historical v0.7.0 baseline | `59373961d648dfbf68a40744060c1d64f57ecbec98f4f5fb89f3a1b4213ccd10` |
| pitzer.dat | Unmodified whole-profile sensitivity control | `06ab2debc0cdb333598118df953165499c2f762a79de5f2df55dec6b78b02589` |
| ideal-co2.dat | Diagnostic derivative: remove CO2 critical/EOS properties only | `7e16cbf61c671d382459dbebed8c94694d1f489d233ef63ff77cb348b2ae85f9` |
| davies-ions.dat | Diagnostic derivative: omit explicit gamma for the five listed charged ions | `a97b6455135727aa1e5c3549728076e5a9f19d12a8e2fe63b8be182eb7831bf6` |

Derivatives are generated and audited by [attribute_calcite_bias.jl](../../../../scripts/attribute_calcite_bias.jl), not proposed as tuned production databases. No log K or analytic temperature coefficient is changed. See the [protocol](../PROTOCOL.md); do not silently substitute these files in a discovery study. Pitzer changes a whole profile, not only the activity equation, and is not independently certified here.
