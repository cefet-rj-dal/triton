# Triton

Triton is the simulation code used to evaluate the economic and environmental viability of biodiesel blends with bunker fuel in a representative Santos-Rotterdam voyage.

The model compares a conventional bunker-fuel voyage with biobunker scenarios under different blend fractions, biodiesel production pathways, fuel prices, emission factors, operational assumptions, and regulatory carbon-cost signals. Its role in the article is to make the viability frontier explicit: a scenario is considered viable only when it reaches the adopted emission-reduction threshold and remains compatible with the reference cost of carbon.

## Repository Structure

- `simulacao.R`: main script with the model, experimental grids, tables, and figures.
- `generate_figures.R`: figure-only script that regenerates the plots from existing CSV outputs.
- `generate_figures_br.R`: figure-only script that regenerates Portuguese versions of the same current figures.
- `dados/anp/`: official Brazilian biodiesel data used to build the state-level blend experiment.
- `resultados/tabelas/`: CSV outputs used to summarize the experiments.
- `resultados/graficos/`: figures generated for the current article narrative.
- `br/`: Portuguese versions of the current figures, saved with the same file names used in `resultados/graficos/`.
- `legado/`: legacy outputs and supporting material retained for traceability.

## Reproducing the Results

Run the full simulation from the repository root:

```bash
Rscript simulacao.R
```

The script writes current article outputs to `resultados/` and supporting legacy outputs to `legado/resultados/`.

To regenerate only the figures from existing CSV outputs, run:

```bash
Rscript generate_figures.R
```

To regenerate the Portuguese versions in `br/`, run:

```bash
Rscript generate_figures_br.R
```

## Experimental Narrative

The article uses the experiments as a progressive argument.

E1 establishes the baseline comparison between bunker fuel and representative biodiesel pathways. It shows that emissions decrease as the renewable fraction increases, but that the marginal abatement cost remains above the adopted reference carbon cost when explicit compliance cost is not internalized.

E2-E5 test whether this conclusion changes under economic, environmental, regulatory-reference, and operational perturbations. These experiments show that the viability reading is most sensitive to the price relationship between fossil and renewable fuel, while the pathway hierarchy remains stable under moderate perturbations.

E6 introduces an explicit compliance cost while keeping the reference carbon cost fixed. This experiment shows the regulatory level at which the first viable combinations emerge and explains why the cost of covered fossil emissions can change the relative position of biobunker.

E7 varies the explicit compliance cost and the reference cost jointly. This separates two mechanisms that are often conflated: the compliance cost changes total scenario cost, whereas the reference cost defines the threshold used to classify the remaining abatement cost.

E8 replaces isolated biodiesel pathways with aggregate state-level supply compositions. This tests whether the central interpretation persists when biodiesel is represented by compositions approximated from observed feedstock shares and regional B100 prices.

The simulator output file names follow an earlier numbering, created before the article narrative was expanded. The mapping between the manuscript labels and the file names is given below, under Experiment Labels and File Names.

## Figures

### Current Figures

- `grafico_01_emissoes_vs_alpha.png`
  Shows total voyage emissions by blend fraction and representative biodiesel pathway in the baseline configuration. It supports the first empirical claim of the article: higher blend fractions reduce emissions, and residue or by-product pathways remain below soybean across the tested range.

- `grafico_03b_break_even_vs_alpha.png`
  Summarizes the break-even carbon price for each representative pathway. Since the value is stable across blend fractions in the baseline formulation, the figure is presented as a pathway-level comparison. It helps show the economic gap before explicit compliance cost is introduced.

- `grafico_04_tradeoff_deltaG_deltaC.png`
  Relates emission reduction to incremental voyage cost in the baseline scenario. The figure is useful as supporting material because it shows the trade-off behind the marginal abatement cost: larger emission reductions require larger incremental costs, with soybean separated from the residue and by-product pathways.

- `grafico_06_decomposicao_custo.png`
  Decomposes total voyage cost into fuel cost and compliance cost for bunker fuel and B24 biobunker alternatives at an illustrative explicit compliance cost. This figure explains the mechanism behind E6: biobunker remains more expensive in fuel terms, but lower covered emissions reduce its compliance-cost disadvantage.

- `grafico_07_fronteira_viabilidade.png`
  Shows the economic and environmental classification over the grid formed by blend fraction and explicit compliance cost for representative pathways. It is the main visual result for E6 and shows that viability appears only in a localized region of the regulatory grid.

- `grafico_09_break_even_estados.png`
  Shows break-even carbon prices for observed state-level biodiesel blends. It supports the state-level extension by showing that aggregate blends are more compressed than isolated production pathways.

- `grafico_10_fronteira_viabilidade_estados.png`
  Shows the viability frontier for observed state-level blends. It is the main visual result for the state-level experiment and shows that empirical blends enter the viable region at high blend fractions and different compliance-cost levels.

### Supporting Legacy Figures

- `grafico_02_custo_vs_alpha.png`
  Stored under `legado/resultados/graficos/`. It shows total voyage cost by blend fraction and pathway in the baseline configuration. It is useful for checking the cost side of E1 but is not part of the current article narrative.

- `grafico_03_mac_vs_alpha.png`
  Stored under `legado/resultados/graficos/`. It shows marginal abatement cost by blend fraction and pathway. It is redundant with the current break-even summary but remains useful for traceability.

- `grafico_05_heatmap_viabilidade.png`
  Stored under `legado/resultados/graficos/`. It shows the baseline viability classification for the regulatory sensitivity grid without explicit compliance cost. It is retained as supporting material because the current article presents this result in tabular and textual form.

- `grafico_06_comparacao_custo_total_legacy.png`
  Stored under `legado/resultados/graficos/`. It preserves the earlier cost-comparison view for traceability. The current article narrative uses the redesigned cost-decomposition figure instead.

- `grafico_08_heatmap_break_even.png`
  Stored under `legado/resultados/graficos/`. It gives a heatmap view of break-even values by blend fraction and pathway. The current article uses the more compact pathway-level break-even figure.

## Experiment Labels and File Names

The file name prefixes follow an earlier numbering and are shifted by one for the last two
experiments. The code does not use the label `E8`. Use this mapping to match the manuscript to the
output files:

| Manuscript | What it does | Files |
| --- | --- | --- |
| E1 | Baseline configuration | `E1_cenario_base.csv`, `resumo_E1.csv` |
| E2 | Price sensitivity | `E2_sensibilidade_economica.csv` |
| E3 | Emission-factor sensitivity | `E3_sensibilidade_ambiental.csv` |
| E4 | Regulatory sensitivity (`delta`, `gamma_ref`) | `E4_sensibilidade_regulatoria.csv` |
| E5 | Operational sensitivity | `E5_sensibilidade_operacional.csv` |
| E2-E5 | Combined summary | `resumo_sensibilidade_E2_E5.csv` |
| E6 | Compliance-cost grid | `E6_caminhos_viabilidade.csv` |
| **E7** | Interaction `gamma_comp` x `gamma_ref` | `E6_interacao_gamma_ref_gamma_comp.csv`, `resumo_E6_interacao_gamma_ref_gamma_comp.csv` |
| **E8** | State-level supply compositions | `E7_blends_estaduais_base.csv`, `E7_blends_estaduais_regulatorio.csv`, `E7_primeiros_viaveis.csv`, `resumo_E7_estados.csv` |
| E8 inputs | Feedstock shares, prices, and parameters derived from ANP data | `E7_materias_primas_estaduais_anp_mar2026.csv`, `E7_precos_regionais_b100_anp_mar2026.csv`, `E7_parametros_estaduais.csv`, `E7_top_estados_anp_mar2026.csv` |

The break-even carbon price of each scenario is the marginal abatement cost expressed in the
comparison currency, not a separate metric. It is reported in `resumo_break_even.csv`.

## Main Outputs

The most relevant tables in `resultados/tabelas/` are:

- `E1_cenario_base.csv`: baseline scenario grid.
- `resumo_E1.csv`: summarized baseline results by pathway.
- `resumo_sensibilidade_E2_E5.csv`: sensitivity summary for E2-E5.
- `E6_caminhos_viabilidade.csv`: viability paths after introducing explicit compliance cost.
- `E6_interacao_gamma_ref_gamma_comp.csv`: interaction between reference cost and explicit compliance cost.
- `resumo_E6_interacao_gamma_ref_gamma_comp.csv`: compact summary of that interaction.
- `E7_blends_estaduais_base.csv`: baseline state-level blend results.
- `E7_blends_estaduais_regulatorio.csv`: state-level regulatory grid.
- `E7_primeiros_viaveis.csv`: first viable state-level combinations.
- `resumo_E7_estados.csv`: summarized state-level results.

## Parameter Elicitation

All parameters are declared at the top of `simulacao.R`. The manuscript reports the energy,
environmental, and economic parameters of the fuels in a dedicated table; this section records the
full set, including the values that the manuscript states in prose or varies through grids.

### Operational conditions

| Parameter | Value | Source |
| --- | --- | --- |
| Route distance `D` | 10,120 km (Santos-Rotterdam) | SeaRoutes maritime routing platform |
| Average speed `v` | 25.93 km/h (14 knots) | Representative of Panamax vessels |
| Aggregate consumption `c` | 40 t/day | Order of magnitude for the Panamax dry-bulk market |

The conventional scenario derives from these three values: voyage time `T = D / v`, fuel mass
`F_kg(0) = c * T`, and the useful voyage demand that is held constant across scenarios.

### Fossil reference

| Parameter | Value | Source |
| --- | --- | --- |
| `PCI_b` | 40.2 MJ/kg | IPCC (2006), Residual Fuel Oil category |
| `FE_b` | 3.114 kgCO2/kg | IPCC (2006), Residual Fuel Oil category |
| `eta_b` | 0.45 | Representative value for comparative modeling |
| `p_b` | 0.50 USD/kg | Order of magnitude from recent techno-economic assessments |

### Biodiesel pathways

| Pathway | `PCI_bio` (MJ/kg) | `eta_bio` | `FE_bio` (kgCO2/kg) | `p_bio` (USD/kg) |
| --- | --- | --- | --- | --- |
| Soybean | 37.68 | 0.43 | 1.320 | 1.60 |
| Beef tallow | 37.68 | 0.43 | 0.640 | 1.60 |
| UCO | 37.68 | 0.43 | 0.560 | 1.60 |
| TCO | 36.64 | 0.43 | 0.513 | 1.60 |

- Lower heating values for soybean, beef tallow, and UCO are consistent with RenovaCalc.
- The TCO lower heating value is the calorific value of corn oil methyl ester measured under ASTM
  standards by Balaji et al. (2019), Data in Brief 27:104683.
- Emission factors for soybean, beef tallow, and UCO follow RenovaBio references and their recent
  methodological systematization.
- The TCO emission factor is converted from Wang et al. (2015), Biotechnology for Biofuels 8:178,
  under the marginal co-product treatment method, since TCO is recovered as a co-product of corn
  ethanol production. This factor is more sensitive to the co-product allocation method than the
  factors of the consolidated residue pathways, which is why the model includes a specific
  sensitivity analysis for emission factors and prices.
- The unit price is the same for the four pathways. In E1-E7 the ordering among them therefore
  follows from emission factors, lower heating values, and efficiencies alone. Differentiated prices
  enter only with the state-level supply compositions.

### Environmental and regulatory parameters

| Parameter | Value | Note |
| --- | --- | --- |
| `delta` | 0.15 | Minimum emission reduction; E4 varies it from 0.10 to 0.25, step 0.01 |
| `gamma_ref` | 80 EUR/tCO2 | E4 varies it from 60 to 120; E7 from 80 to 350, step 10 |
| `gamma_comp` | 0 EUR/tCO2 in the baseline | E6 and E8 vary it from 0 to 700, step 10; E7 from 80 to 700 |
| `ets_coverage` (`lambda`) | 0.50 | Share of voyage emissions covered on voyages arriving from a port outside the European Union |
| `ets_phase_in` (`rho`) | 1.00 | Phase-in of the allowance-surrender obligation in force from 2026 onward |
| TTW factor of the renewable fraction | 0 | Sustainable biomass eligible for a zero surrender factor under the EU ETS |

### Currency conversion

| Parameter | Value | Source |
| --- | --- | --- |
| EUR to USD | 1.1581 | European Central Bank euro foreign exchange reference rate, 11 March 2026 |
| BRL to USD | 5.2296 | Average rate for the observation period |
| Biodiesel density | 0.88 kg/L | Used to convert ANP prices from BRL/L to USD/kg |

The marginal abatement cost is computed in USD/tCO2, so the comparison with `gamma_ref` is made
after converting the reference cost from EUR/tCO2 to USD/tCO2.

### State-level supply compositions

Feedstock shares and regional B100 prices refer to March 2026. The five states are those with the
highest biodiesel production in that month, according to the ANP dynamic panel of biodiesel
producers. Emission factors are averages weighted by the volumetric share of each feedstock in
state production. These compositions are model representations approximated from observed feedstock
shares and regional prices; they are not observed marine-fuel batches.

### Blend composition

The lower heating value of a blend is a mass-weighted average of its components. The effective
efficiency is computed from the efficiencies of the components weighted by their energy
contribution, so that the required fuel mass varies with composition while the useful voyage demand
stays constant.

## Notes

- `gamma_comp` changes total scenario cost by adding an explicit compliance component.
- `gamma_ref` is the reference threshold used to classify whether the remaining marginal abatement cost is acceptable.
- E1-E5 keep `gamma_comp = 0`.
- E6-E8 activate the compliance-cost mechanism.
- The marginal abatement cost does not depend on `delta` or `gamma_ref`, which appear only in the
  classification rule, so the interval reported for E4 is invariant by construction. The three
  parameters varied in E5 scale the size of the voyage, so incremental cost and avoided emissions
  change in the same proportion and their ratio is preserved.
- The state-level compositions do not replace the representative pathways. They extend the
  assessment to an aggregate representation of Brazilian supply, approximated from observed
  feedstock shares and regional prices for March 2026. They are model representations, not
  observed marine-fuel batches, and they carry differentiated regional prices, which the four
  representative pathways do not.
