suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(readr)
})

dir.create("br", recursive = TRUE, showWarnings = FALSE)

pathway_labels <- c(
  "soja" = "Soja",
  "sebo bovino" = "Sebo bovino",
  "UCO" = "UCO",
  "TCO" = "TCO"
)

pathway_levels <- c("Soja", "Sebo bovino", "UCO", "TCO")
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

save_plot_br <- function(plot_obj, filename, width = 10, height = 6.5, dpi = 300) {
  ggsave(
    filename = file.path("br", filename),
    plot = plot_obj,
    width = width,
    height = height,
    dpi = dpi,
    bg = "white"
  )
}

format_decimal_br <- function(x, digits = 1) {
  format(round(x, digits), decimal.mark = ",", big.mark = ".", nsmall = digits)
}

format_usd_k_br <- function(x) {
  paste0("USD ", trimws(format(round(x / 1000, 0), big.mark = ".", decimal.mark = ",")), " mil")
}

res_E1 <- read_csv("resultados/tabelas/E1_cenario_base.csv", show_col_types = FALSE)
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
    y = "Emissoes totais (tCO2/viagem)",
    linetype = "Rota do biodiesel"
  ) +
  theme_triton()

save_plot_br(g1, "grafico_01_emissoes_vs_alpha.png")

break_even_E1 <- res_E1_plot %>%
  group_by(pathway) %>%
  summarise(break_even_EUR_tCO2 = first(break_even_EUR_tCO2), .groups = "drop")

policy_lines <- tibble(y = c(80, 150, 200, 300, 400))

g3b <- ggplot(
  break_even_E1,
  aes(x = reorder(pathway, break_even_EUR_tCO2), y = break_even_EUR_tCO2)
) +
  geom_hline(data = policy_lines, aes(yintercept = y), linewidth = 0.5, alpha = 0.45) +
  geom_col(width = 0.65, fill = "grey35") +
  geom_text(
    aes(label = format_decimal_br(break_even_EUR_tCO2, 1)),
    vjust = -0.4,
    size = 5.0
  ) +
  labs(
    x = "Rota do biodiesel",
    y = expression("Preco de carbono de equilibrio " * "(" * EUR/tCO[2] * ")")
  ) +
  coord_cartesian(ylim = c(0, 740)) +
  theme_triton()

save_plot_br(g3b, "grafico_03b_break_even_vs_alpha.png")

g4 <- ggplot(res_E1_plot, aes(x = Delta_G_t, y = Delta_C_USD, linetype = pathway)) +
  geom_point(size = 2.8) +
  geom_path(linewidth = 1.0) +
  labs(
    x = "Reducao de emissoes (tCO2/viagem)",
    y = "Custo incremental (USD/viagem)",
    linetype = "Rota do biodiesel"
  ) +
  theme_triton()

save_plot_br(g4, "grafico_04_tradeoff_deltaG_deltaC.png")

cost_compare <- res_E6 %>%
  filter(gamma_comp_signal_eur == 650, abs(alpha - 0.24) < 1e-9) %>%
  mutate(pathway = factor(recode(rota, !!!pathway_labels), levels = pathway_levels))

cost_compare_bunker <- cost_compare %>%
  slice(1) %>%
  transmute(
    scenario = "Bunker fuel",
    `Custo do combustivel` = C0_fuel_USD,
    `Custo de compliance` = C0_comp_USD
  )

cost_compare_biobunker <- cost_compare %>%
  transmute(
    scenario = paste(pathway, "B24"),
    `Custo do combustivel` = C_fuel_USD,
    `Custo de compliance` = C_comp_USD
  )

cost_compare_plot <- bind_rows(cost_compare_bunker, cost_compare_biobunker) %>%
  mutate(
    scenario = factor(
      scenario,
      levels = c("Bunker fuel", "UCO B24", "TCO B24", "Sebo bovino B24", "Soja B24")
    )
  ) %>%
  pivot_longer(
    cols = c(`Custo do combustivel`, `Custo de compliance`),
    names_to = "component",
    values_to = "custo_usd"
  ) %>%
  mutate(component = factor(component, levels = c("Custo do combustivel", "Custo de compliance")))

total_labels_g6 <- cost_compare_plot %>%
  group_by(scenario) %>%
  summarise(custo_total = sum(custo_usd), .groups = "drop") %>%
  mutate(label = format_usd_k_br(custo_total))

g6 <- ggplot(cost_compare_plot, aes(x = scenario, y = custo_usd, fill = component)) +
  geom_col(width = 0.68) +
  geom_text(
    data = total_labels_g6,
    aes(x = scenario, y = custo_total, label = label),
    inherit.aes = FALSE,
    vjust = -0.35,
    size = 4.6
  ) +
  scale_fill_manual(values = c("Custo do combustivel" = "grey45", "Custo de compliance" = "#2C7FB8")) +
  scale_y_continuous(labels = format_usd_k_br) +
  labs(
    x = NULL,
    y = "Custo total (USD/viagem)",
    fill = "Componente de custo"
  ) +
  coord_cartesian(ylim = c(0, max(total_labels_g6$custo_total) * 1.08)) +
  theme_triton() +
  theme(axis.text.x = element_text(angle = 15, hjust = 1))

save_plot_br(g6, "grafico_06_decomposicao_custo.png", width = 10.5)

frontier_E6 <- res_E6 %>%
  mutate(
    pathway = factor(recode(rota, !!!pathway_labels), levels = pathway_levels),
    alpha_f = factor(alpha),
    economic_ok = !is.na(MAC_EUR_tCO2) & MAC_EUR_tCO2 <= gamma_ref_signal_eur,
    env_ok = G_t <= (1 - delta_ref) * G0_t,
    status_viabilidade = case_when(
      V == 1 ~ "Viavel",
      economic_ok & !env_ok ~ "Apenas criterio economico",
      TRUE ~ "Nao viavel"
    ),
    status_viabilidade = factor(
      status_viabilidade,
      levels = c("Nao viavel", "Apenas criterio economico", "Viavel")
    )
  )

g7 <- ggplot(frontier_E6, aes(x = alpha_f, y = gamma_comp_signal_eur, fill = status_viabilidade)) +
  geom_tile(color = "white") +
  facet_wrap(~ pathway) +
  scale_y_continuous(breaks = seq(0, 700, by = 100)) +
  scale_fill_manual(values = c(
    "Nao viavel" = "#F8766D",
    "Apenas criterio economico" = "#F2C94C",
    "Viavel" = "#00BFC4"
  )) +
  labs(
    x = expression(alpha),
    y = expression("Compliance " * gamma^{comp} * " (" * EUR/tCO[2] * ")"),
    fill = "Classificacao"
  ) +
  theme_triton()

save_plot_br(g7, "grafico_07_fronteira_viabilidade.png", width = 10.5, height = 7)

g9_data <- res_E7 %>%
  mutate(state = factor(label_state(rota), levels = state_levels))

cores_estados <- c(
  "Bahia" = "#1f77b4",
  "Goias" = "#d62728",
  "Mato Grosso" = "#2ca02c",
  "Parana" = "#ff7f0e",
  "Rio Grande do Sul" = "#9467bd"
)

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
    y = expression("Preco de carbono de equilibrio " * "(" * EUR/tCO[2] * ")"),
    color = "Blend estadual",
    linetype = "Blend estadual"
  ) +
  theme_triton()

save_plot_br(g9, "grafico_09_break_even_estados.png", width = 10.5)

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
    labels = c("0" = "Nao viavel", "1" = "Viavel")
  ) +
  labs(
    x = expression(alpha),
    y = expression("Compliance " * gamma^{comp} * " (" * EUR/tCO[2] * ")"),
    fill = "Classificacao"
  ) +
  theme_triton()

save_plot_br(g10, "grafico_10_fronteira_viabilidade_estados.png", width = 10.5, height = 7)
