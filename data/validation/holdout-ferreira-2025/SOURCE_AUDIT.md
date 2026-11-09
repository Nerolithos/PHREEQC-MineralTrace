# Independent-source screening and qualification audit

Reviewed 2026-11-09, before predictions. Selected original source: Ferreira et al. (2025), *J. Chem. Eng. Data* 70,1498–1507, DOI [10.1021/acs.jced.4c00670](https://doi.org/10.1021/acs.jced.4c00670). All five pure-water 298.15 K points from Table 3 are selected because they fall inside the existing 23–80 C endpoint API. No added process, new temperature range or parameter fit is needed.

## Source and measurement contract

| Field | Primary source location | Finding / interpretation |
| --- | --- | --- |
| Initial composition | §2.1, Table 2 | Type-1 distilled/deionized water, conductivity monitored <1.5 µS/cm; CaCO3 Sigma-Aldrich ≥99.5%, CO2 Linde ≥99.9%; no MEG in selected Table 3 subset. Trace composition is not an ion analysis. |
| Apparatus/boundary | §2.2, Fig.1 | Paired jacketed glass cells, CO2 cylinder/buffer/manifold and pressure control. Supports a regulated CO2 partial-pressure approximation, not a specified finite headspace. |
| Temperature and pressure | §4.1, Table 3 | 298.15 K; pCO2=101.3,134.6,161.3,188.0,214.6 kPa. Values are used as labeled partial pressures, not total pressure or gauge readings. |
| Solid | §2.2 | Excess calcium carbonate present to saturate liquid; no exact per-run solid/water masses recovered. Calcite is the phase identified by authors in §3.1; this is not an independent mineralogical assay. |
| Equilibration | §2.2 | Initial lower-temperature dissolution for 30 min, 2 h agitation +2 h sedimentation, some runs extended 24 h until successive samples reproducible. Do not assign a single time to each point or claim rates validated. |
| Analysis | §2.2 | Samples acidified/diluted with HNO3 to avoid precipitation and analyzed by VARIAN atomic absorption. Compare the reported solubility inferred from analyzed supernatant Ca, not free Ca2+ activity. Filtration is not explicitly specified for these glass-cell samples; acidification may not discriminate residual fine particles. Do not assert particle contamination occurred or that a strict dissolved-size cutoff was established. |
| Observable/unit | Table 3, §3.1, conclusion | CaCO3-equivalent molality, displayed mmol/kg; ion molality is mol/kg water. 1 mmol Ca corresponds to 1 mmol CaCO3 equivalent. Prediction uses database GFW only for optional g/kg conversion, not for molal comparison. |
| Pointwise repeatability | Table 3 sigma, footnote b | SD of duplicate experimental data: retained as SD, not assumed full uncertainty or standard error of mean. |
| Standard uncertainty | Table 3 footnote a | u(T)=0.05 K, u(P)=2.7 kPa, u(mCaCO3)=0.15 mmol/kg. Distinct from duplicate SD and numerical closure tolerance. No invented covariance or statistical pass criterion. |
| pH | §4.1 and Eq.21 | Missing pH filled by literature-derived pressure correlation for authors' model; these are not independent pH measurements. Do not validate predicted pH against them. |
| DIC/CO2 | Selected data subset | No independently measured DIC or dissolved CO2 recovered. Remain UNKNOWN. |

The preserved publisher text snapshot is a **web-search retrieval transcript**, with DOI and retrieval date, not an original PDF/HTML byte download. Direct publisher PDF/HTML requests returned HTTP 403. Table 3 and both footnotes were explicitly recovered from the primary publisher text. Publisher states CC BY 4.0; attribution retained. Do not mistake this snapshot's SHA-256 for an original publisher PDF fingerprint.

## Related 2022 thesis: not an independent second dataset

Penha (2022), [UFRN handle 123456789/49714](https://repositorio.ufrn.br/handle/123456789/49714), publicly deposited 2022-11-09; defense 2022-03-31. Original PDF verified against repository MD5 `656a40a832b57dd686c39aad83ef4512`; public metadata and download identifier archived in lineage-v081. Methods printed pp.41–42/PDF42–43; original pure-water Table AI printed p.94/PDF95, 298.15 K comparison Table 4.6 printed p.63/PDF64. These show related measurements, not necessarily an identical table/version. Some solubilities round to the 2025 values, others and the pressure coordinates differ. No conversion/correction is silently applied to make the two versions match; the 2025 table alone is the frozen prediction target.

The thesis pH values are also calculated from a literature pressure correlation (printed p.43/PDF44), not measured in those glass-cell experiments. Separate high-temperature Othmer experiments in later chapters have different boundaries and are not included. The 2022 thesis and 2025 paper are treated as one related data family, not two independent validation replications. The thesis license metadata says open access, not a verified redistribution license; its original PDF is retained locally in ignored results/source review, with public download and hash metadata tracked.

## Database calibration lineage

The official 2021-07-07 snapshot predates this thesis: commit `ea7ada6f0967b50ab341956c4b063805a3ddb986`. Comparing it with locked May-2024 production data shows the Calcite/CO2 gas phase coefficients are unchanged, but CaHCO3 association/temperature coefficients, some aqueous volumes and the CO2 gamma block changed. Some other text differences are merely numeric formatting. The official 2021–2024 change history is archived. **A 2021 phase-log-K match is insufficient to establish independence of the complete 2024 aqueous model.** No explicit citation of Penha/Ferreira was found in the selected production blocks, but absence of a citation is not proof of nonuse.

Therefore: independent source versus REFLECT = YES; no parameter fitting by MineralTrace = YES; complete independence from all database parameter calibration = UNKNOWN. A strictly qualified experimental holdout is NOT certified. The external prediction comparison is still informative and must preserve this distinction in registry/report/README. The author's fitted Pitzer parameters and OLI curves are not imported.

## Other original-source candidates screened

- Bo et al. (2018), DOI [10.1021/acs.jced.8b00185](https://doi.org/10.1021/acs.jced.8b00185): pure calcite/carbonated-water branch potentially overlaps REFLECT at 1–5 MPa,293.15–343.15 K; ICP-OES. Original publisher abstract accessible, full measurement tables/uncertainties and detailed boundary recipe not recovered. Supporting information describes XRD, not a substitute for endpoint data. Not calculated or guessed.
- Bychkov et al. (2020), GCA original article PII S001670372030555X: 100–160 C and NaCl, outside current pure-water endpoint contract and relevant parameter lineage; not a new independent holdout in this patch.
- Plummer & Busenberg (1982): foundational carbonate calibration source. Do not relabel fitted source data as a held-out independent prediction.
- Espinoza & Santamarina (2010), DOI 10.1029/2009WR008634: target is interfacial tension/contact angle; its speciation table is not established here as independent Ca/DIC analysis, and equilibrium not guaranteed for droplet tests. Not used as equilibrium-Ca observations.
