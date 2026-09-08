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

E8 replaces isolated biodiesel pathways with observed aggregate blends from Brazilian states. This tests whether the central interpretation persists when biodiesel is represented by empirical supply compositions and regional B100 prices.

The simulator output file names still use `E7` for the state-level experiment because that branch was created before the article narrative was expanded. In the article text, the corresponding state-level experiment is described as E8.

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

## Notes

- `gamma_comp` changes total scenario cost by adding an explicit compliance component.
- `gamma_ref` is the reference threshold used to classify whether the remaining marginal abatement cost is acceptable.
- E1-E5 keep `gamma_comp = 0`.
- E6-E8 activate the compliance-cost mechanism.
- State-level blends do not replace the representative pathways. They provide an empirical extension using observed Brazilian biodiesel supply data.
