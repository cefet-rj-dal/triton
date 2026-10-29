# Robust Viability Frontiers (RVF)

This folder contains the probabilistic extension of Triton for the proposed IEEE
Latin America Transactions article. It is intentionally isolated from the root
scripts and outputs used in the submitted WMU Journal of Maritime Affairs paper.

## Purpose

RVF reframes the deterministic viability frontier as a robust decision problem.
Instead of asking only whether a biodiesel blend is viable under fixed
parameters, it estimates the probability that a scenario satisfies both
environmental and economic-regulatory criteria under uncertain fuel prices,
emission factors, operation, exchange rate, and carbon-price signals.

## Baselines

The extension uses two baselines:

- The deterministic Triton classification from the submitted article.
- Plain Monte Carlo sampling, used as an efficiency baseline for Latin Hypercube
  Sampling at the same sample sizes.

The contribution is not that Monte Carlo or Latin Hypercube Sampling are new
methods. The contribution is the robust viability frontier that combines
Brazilian state-level biodiesel blends, well-to-wake emissions, voyage-level
cost, marginal abatement cost, and the separation between explicit compliance
cost (`gamma_comp`) and the reference carbon value (`gamma_ref`).

## Structure

- `code/rvf_simulation.R`: probabilistic simulation and sampling-efficiency
  comparison.
- `results/tables/`: generated CSV tables.
- `results/figures/`: generated PNG figures.
- `paper/main.tex`: IEEE-style manuscript draft.
- `paper/references.bib`: references for the IEEE draft.

## Reproducing

From the repository root:

```bash
Rscript RVF/code/rvf_simulation.R
```

The script writes only inside `RVF/results/`.
