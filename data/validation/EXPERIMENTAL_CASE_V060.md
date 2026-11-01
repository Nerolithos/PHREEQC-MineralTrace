# Independent calcite experiment screening — v0.6.0

Reviewed 2026-11-01. **No complete independent reaction-path experimental validation has been completed.** This record distinguishes available measurements from a reproducible, supported model benchmark. It is not a declaration that adequate public data do not exist.

## Promising closed-system titration dataset

Original publisher supplementary information for *Proton/calcium ion exchange behavior of calcite*, DOI [10.1039/B815198A](https://doi.org/10.1039/B815198A): [methods and raw data](https://www.rsc.org/suppdata/cp/b8/b815198a/b815198a.pdf).

The publisher-indexed supplement describes equilibrated calcite, HCl titrations in KCl electrolyte, measured pH and calcium activity, and uncertainty information. It also treats surface proton/calcium exchange and finite titrant volumes. These are relevant equilibrium-step data, rather than a rate prediction target.

**Status: promising, not yet an executable benchmark.** The indexed PDF text was accessible, but direct download returned HTTP 404 and the PDF screenshot service returned a cache miss. The raw numerical tables were therefore not independently visually transcribed in this sprint. Do not use an unverified table extraction as a passing experimental result. The main-paper initial-condition table was not fully verified.

The current discovery profile excludes K, surface exchange, and carrier-water dilution. Discarding those contributions, replacing KCl with NaCl, or assuming missing starting amounts would change the experiment. No such substitutions or fitted initial values were made. Next work is to retrieve the original main paper and supplement, visually verify the entire selected experiment, establish full initial inventory/mineral mass/gas/volume boundaries, and decide whether a bulk endpoint is supportable without a surface model. Otherwise explicitly extend and independently audit the required model before comparing measured pH or calcium activity.

## Independent finite-headspace dissolution dataset

Zhang et al. (2020), *Divalent heavy metals and uranyl cations incorporated in calcite change its dissolution process*, DOI [10.1038/s41598-020-73555-6](https://doi.org/10.1038/s41598-020-73555-6), [original article](https://www.nature.com/articles/s41598-020-73555-6).

For the pure-calcite control the article reports equilibrium dissolved Ca 0.52 mM and pH 8.19, with a finite air headspace and long dissolution observations. Endpoint uncertainties and the full verified starting ionic/carbon inventory were not established in this review and remain null in the source record. The finite gas reservoir cannot be replaced by an infinite atmospheric reservoir or omitted from a supposedly aqueous-only closed calculation.

**Status: unsuitable for the present no-gas discovery boundary.** A finite-headspace model and fully checked methods/supplement are needed before an endpoint comparison. The time series additionally requires an independently parameterized kinetic model; present equilibrium calculations cannot validate dissolution rates.

## What is and is not validated

- Direct CLI replay checks engine/adapter agreement and state handoff.
- Element/charge/phase-permission checks establish numerical chemical accounting.
- Neither establishes experimental accuracy. The previous Brown–Roberson limited log K comparison remains a parameter comparison only.
- Neither newly screened source has been used to populate guessed initial fluids, fit a pH, or generate invented measurement-versus-model figures.

A supported experimental benchmark remains an outstanding scientific requirement, not a completed acceptance item. Specimen formats, gas exchange, mixing and kinetics are deferred to keep v0.6.0 focused on bounded mechanism screening.
