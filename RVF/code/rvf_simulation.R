# ============================================================
# RVF: Robust Viability Frontiers
# Probabilistic extension of Triton for the IEEE LATAM article.
#
# This script writes only to RVF/results and does not modify the
# deterministic article-1 scripts or outputs in the repository root.
# ============================================================

suppressPackageStartupMessages({
  library(ggplot2)
})

set.seed(20261008)

`%||%` <- function(x, y) if (is.null(x)) y else x

script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_path <- if (length(script_arg) == 1) sub("^--file=", "", script_arg) else "RVF/code/rvf_simulation.R"
script_dir <- dirname(normalizePath(script_path, mustWork = FALSE))
root_dir <- normalizePath(file.path(script_dir, "..", ".."), mustWork = FALSE)
if (!dir.exists(file.path(root_dir, "RVF"))) {
  root_dir <- normalizePath(getwd(), mustWork = TRUE)
}

rvf_dir <- file.path(root_dir, "RVF")
tables_dir <- file.path(rvf_dir, "results", "tables")
figures_dir <- file.path(rvf_dir, "results", "figures")
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

# -----------------------------
# Deterministic Triton parameters
# -----------------------------

params <- list(
  D_base_km = 10120,
  V_base_kmh = 25.93,
  c_base_tday = 40,
  PCI_b = 40.2,
  eta_b = 0.45,
  p_b = 0.50,
  FE_b = 3.114,
  delta_ref = 0.15,
  gamma_ref_eur = 80,
  eur_to_usd = 1.1581,
  ets_coverage = 0.50,
  ets_phase_in = 1.00,
  FE_b_ttw_ets = 3.114,
  FE_bio_ttw_ets = 0
)

fuel_states <- data.frame(
  rota = c("Bahia", "Goias", "Mato Grosso", "Parana", "Rio Grande do Sul"),
  PCI_bio = rep(37.68, 5),
  eta_bio = rep(0.43, 5),
  p_bio = c(1.1452544606227488, 1.1061392666916992, 1.1061392666916992,
            1.0736785013976387, 1.0736785013976387),
  FE_bio = c(1.14, 1.21, 1.18, 1.17, 1.24),
  stringsAsFactors = FALSE
)
fuel_states$scenario <- paste0(fuel_states$rota, " B30")
fuel_states$alpha <- 0.30

# -----------------------------
# Distribution helpers
# -----------------------------

qtri <- function(u, min, mode, max) {
  fc <- (mode - min) / (max - min)
  ifelse(
    u < fc,
    min + sqrt(u * (max - min) * (mode - min)),
    max - sqrt((1 - u) * (max - min) * (max - mode))
  )
}

qlognorm_cv <- function(u, mean, cv) {
  sigma <- sqrt(log(1 + cv^2))
  mu <- log(mean) - 0.5 * sigma^2
  qlnorm(u, meanlog = mu, sdlog = sigma)
}

sample_unit <- function(n, p, method = c("mc", "lhs")) {
  method <- match.arg(method)
  if (method == "mc") {
    matrix(runif(n * p), nrow = n, ncol = p)
  } else {
    out <- matrix(NA_real_, nrow = n, ncol = p)
    for (j in seq_len(p)) {
      out[, j] <- (sample.int(n) - runif(n)) / n
    }
    out
  }
}

draw_uncertainty <- function(n, method = c("mc", "lhs")) {
  u <- sample_unit(n, 10, method)
  data.frame(
    p_b = qlognorm_cv(u[, 1], params$p_b, 0.15),
    p_bio_mult = qlognorm_cv(u[, 2], 1.00, 0.20),
    FE_b = qlognorm_cv(u[, 3], params$FE_b, 0.05),
    FE_bio_mult = qlognorm_cv(u[, 4], 1.00, 0.20),
    c_tday = qtri(u[, 5], 34, params$c_base_tday, 46),
    D_km = qtri(u[, 6], 0.95 * params$D_base_km, params$D_base_km, 1.05 * params$D_base_km),
    gamma_comp_eur = qtri(u[, 7], 150, 320, 700),
    gamma_ref_eur = qtri(u[, 8], 60, params$gamma_ref_eur, 180),
    eur_to_usd = qlognorm_cv(u[, 9], params$eur_to_usd, 0.06),
    delta_ref = qtri(u[, 10], 0.10, params$delta_ref, 0.25)
  )
}

# -----------------------------
# Vectorized voyage model
# -----------------------------

calc_rvf <- function(draws, fuel, alpha = 0.30) {
  T_h <- draws$D_km / params$V_base_kmh
  F0_kg <- (draws$c_tday / 24) * T_h * 1000
  E_req_MJ <- F0_kg * params$PCI_b * params$eta_b

  p_bio <- fuel$p_bio * draws$p_bio_mult
  FE_bio <- fuel$FE_bio * draws$FE_bio_mult

  PCI_mix <- (1 - alpha) * params$PCI_b + alpha * fuel$PCI_bio
  p_mix <- (1 - alpha) * draws$p_b + alpha * p_bio
  FE_mix <- (1 - alpha) * draws$FE_b + alpha * FE_bio
  FE_mix_ets_ttw <- (1 - alpha) * params$FE_b_ttw_ets + alpha * params$FE_bio_ttw_ets
  eta_mix <- (((1 - alpha) * params$PCI_b * params$eta_b) +
    (alpha * fuel$PCI_bio * fuel$eta_bio)) / PCI_mix

  F_mix_kg <- E_req_MJ / (PCI_mix * eta_mix)

  gamma_comp_usd <- draws$gamma_comp_eur * draws$eur_to_usd
  gamma_ref_usd <- draws$gamma_ref_eur * draws$eur_to_usd

  G0_t <- F0_kg * draws$FE_b / 1000
  ETS0_t <- F0_kg * params$FE_b_ttw_ets / 1000 * params$ets_coverage * params$ets_phase_in
  C0 <- (F0_kg * draws$p_b) + (ETS0_t * gamma_comp_usd)

  G_t <- F_mix_kg * FE_mix / 1000
  ETS_t <- F_mix_kg * FE_mix_ets_ttw / 1000 * params$ets_coverage * params$ets_phase_in
  C <- (F_mix_kg * p_mix) + (ETS_t * gamma_comp_usd)

  Delta_G_t <- G0_t - G_t
  Delta_C_USD <- C - C0
  MAC_USD_tCO2 <- Delta_C_USD / Delta_G_t
  MAC_EUR_tCO2 <- MAC_USD_tCO2 / draws$eur_to_usd
  env_ok <- G_t <= (1 - draws$delta_ref) * G0_t
  econ_ok <- MAC_USD_tCO2 <= gamma_ref_usd
  V <- as.integer(env_ok & econ_ok & is.finite(MAC_USD_tCO2))

  data.frame(
    scenario = fuel$scenario,
    alpha = alpha,
    V = V,
    env_ok = as.integer(env_ok),
    econ_ok = as.integer(econ_ok),
    G_t = G_t,
    Delta_G_t = Delta_G_t,
    C_USD = C,
    Delta_C_USD = Delta_C_USD,
    MAC_EUR_tCO2 = MAC_EUR_tCO2,
    gamma_comp_eur = draws$gamma_comp_eur,
    gamma_ref_eur = draws$gamma_ref_eur
  )
}

simulate_scenarios <- function(n, method = "lhs", fuels = fuel_states) {
  draws <- draw_uncertainty(n, method)
  do.call(rbind, lapply(seq_len(nrow(fuels)), function(i) calc_rvf(draws, fuels[i, ], fuels$alpha[i])))
}

summarize_rvf <- function(x) {
  do.call(rbind, lapply(split(x, x$scenario), function(z) {
    data.frame(
      scenario = z$scenario[1],
      alpha = z$alpha[1],
      p_viable = mean(z$V),
      p_env_ok = mean(z$env_ok),
      p_econ_ok = mean(z$econ_ok),
      mac_p05 = unname(quantile(z$MAC_EUR_tCO2, 0.05, na.rm = TRUE)),
      mac_p50 = unname(quantile(z$MAC_EUR_tCO2, 0.50, na.rm = TRUE)),
      mac_p95 = unname(quantile(z$MAC_EUR_tCO2, 0.95, na.rm = TRUE)),
      deltaG_p50 = unname(quantile(z$Delta_G_t, 0.50, na.rm = TRUE)),
      deltaC_p50 = unname(quantile(z$Delta_C_USD, 0.50, na.rm = TRUE)),
      gamma_comp_p50 = unname(quantile(z$gamma_comp_eur, 0.50, na.rm = TRUE))
    )
  }))
}

# -----------------------------
# Main probabilistic run
# -----------------------------

N_MAIN <- 10000
rvf_main <- simulate_scenarios(N_MAIN, "lhs")
rvf_summary <- summarize_rvf(rvf_main)
rvf_summary <- rvf_summary[order(-rvf_summary$p_viable), ]

write.csv(rvf_summary, file.path(tables_dir, "rvf_summary_lhs_10000.csv"), row.names = FALSE)

det_first <- data.frame(
  scenario = c("Bahia B30", "Goias B30", "Mato Grosso B30", "Parana B30", "Rio Grande do Sul B30"),
  gamma_comp_signal_eur = c(340, 320, 320, 300, 300),
  break_even_EUR_tCO2 = c(77.66476833196543, 77.38100373714578, 75.93828817632806,
                          75.38364080407166, 78.79010750003305),
  Delta_G_t = c(332.1997592748396, 318.0984868886426, 324.14188933986975,
                326.1563568236122, 312.05508443741496),
  stringsAsFactors = FALSE
)
det_compare <- merge(
  det_first,
  rvf_summary[, c("scenario", "p_viable", "p_env_ok", "p_econ_ok", "mac_p50")],
  by = "scenario",
  all.y = TRUE
)
write.csv(det_compare, file.path(tables_dir, "deterministic_vs_rvf.csv"), row.names = FALSE)

# -----------------------------
# Sampling-efficiency baseline
# -----------------------------

N_REF <- 50000
ref <- summarize_rvf(simulate_scenarios(N_REF, "lhs"))
ref_p <- setNames(ref$p_viable, ref$scenario)

sample_sizes <- c(250, 500, 1000, 2000)
replicates <- 30

eff_rows <- list()
k <- 1
for (method in c("mc", "lhs")) {
  for (n in sample_sizes) {
    err <- numeric(replicates)
    for (r in seq_len(replicates)) {
      s <- summarize_rvf(simulate_scenarios(n, method))
      p <- setNames(s$p_viable, s$scenario)
      err[r] <- sqrt(mean((p[names(ref_p)] - ref_p)^2))
    }
    eff_rows[[k]] <- data.frame(
      method = method,
      n = n,
      rmse_mean = mean(err),
      rmse_sd = sd(err),
      rmse_p95 = unname(quantile(err, 0.95))
    )
    k <- k + 1
  }
}
efficiency <- do.call(rbind, eff_rows)
write.csv(efficiency, file.path(tables_dir, "sampling_efficiency_mc_vs_lhs.csv"), row.names = FALSE)

# -----------------------------
# Parameter importance
# -----------------------------

draws_imp <- draw_uncertainty(N_MAIN, "lhs")
imp_target <- calc_rvf(draws_imp, fuel_states[fuel_states$rota == "Parana", ], 0.30)
importance_data <- data.frame(
  V = imp_target$V,
  draws_imp
)

fit <- glm(
  V ~ p_b + p_bio_mult + FE_b + FE_bio_mult + c_tday + D_km +
    gamma_comp_eur + gamma_ref_eur + eur_to_usd + delta_ref,
  data = importance_data,
  family = binomial()
)

coef_tab <- summary(fit)$coefficients
importance <- data.frame(
  parameter = rownames(coef_tab),
  estimate = coef_tab[, "Estimate"],
  p_value = coef_tab[, "Pr(>|z|)"],
  row.names = NULL
)
importance <- importance[importance$parameter != "(Intercept)", ]
importance$abs_estimate <- abs(importance$estimate)
importance <- importance[order(-importance$abs_estimate), ]
write.csv(importance, file.path(tables_dir, "importance_logit_parana_b30.csv"), row.names = FALSE)

# -----------------------------
# Figures
# -----------------------------

rvf_summary$scenario <- factor(rvf_summary$scenario, levels = rvf_summary$scenario[order(rvf_summary$p_viable)])
p1 <- ggplot(rvf_summary, aes(x = scenario, y = p_viable)) +
  geom_col(fill = "#2A9D8F", width = 0.72) +
  coord_flip() +
  scale_y_continuous(labels = function(x) paste0(round(100 * x), "%"), limits = c(0, 1)) +
  labs(x = NULL, y = "Probability of viability", title = "Robust viability probability by state-level B30 blend") +
  theme_minimal(base_size = 11)
ggsave(file.path(figures_dir, "fig_probability_viability.png"), p1, width = 7.2, height = 4.2, dpi = 300)

p2 <- ggplot(efficiency, aes(x = n, y = rmse_mean, color = method, group = method)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  scale_color_manual(values = c(mc = "#E76F51", lhs = "#264653"), labels = c(mc = "Monte Carlo", lhs = "Latin Hypercube")) +
  labs(x = "Sample size per scenario", y = "RMSE against reference probability", color = NULL, title = "Sampling-efficiency baseline") +
  theme_minimal(base_size = 11)
ggsave(file.path(figures_dir, "fig_sampling_efficiency.png"), p2, width = 7.2, height = 4.2, dpi = 300)

top_imp <- head(importance, 8)
top_imp$parameter <- factor(top_imp$parameter, levels = rev(top_imp$parameter))
p3 <- ggplot(top_imp, aes(x = parameter, y = abs_estimate)) +
  geom_col(fill = "#457B9D", width = 0.72) +
  coord_flip() +
  labs(x = NULL, y = "Absolute logit coefficient", title = "Main drivers of robust viability for Paraná B30") +
  theme_minimal(base_size = 11)
ggsave(file.path(figures_dir, "fig_parameter_importance.png"), p3, width = 7.2, height = 4.2, dpi = 300)

message("RVF simulation complete.")
message("Tables: ", tables_dir)
message("Figures: ", figures_dir)
