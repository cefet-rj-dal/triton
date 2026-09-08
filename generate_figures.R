suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(readr)
})

dir.create("resultados/graficos", recursive = TRUE, showWarnings = FALSE)
dir.create("legado/resultados/graficos", recursive = TRUE, showWarnings = FALSE)

pathway_labels <- c(
  "soja" = "Soybean",
  "sebo bovino" = "Beef tallow",
  "UCO" = "UCO",
  "TCO" = "TCO"
)

pathway_levels <- c("Soybean", "Beef tallow", "UCO", "TCO")
state_levels <- c("Bahia", "Goias", "Mato Grosso", "Parana", "Rio Grande do Sul")

label_state <- function(x) {
  out <- as.character(x)
  out[grepl("^Goi", out)] <- "Goias"
  out[grepl("^Paran", out)] <- "Parana"
  out
}

theme_triton <- function(base_size = 15) {
  theme_minimal(base_size = base_size) +
    theme(
      axis.title = element_text(size = base_size + 1),
      axis.text = element_text(size = base_size - 1),
      legend.title = element_text(size = base_size - 1),
      legend.text = element_text(size = base_size - 2),
      strip.text = element_text(size = base_size + 1),
      panel.grid.minor = element_line(color = "grey92", linewidth = 0.25),
      panel.grid.major = element_line(color = "grey86", linewidth = 0.35),
      legend.position = "bottom"
    )
}

save_plot <- function(plot_obj, filename, width = 10, height = 6.5, dpi = 300,
                      base_dir = file.path("resultados", "graficos")) {
  ggsave(
    filename = file.path(base_dir, filename),
    plot = plot_obj,
    width = width,
    height = height,
    dpi = dpi,
    bg = "white"
  )
}

format_decimal_en <- function(x, digits = 1) {
  format(round(x, digits), decimal.mark = ".", big.mark = ",", nsmall = digits)
}

format_usd_k <- function(x) {
  paste0("$", trimws(format(round(x / 1000, 0), big.mark = ",")), "k")
}

res_E1 <- read_csv("resultados/tabelas/E1_cenario_base.csv", show_col_types = FALSE)
res_E4 <- read_csv("resultados/tabelas/E4_sensibilidade_regulatoria.csv", show_col_types = FALSE)
res_E6 <- read_csv("resultados/tabelas/E6_caminhos_viabilidade.csv", show_col_types = FALSE)
res_E7 <- read_csv("resultados/tabelas/E7_blends_estaduais_base.csv", show_col_types = FALSE)
res_E7_reg <- read_csv("resultados/tabelas/E7_blends_estaduais_regulatorio.csv", show_col_types = FALSE)

res_E1_plot <- res_E1 %>%
  mutate(pathway = factor(recode(rota, !!!pathway_labels), levels = pathway_levels))

g1 <- ggplot(res_E1_plot, aes(x = alpha, y = G_t, group = pathway, linetype = pathway)) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.8) +
  labs(
    x = expression(alpha),
    y = "Total emissions (tCO2/voyage)",
    linetype = "Biodiesel pathway"
  ) +
  theme_triton()

save_plot(g1, "grafico_01_emissoes_vs_alpha.png")

g2 <- ggplot(res_E1_plot, aes(x = alpha, y = C_USD, group = pathway, linetype = pathway)) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.8) +
  labs(
    x = expression(alpha),
    y = "Total cost (USD/voyage)",
    linetype = "Biodiesel pathway"
  ) +
  theme_triton()

save_plot(g2, "grafico_02_custo_vs_alpha.png",
          base_dir = file.path("legado", "resultados", "graficos"))

g3 <- ggplot(res_E1_plot, aes(x = alpha, y = MAC_USD_tCO2, group = pathway, linetype = pathway)) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.8) +
  geom_hline(yintercept = first(res_E1$gamma_ref_usd), linewidth = 0.8) +
  labs(
    x = expression(alpha),
    y = expression("MAC " * "(" * USD/tCO[2] * ")"),
    linetype = "Biodiesel pathway"
  ) +
  theme_triton()

save_plot(g3, "grafico_03_mac_vs_alpha.png",
          base_dir = file.path("legado", "resultados", "graficos"))

policy_lines <- tibble(y = c(80, 150, 200, 300, 400))

break_even_E1 <- res_E1_plot %>%
  group_by(pathway) %>%
  summarise(break_even_EUR_tCO2 = first(break_even_EUR_tCO2), .groups = "drop")

g3b <- ggplot(
  break_even_E1,
  aes(x = reorder(pathway, break_even_EUR_tCO2), y = break_even_EUR_tCO2)
) +
  geom_hline(data = policy_lines, aes(yintercept = y), linewidth = 0.5, alpha = 0.45) +
  geom_col(width = 0.65, fill = "grey35") +
  geom_text(
    aes(label = format_decimal_en(break_even_EUR_tCO2, 1)),
    vjust = -0.4,
    size = 5.0
  ) +
  labs(
    x = "Biodiesel pathway",
    y = expression("Break-even carbon price " * "(" * EUR/tCO[2] * ")")
  ) +
  coord_cartesian(ylim = c(0, 740)) +
  theme_triton()

save_plot(g3b, "grafico_03b_break_even_vs_alpha.png")

g4 <- ggplot(res_E1_plot, aes(x = Delta_G_t, y = Delta_C_USD, linetype = pathway)) +
  geom_point(size = 2.8) +
  geom_path(linewidth = 1.0) +
  labs(
    x = "Emission reduction (tCO2/voyage)",
    y = "Incremental cost (USD/voyage)",
    linetype = "Biodiesel pathway"
  ) +
  theme_triton()

save_plot(g4, "grafico_04_tradeoff_deltaG_deltaC.png")

heat_E4 <- res_E4 %>%
  filter(delta_ref == first(delta_ref) | delta_ref == 0.15) %>%
  filter(gamma_ref_eur == first(gamma_ref_eur) | gamma_ref_eur == 80) %>%
  mutate(
    pathway = factor(recode(rota, !!!pathway_labels), levels = pathway_levels),
    alpha_f = factor(alpha)
  )

g5 <- ggplot(heat_E4, aes(x = alpha_f, y = pathway, fill = factor(V))) +
  geom_tile(color = "white") +
  scale_fill_manual(
    values = c("0" = "#F8766D", "1" = "#00BFC4"),
    labels = c("0" = "Non-viable", "1" = "Viable")
  ) +
  labs(
    x = expression(alpha),
    y = "Biodiesel pathway",
    fill = "Classification"
  ) +
  theme_triton()

save_plot(g5, "grafico_05_heatmap_viabilidade.png",
          base_dir = file.path("legado", "resultados", "graficos"))

cost_compare <- res_E6 %>%
  filter(gamma_comp_signal_eur == 650, abs(alpha - 0.24) < 1e-9) %>%
  mutate(pathway = factor(recode(rota, !!!pathway_labels), levels = pathway_levels))

cost_compare_bunker <- cost_compare %>%
  slice(1) %>%
  transmute(
    scenario = "Bunker fuel",
    `Fuel cost` = C0_fuel_USD,
    `Compliance cost` = C0_comp_USD
  )

cost_compare_biobunker <- cost_compare %>%
  transmute(
    scenario = paste(pathway, "B24"),
    `Fuel cost` = C_fuel_USD,
    `Compliance cost` = C_comp_USD
  )

cost_compare_plot <- bind_rows(cost_compare_bunker, cost_compare_biobunker) %>%
  mutate(
    scenario = factor(
      scenario,
      levels = c("Bunker fuel", "UCO B24", "TCO B24", "Beef tallow B24", "Soybean B24")
    )
  ) %>%
  pivot_longer(
    cols = c(`Fuel cost`, `Compliance cost`),
    names_to = "component",
    values_to = "custo_usd"
  ) %>%
  mutate(component = factor(component, levels = c("Fuel cost", "Compliance cost")))

total_labels_g6 <- cost_compare_plot %>%
  group_by(scenario) %>%
  summarise(custo_total = sum(custo_usd), .groups = "drop") %>%
  mutate(label = format_usd_k(custo_total))

g6 <- ggplot(cost_compare_plot, aes(x = scenario, y = custo_usd, fill = component)) +
  geom_col(width = 0.68) +
  geom_text(
    data = total_labels_g6,
    aes(x = scenario, y = custo_total, label = label),
    inherit.aes = FALSE,
    vjust = -0.35,
    size = 5.0
  ) +
  scale_fill_manual(values = c("Fuel cost" = "grey45", "Compliance cost" = "#2C7FB8")) +
  scale_y_continuous(labels = format_usd_k) +
  labs(
    x = NULL,
    y = "Total cost (USD/voyage)",
    fill = "Cost component"
  ) +
  coord_cartesian(ylim = c(0, max(total_labels_g6$custo_total) * 1.08)) +
  theme_triton() +
  theme(axis.text.x = element_text(angle = 15, hjust = 1))

save_plot(g6, "grafico_06_decomposicao_custo.png", width = 10.5)

cost_compare_legacy <- res_E6 %>%
  filter(gamma_comp_signal_eur == 650) %>%
  transmute(
    pathway = factor(recode(rota, !!!pathway_labels), levels = pathway_levels),
    alpha,
    `Biobunker` = C_USD,
    `Bunker fuel with compliance` = C0_USD
  ) %>%
  pivot_longer(
    cols = c(`Biobunker`, `Bunker fuel with compliance`),
    names_to = "cenario",
    values_to = "custo_usd"
  ) %>%
  mutate(cenario = factor(cenario, levels = c("Biobunker", "Bunker fuel with compliance")))

g6_legacy <- ggplot(cost_compare_legacy, aes(x = alpha, y = custo_usd, color = cenario, linetype = cenario)) +
  geom_line(linewidth = 1.0) +
  geom_point(size = 2.8) +
  facet_wrap(~ pathway, scales = "free_y") +
  scale_color_manual(values = c("Biobunker" = "#C43C39", "Bunker fuel with compliance" = "#2C7FB8")) +
  scale_linetype_manual(values = c("Biobunker" = "solid", "Bunker fuel with compliance" = "solid")) +
  labs(
    x = expression(alpha),
    y = "Total cost (USD/voyage)",
    color = "Scenario",
    linetype = "Scenario"
  ) +
  theme_triton()

save_plot(g6_legacy, "grafico_06_comparacao_custo_total_legacy.png",
          width = 10.5,
          base_dir = file.path("legado", "resultados", "graficos"))

frontier_E6 <- res_E6 %>%
  mutate(
    pathway = factor(recode(rota, !!!pathway_labels), levels = pathway_levels),
    alpha_f = factor(alpha),
    economic_ok = !is.na(MAC_EUR_tCO2) & MAC_EUR_tCO2 <= gamma_ref_signal_eur,
    env_ok = G_t <= (1 - delta_ref) * G0_t,
    status_viabilidade = case_when(
      V == 1 ~ "Viable",
      economic_ok & !env_ok ~ "Economic criterion only",
      TRUE ~ "Non-viable"
    ),
    status_viabilidade = factor(
      status_viabilidade,
      levels = c("Non-viable", "Economic criterion only", "Viable")
    )
  )

g7 <- ggplot(frontier_E6, aes(x = alpha_f, y = gamma_comp_signal_eur, fill = status_viabilidade)) +
  geom_tile(color = "white") +
  facet_wrap(~ pathway) +
  scale_y_continuous(breaks = seq(0, 700, by = 100)) +
  scale_fill_manual(values = c(
    "Non-viable" = "#F8766D",
    "Economic criterion only" = "#F2C94C",
    "Viable" = "#00BFC4"
  )) +
  labs(
    x = expression(alpha),
    y = expression("Compliance " * gamma^{comp} * " (" * EUR/tCO[2] * ")"),
    fill = "Classification"
  ) +
  theme_triton()

save_plot(g7, "grafico_07_fronteira_viabilidade.png", width = 10.5, height = 7)

heat_break_even <- res_E1_plot %>%
  mutate(alpha_f = factor(alpha))

g8 <- ggplot(heat_break_even, aes(x = alpha_f, y = pathway, fill = break_even_EUR_tCO2)) +
  geom_tile(color = "white") +
  labs(
    x = expression(alpha),
    y = "Biodiesel pathway",
    fill = expression("Break-even" ~ "(" * EUR/tCO[2] * ")")
  ) +
  theme_triton()

save_plot(g8, "grafico_08_heatmap_break_even.png",
          base_dir = file.path("legado", "resultados", "graficos"))

cores_estados <- c(
  "Bahia" = "#1f77b4",
  "Goias" = "#d62728",
  "Mato Grosso" = "#2ca02c",
  "Parana" = "#ff7f0e",
  "Rio Grande do Sul" = "#9467bd"
)

g9_data <- res_E7 %>%
  mutate(state = factor(label_state(rota), levels = state_levels))

g9 <- ggplot(
  g9_data,
  aes(x = alpha, y = break_even_EUR_tCO2, group = state, color = state, linetype = state)
) +
  geom_hline(data = policy_lines, aes(yintercept = y), linewidth = 0.5, alpha = 0.45, color = "grey40") +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.8) +
  scale_color_manual(values = cores_estados) +
  labs(
    x = expression(alpha),
    y = expression("Break-even carbon price " * "(" * EUR/tCO[2] * ")"),
    color = "State blend",
    linetype = "State blend"
  ) +
  theme_triton()

save_plot(g9, "grafico_09_break_even_estados.png", width = 10.5)

frontier_E7 <- res_E7_reg %>%
  mutate(
    state = factor(label_state(rota), levels = state_levels),
    alpha_f = factor(alpha)
  )

g10 <- ggplot(frontier_E7, aes(x = alpha_f, y = gamma_comp_signal_eur, fill = factor(V))) +
  geom_tile(color = "white") +
  facet_wrap(~ state) +
  scale_y_continuous(breaks = seq(0, 700, by = 100)) +
  scale_fill_manual(
    values = c("0" = "#F8766D", "1" = "#00BFC4"),
    labels = c("0" = "Non-viable", "1" = "Viable")
  ) +
  labs(
    x = expression(alpha),
    y = expression("Compliance " * gamma^{comp} * " (" * EUR/tCO[2] * ")"),
    fill = "Classification"
  ) +
  theme_triton()

save_plot(g10, "grafico_10_fronteira_viabilidade_estados.png", width = 10.5, height = 7)
