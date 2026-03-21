# ============================================================
# Planejamento experimental do modelo de biobunker
# Dissertação de mestrado - versão inicial
# ============================================================

# -----------------------------
# Pacotes
# -----------------------------
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(forcats)
})

# -----------------------------
# Diretórios de saída
# -----------------------------
dir.create("resultados", showWarnings = FALSE)
dir.create("resultados/tabelas", recursive = TRUE, showWarnings = FALSE)
dir.create("resultados/graficos", recursive = TRUE, showWarnings = FALSE)

# -----------------------------
# Parâmetros globais
# -----------------------------

# Rota-base: Santos -> Roterdã
D_base_km   <- 10120      # km
V_base_kmh  <- 25.93      # km/h
c_base_tday <- 40         # t/dia

# Conversões operacionais
c_base_th <- c_base_tday / 24  # t/h

# Misturas avaliadas
alpha_grid <- c(0.10, 0.15, 0.20, 0.24, 0.25, 0.30)

# Rotas de produção do biodiesel
# Neste trabalho, TCO = Technical Corn Oil (óleo técnico de milho).
# A sigla não se refere a Tall Oil Crude.
rotas_bio <- c("soja", "sebo bovino", "UCO", "TCO")

# Critérios de viabilidade
delta_ref <- 0.15           # referência para critério ambiental
gamma_ref_eur <- 80         # EUR/tCO2, referência para comparar com MAC

# Faixas para sensibilidade
delta_grid <- c(0.10, 0.15, 0.20, 0.25)
gamma_grid_eur <- c(60, 80, 100)

# Câmbio de referência para comparar MAC (USD/tCO2) com gamma de referência (EUR/tCO2).
# Fonte: ECB euro foreign exchange reference rates, USD = 1.1581 em 11/03/2026.
# https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/index.en.html
eur_to_usd_ref <- 1.1581
gamma_ref <- gamma_ref_eur * eur_to_usd_ref
gamma_grid <- gamma_grid_eur * eur_to_usd_ref

# Componente gamma^comp associado ao custo explícito de compliance do EU ETS
# na rota Santos -> Roterdã, em modelagem simplificada.
# Regras-base:
# - viagens extra-UE para UE: 50% das emissões elegíveis cobertas;
# - phase-in: 100% para emissões de 2026 em diante;
# - biomassa sustentável elegível: fator zero para surrender no EU ETS.
gamma_comp_eur_ref <- 80
gamma_comp_usd_ref <- gamma_comp_eur_ref * eur_to_usd_ref
ets_coverage_ref <- 0.50
ets_phase_in_ref <- 1.00

# Sensibilidade econômica
pb_mult_grid    <- c(0.80, 1.00, 1.20)
pbio_mult_grid  <- c(0.80, 1.00, 1.20)

# Sensibilidade ambiental
fe_mult_grid <- c(0.90, 1.00, 1.10)

# Sensibilidade operacional
op_mult_grid <- c(0.90, 1.00, 1.10)

# Sensibilidade específica para TCO
tco_fe_mult_grid <- c(0.80, 1.00, 1.20)
tco_price_mult_grid <- c(0.70, 0.85, 1.00, 1.15)

# Penalidade de interação da mistura na eficiência do motor.
# Valor pequeno e configurável para evitar comportamento idealizado demais do blend.
# Base empírica para modelar efeito do teor de biodiesel sobre consumo/eficiência:
# - Gokalp, Buyukkaya, Soyhan (2011), Biomass and Bioenergy 35(8):3575-3583,
#   doi:10.1016/j.biombioe.2011.05.015. Em misturas com marine fuel e SME,
#   o BSFC aumenta e os blends de menor teor preservam melhor o desempenho.
# - Lujan et al. (2020), Applied Sciences 10(3):907, doi:10.3390/app10030907.
#   O aumento do teor de biodiesel eleva o consumo específico e reduz a BTE.
# - Zhu et al. (2012), Applied Energy 99:363-371, doi:10.1016/j.apenergy.2012.05.049.
#   BSFC e BTE variam com o blend e com a carga, indicando resposta não linear.
eta_blend_penalty <- 0.015

# -----------------------------
# Propriedades dos combustíveis
# -----------------------------

# Bunker fuel
PCI_b  <- 40.2             # MJ/kg
eta_b  <- 0.45
p_b    <- 0.50             # USD/kg
FE_b   <- 3.114            # kgCO2/kg

# Biodiesel por rota
# TCO = technical corn oil / distillers corn oil, subproduto da cadeia do milho
# e do etanol de milho. A sigla não se refere, aqui, a Tall Oil Crude.
# A literatura trata o TCO como óleo não comestível recuperado de thin
# stillage/DDGS em plantas dry mill de etanol de milho. No contexto regulatório
# europeu, o feedstock aparece na Union Database como matéria-prima
# reconhecida, mas sem marcação Annex IX, diferindo de UCO.
# Referências:
# - Wang et al. (2015), Biotechnol Biofuels 8:178, doi:10.1186/s13068-015-0350-8.
#   No método marginal, o biodiesel de technical corn oil apresentou 14 gCO2e/MJ.
# - Dhinesh et al. (2019), Data in Brief 25:104308, PMCID: PMC6838419.
#   O biodiesel B100 de corn oil methyl ester reportou calorific value de 36.64 MJ/kg.
# - Washington Administrative Code 173-424-110(137): define technical corn oil
#   como óleo não alimentar recuperado de thin stillage/DDGS.
# - Union Database for Biofuels (EC, revisão Nov/2025): "Technical corn oil"
#   listado como matéria-prima reconhecida, sem tag Annex IX.
# Observação metodológica: para TCO, o fator de emissão WTW é mais sensível ao
# método de alocação de coprodutos do que em rotas residuais mais consolidadas,
# razão pela qual o modelo inclui sensibilidade específica para FE e preço.
fuel_tbl <- tibble(
  rota = rotas_bio,
  PCI_bio = c(37.68, 37.68, 37.68, 36.64),      # MJ/kg
  eta_bio = c(0.43, 0.43, 0.43, 0.43),
  p_bio   = c(1.60, 1.60, 1.60, 1.60),          # USD/kg (valor inicial; pode ser ajustado)
  FE_bio  = c(1.32, 0.64, 0.56, 0.513)          # kgCO2/kg: soja, sebo bovino, UCO, TCO
)

FE_b_ttw_ets <- FE_b
FE_bio_ttw_ets <- 0

# -----------------------------
# Funções auxiliares
# -----------------------------

calc_operacao <- function(D_km, V_kmh, c_tday) {
  c_th <- c_tday / 24
  T_h  <- D_km / V_kmh
  F_t  <- c_th * T_h
  F_kg <- 1000 * F_t

  tibble(
    D_km = D_km,
    V_kmh = V_kmh,
    c_tday = c_tday,
    c_th = c_th,
    T_h = T_h,
    F_t = F_t,
    F_kg = F_kg
  )
}

calc_cenario <- function(alpha, rota,
                         D_km = D_base_km,
                         V_kmh = V_base_kmh,
                         c_tday = c_base_tday,
                         p_b_val = p_b,
                         FE_b_val = FE_b,
                         PCI_b_val = PCI_b,
                         eta_b_val = eta_b,
                         delta_val = delta_ref,
                         gamma_ref_val_eur = gamma_ref_eur,
                         eur_to_usd_val = eur_to_usd_ref,
                         gamma_comp_val_eur = gamma_comp_eur_ref,
                         ets_coverage_val = ets_coverage_ref,
                         ets_phase_in_val = ets_phase_in_ref,
                         FE_b_ttw_ets_val = FE_b_ttw_ets,
                         FE_bio_ttw_ets_val = FE_bio_ttw_ets,
                         eta_blend_penalty_val = eta_blend_penalty,
                         fuel_data = fuel_tbl) {

  op <- calc_operacao(D_km, V_kmh, c_tday)

  bio <- fuel_data %>% filter(rota == !!rota)

  stopifnot(nrow(bio) == 1)

  gamma_ref_val_usd <- gamma_ref_val_eur * eur_to_usd_val
  gamma_comp_val_usd <- gamma_comp_val_eur * eur_to_usd_val

  # Mantém o mesmo serviço energético útil da viagem em todos os cenários.
  # Essa é a comparação operacionalmente mais consistente: mesma rota, mesma carga,
  # mesma velocidade/meta de viagem, logo a demanda útil é fixa e a massa consumida
  # passa a depender do blend e da eficiência efetiva.
  E_req_MJ <- op$F_kg * PCI_b_val * eta_b_val

  PCI_mix <- (1 - alpha) * PCI_b_val + alpha * bio$PCI_bio
  p_mix   <- (1 - alpha) * p_b_val + alpha * bio$p_bio
  FE_mix  <- (1 - alpha) * FE_b_val + alpha * bio$FE_bio
  FE_mix_ets_ttw <- (1 - alpha) * FE_b_ttw_ets_val + alpha * FE_bio_ttw_ets_val
  eta_mix_ideal <- (((1 - alpha) * PCI_b_val * eta_b_val) +
    (alpha * bio$PCI_bio * bio$eta_bio)) / PCI_mix
  # A penalidade alpha*(1-alpha) representa desvio moderado do caso ideal de mistura.
  # Ela evita MAC constante em alpha e reflete o fato de que o desempenho do motor
  # com blends reais depende do teor de biodiesel, da atomização e da combustão.
  eta_mix <- pmax(eta_mix_ideal - eta_blend_penalty_val * alpha * (1 - alpha), 1e-9)
  e_mix_util_MJ_kg <- PCI_mix * eta_mix
  F_mix_kg <- E_req_MJ / e_mix_util_MJ_kg

  m_b_kg <- F_mix_kg * (1 - alpha)
  m_bio_kg <- F_mix_kg * alpha

  # Cenário convencional
  G0_kg <- op$F_kg * FE_b_val
  G0_t  <- G0_kg / 1000
  C0_fuel <- op$F_kg * p_b_val
  ETS0_t <- op$F_kg * FE_b_ttw_ets_val / 1000 * ets_coverage_val * ets_phase_in_val
  C0_comp <- ETS0_t * gamma_comp_val_usd
  C0 <- C0_fuel + C0_comp

  # Cenário mistura
  G_kg <- F_mix_kg * FE_mix
  G_t  <- G_kg / 1000
  C_fuel <- F_mix_kg * p_mix
  ETS_t <- F_mix_kg * FE_mix_ets_ttw / 1000 * ets_coverage_val * ets_phase_in_val
  C_comp <- ETS_t * gamma_comp_val_usd
  C <- C_fuel + C_comp

  Delta_G_t <- G0_t - G_t
  Delta_C   <- C - C0

  MAC <- ifelse(abs(Delta_G_t) < 1e-12, NA_real_, Delta_C / Delta_G_t)
  MAC_eur <- MAC / eur_to_usd_val
  break_even_usd <- MAC
  break_even_eur <- MAC_eur

  # Energia química e útil
  E_quim_MJ <- (m_b_kg * PCI_b_val) + (m_bio_kg * bio$PCI_bio)
  E_quim_GJ <- E_quim_MJ / 1000
  E_util_GJ <- E_quim_GJ * eta_mix
  eta_mix_eff <- ifelse(E_quim_GJ > 0, E_util_GJ / E_quim_GJ, NA_real_)

  # Critério de viabilidade
  V <- ifelse((G_t <= (1 - delta_val) * G0_t) & (!is.na(MAC)) & (MAC <= gamma_ref_val_usd), 1, 0)

  tibble(
    rota = rota,
    alpha = alpha,
    D_km = op$D_km,
    V_kmh = op$V_kmh,
    c_tday = op$c_tday,
    T_h = op$T_h,
    F_t = op$F_t,
    F0_kg = op$F_kg,
    F_kg = F_mix_kg,
    m_b_kg = m_b_kg,
    m_bio_kg = m_bio_kg,
    PCI_mix = PCI_mix,
    p_mix = p_mix,
    FE_mix = FE_mix,
    FE_mix_ets_ttw = FE_mix_ets_ttw,
    eta_mix = eta_mix_eff,
    E_req_GJ = E_req_MJ / 1000,
    E_quim_GJ = E_quim_GJ,
    E_util_GJ = E_util_GJ,
    G_t = G_t,
    ETS_t = ETS_t,
    C_fuel_USD = C_fuel,
    C_comp_USD = C_comp,
    C_USD = C,
    G0_t = G0_t,
    ETS0_t = ETS0_t,
    C0_fuel_USD = C0_fuel,
    C0_comp_USD = C0_comp,
    C0_USD = C0,
    Delta_G_t = Delta_G_t,
    Delta_C_USD = Delta_C,
    MAC_USD_tCO2 = MAC,
    MAC_EUR_tCO2 = MAC_eur,
    break_even_USD_tCO2 = break_even_usd,
    break_even_EUR_tCO2 = break_even_eur,
    delta_ref = delta_val,
    gamma_ref_eur = gamma_ref_val_eur,
    gamma_ref_usd = gamma_ref_val_usd,
    gamma_comp_eur = gamma_comp_val_eur,
    gamma_comp_usd = gamma_comp_val_usd,
    ets_coverage = ets_coverage_val,
    ets_phase_in = ets_phase_in_val,
    eur_to_usd = eur_to_usd_val,
    V = V
  )
}

save_plot <- function(plot_obj, filename, width = 9, height = 6, dpi = 300) {
  ggsave(
    filename = file.path("resultados/graficos", filename),
    plot = plot_obj,
    width = width,
    height = height,
    dpi = dpi,
    bg = "white"
  )
}

# -----------------------------
# Setup E1 - Cenário-base
# -----------------------------
res_E1 <- expand_grid(
  alpha = alpha_grid,
  rota = rotas_bio
) %>%
  pmap_dfr(\(alpha, rota) calc_cenario(alpha = alpha, rota = rota))

write_csv(res_E1, "resultados/tabelas/E1_cenario_base.csv")

# -----------------------------
# Setup E2 - Sensibilidade econômica
# -----------------------------
res_E2 <- expand_grid(
  alpha = alpha_grid,
  rota = rotas_bio,
  pb_mult = pb_mult_grid,
  pbio_mult = pbio_mult_grid
) %>%
  left_join(fuel_tbl, by = c("rota" = "rota")) %>%
  mutate(
    p_bio_adj = p_bio * pbio_mult,
    p_b_adj = p_b * pb_mult,
    fuel_data_adj = pmap(
      list(rota, PCI_bio, eta_bio, p_bio_adj, FE_bio),
      \(rota, PCI_bio, eta_bio, p_bio_adj, FE_bio) {
        tibble(
          rota = rota,
          PCI_bio = PCI_bio,
          eta_bio = eta_bio,
          p_bio = p_bio_adj,
          FE_bio = FE_bio
        )
      }
    ),
    data = pmap(
      list(alpha, rota, p_b_adj, fuel_data_adj),
      \(alpha, rota, p_b_adj, fuel_data_adj) {
        calc_cenario(
          alpha = alpha,
          rota = rota,
          p_b_val = p_b_adj,
          fuel_data = fuel_data_adj
        )
      }
    )
  ) %>%
  mutate(
    data = pmap(
      list(data, pb_mult, pbio_mult),
      \(data, pb_mult, pbio_mult) {
        bind_cols(tibble(pb_mult = pb_mult, pbio_mult = pbio_mult), data)
      }
    )
  ) %>%
  pull(data) %>%
  list_rbind()

write_csv(res_E2, "resultados/tabelas/E2_sensibilidade_economica.csv")

# -----------------------------
# Setup E3 - Sensibilidade ambiental
# -----------------------------
res_E3 <- expand_grid(
  alpha = alpha_grid,
  rota = rotas_bio,
  fe_mult = fe_mult_grid
) %>%
  left_join(fuel_tbl, by = c("rota" = "rota")) %>%
  mutate(
    FE_bio_adj = FE_bio * fe_mult,
    fuel_data_adj = pmap(
      list(rota, PCI_bio, eta_bio, p_bio, FE_bio_adj),
      \(rota, PCI_bio, eta_bio, p_bio, FE_bio_adj) {
        tibble(
          rota = rota,
          PCI_bio = PCI_bio,
          eta_bio = eta_bio,
          p_bio = p_bio,
          FE_bio = FE_bio_adj
        )
      }
    ),
    data = pmap(
      list(alpha, rota, fuel_data_adj),
      \(alpha, rota, fuel_data_adj) {
        calc_cenario(
          alpha = alpha,
          rota = rota,
          fuel_data = fuel_data_adj
        )
      }
    )
  ) %>%
  mutate(
    data = pmap(
      list(data, fe_mult),
      \(data, fe_mult) bind_cols(tibble(fe_mult = fe_mult), data)
    )
  ) %>%
  pull(data) %>%
  list_rbind()

write_csv(res_E3, "resultados/tabelas/E3_sensibilidade_ambiental.csv")

# -----------------------------
# Setup E4 - Sensibilidade regulatória
# -----------------------------
res_E4 <- expand_grid(
  alpha = alpha_grid,
  rota = rotas_bio,
  gamma_ref_eur = gamma_grid_eur,
  delta_ref = delta_grid
) %>%
  mutate(
    data = pmap(
      list(alpha, rota, delta_ref, gamma_ref_eur),
      \(alpha, rota, delta_ref, gamma_ref_eur) {
        calc_cenario(
          alpha = alpha,
          rota = rota,
          delta_val = delta_ref,
          gamma_ref_val_eur = gamma_ref_eur
        )
      }
    )
  ) %>%
  pull(data) %>%
  list_rbind()

write_csv(res_E4, "resultados/tabelas/E4_sensibilidade_regulatoria.csv")

# -----------------------------
# Setup E5 - Sensibilidade operacional
# -----------------------------
res_E5 <- expand_grid(
  alpha = alpha_grid,
  rota = rotas_bio,
  D_mult = op_mult_grid,
  V_mult = op_mult_grid,
  c_mult = op_mult_grid
) %>%
  mutate(
    D_adj = D_base_km * D_mult,
    V_adj = V_base_kmh * V_mult,
    c_adj = c_base_tday * c_mult,
    data = pmap(
      list(alpha, rota, D_adj, V_adj, c_adj),
      \(alpha, rota, D_adj, V_adj, c_adj) {
        calc_cenario(
          alpha = alpha,
          rota = rota,
          D_km = D_adj,
          V_kmh = V_adj,
          c_tday = c_adj
        )
      }
    )
  ) %>%
  mutate(
    data = pmap(
      list(data, D_mult, V_mult, c_mult),
      \(data, D_mult, V_mult, c_mult) {
        bind_cols(tibble(D_mult = D_mult, V_mult = V_mult, c_mult = c_mult), data)
      }
    )
  ) %>%
  pull(data) %>%
  list_rbind()

write_csv(res_E5, "resultados/tabelas/E5_sensibilidade_operacional.csv")

# -----------------------------
# Setup E6 - Caminhos de viabilidade regulatória
# -----------------------------
policy_tbl <- tibble(
  policy_path = c(
    "EU ETS - referencia",
    "EU ETS - teto recente",
    "Carbono reforcado I",
    "Carbono reforcado II",
    "Inducao forte I",
    "Inducao forte II",
    "Inducao forte III",
    "FuelEU implicito - baixo",
    "FuelEU implicito - alto"
  ),
  gamma_ref_signal_eur = c(80, 100, 150, 200, 300, 400, 500, 650, 770),
  gamma_comp_signal_eur = c(80, 100, 150, 200, 300, 400, 500, 650, 770)
)

res_E6 <- expand_grid(
  alpha = alpha_grid,
  rota = rotas_bio,
  policy_path = policy_tbl$policy_path
) %>%
  left_join(policy_tbl, by = "policy_path") %>%
  mutate(
    data = pmap(
      list(alpha, rota, gamma_ref_signal_eur, gamma_comp_signal_eur),
      \(alpha, rota, gamma_ref_signal_eur, gamma_comp_signal_eur) {
        calc_cenario(
          alpha = alpha,
          rota = rota,
          gamma_ref_val_eur = gamma_ref_signal_eur,
          gamma_comp_val_eur = gamma_comp_signal_eur
        )
      }
    )
  ) %>%
  mutate(
    data = pmap(
      list(data, policy_path, gamma_ref_signal_eur, gamma_comp_signal_eur),
      \(data, policy_path, gamma_ref_signal_eur, gamma_comp_signal_eur) {
        bind_cols(
          tibble(
            policy_path = policy_path,
            gamma_ref_signal_eur = gamma_ref_signal_eur,
            gamma_comp_signal_eur = gamma_comp_signal_eur
          ),
          data
        )
      }
    )
  ) %>%
  pull(data) %>%
  list_rbind()

write_csv(res_E6, "resultados/tabelas/E6_caminhos_viabilidade.csv")

# -----------------------------
# Setup E7 - Sensibilidade específica para TCO
# -----------------------------
tco_row <- fuel_tbl %>% filter(rota == "TCO")

res_E7 <- expand_grid(
  alpha = alpha_grid,
  tco_fe_mult = tco_fe_mult_grid,
  tco_price_mult = tco_price_mult_grid
) %>%
  mutate(
    fuel_data_adj = pmap(
      list(tco_fe_mult, tco_price_mult),
      \(tco_fe_mult, tco_price_mult) {
        fuel_tbl %>%
          mutate(
            p_bio = if_else(rota == "TCO", tco_row$p_bio * tco_price_mult, p_bio),
            FE_bio = if_else(rota == "TCO", tco_row$FE_bio * tco_fe_mult, FE_bio)
          )
      }
    ),
    data = pmap(
      list(alpha, fuel_data_adj),
      \(alpha, fuel_data_adj) {
        calc_cenario(
          alpha = alpha,
          rota = "TCO",
          fuel_data = fuel_data_adj
        )
      }
    )
  ) %>%
  mutate(
    data = pmap(
      list(data, tco_fe_mult, tco_price_mult),
      \(data, tco_fe_mult, tco_price_mult) {
        bind_cols(
          tibble(tco_fe_mult = tco_fe_mult, tco_price_mult = tco_price_mult),
          data
        )
      }
    )
  ) %>%
  pull(data) %>%
  list_rbind()

write_csv(res_E7, "resultados/tabelas/E7_sensibilidade_tco.csv")

# ============================================================
# Gráficos principais da dissertação / artigo
# ============================================================

# -----------------------------
# Gráfico 1 - Emissões vs alpha
# -----------------------------
g1 <- ggplot(res_E1, aes(x = alpha, y = G_t, group = rota, linetype = rota)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 2) +
  labs(
    x = expression(alpha),
    y = expression("Emissões totais " * "(" * t * CO[2] * "/" * "viagem" * ")"),
    title = "Emissões totais por fração de mistura",
    linetype = "Rota do biodiesel"
  ) +
  theme_minimal(base_size = 12)

save_plot(g1, "grafico_01_emissoes_vs_alpha.png")

# -----------------------------
# Gráfico 2 - Custo total vs alpha
# -----------------------------
g2 <- ggplot(res_E1, aes(x = alpha, y = C_USD, group = rota, linetype = rota)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 2) +
  labs(
    x = expression(alpha),
    y = "Custo total (USD/viagem)",
    title = "Custo total por fração de mistura",
    linetype = "Rota do biodiesel"
  ) +
  theme_minimal(base_size = 12)

save_plot(g2, "grafico_02_custo_vs_alpha.png")

# -----------------------------
# Gráfico 3 - MAC vs alpha
# -----------------------------
g3 <- ggplot(res_E1, aes(x = alpha, y = MAC_USD_tCO2, group = rota, linetype = rota)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 2) +
  geom_hline(yintercept = gamma_ref, linewidth = 0.8) +
  labs(
    x = expression(alpha),
    y = expression("MAC " * "(" * USD/tCO[2] * ")"),
    title = "Custo marginal de abatimento por fração de mistura",
    linetype = "Rota do biodiesel"
  ) +
  theme_minimal(base_size = 12)

save_plot(g3, "grafico_03_mac_vs_alpha.png")

# -----------------------------
# Gráfico 3B - Break-even carbon price vs alpha
# -----------------------------
policy_lines <- tibble(
  y = c(80, 100, 300, 650, 770),
  label = c(
    "EU ETS ref. 80",
    "EU ETS teto 100",
    "Inducao forte 300",
    "FuelEU impl. 650",
    "FuelEU impl. 770"
  )
)

g3b <- ggplot(res_E1, aes(x = alpha, y = break_even_EUR_tCO2, group = rota, linetype = rota)) +
  geom_hline(data = policy_lines, aes(yintercept = y), linewidth = 0.5, alpha = 0.45) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 2) +
  labs(
    x = expression(alpha),
    y = expression("Break-even carbon price " * "(" * EUR/tCO[2] * ")"),
    title = "Preco de carbono de equilibrio por fracao de mistura",
    linetype = "Rota do biodiesel"
  ) +
  theme_minimal(base_size = 12)

save_plot(g3b, "grafico_03b_break_even_vs_alpha.png")

# -----------------------------
# Gráfico 4 - Trade-off DeltaG vs DeltaC
# -----------------------------
g4 <- ggplot(res_E1, aes(x = Delta_G_t, y = Delta_C_USD, linetype = rota)) +
  geom_point(size = 2) +
  geom_path(linewidth = 0.8) +
  labs(
    x = expression(Delta * "Emissões " * "(" * t * CO[2] * "/" * "viagem" * ")"),
    y = expression(Delta * "Custo " * "(" * USD/viagem * ")"),
    title = "Trade-off entre redução de emissões e custo incremental",
    linetype = "Rota do biodiesel"
  ) +
  theme_minimal(base_size = 12)

save_plot(g4, "grafico_04_tradeoff_deltaG_deltaC.png")

# -----------------------------
# Gráfico 5 - Heatmap de viabilidade
# -----------------------------
heat_E4 <- res_E4 %>%
  filter(delta_ref == delta_ref[1] | delta_ref == 0.15) %>%
  filter(gamma_ref_eur == gamma_ref_eur[1] | gamma_ref_eur == 80) %>%
  mutate(
    rota = factor(rota, levels = c("soja", "sebo bovino", "UCO", "TCO")),
    alpha_f = factor(alpha)
  )

g5 <- ggplot(heat_E4, aes(x = alpha_f, y = rota, fill = factor(V))) +
  geom_tile(color = "white") +
  labs(
    x = expression(alpha),
    y = "Rota do biodiesel",
    fill = "Viável",
    title = "Mapa de viabilidade econômico-ambiental"
  ) +
  theme_minimal(base_size = 12)

save_plot(g5, "grafico_05_heatmap_viabilidade.png")

# -----------------------------
# Gráfico 6 - Decomposição do custo total
# -----------------------------
cost_breakdown <- res_E1 %>%
  select(rota, alpha, C_fuel_USD, C_comp_USD) %>%
  pivot_longer(
    cols = c(C_fuel_USD, C_comp_USD),
    names_to = "componente",
    values_to = "custo_usd"
  ) %>%
  mutate(
    componente = recode(
      componente,
      "C_fuel_USD" = "Combustivel",
      "C_comp_USD" = "Compliance ETS"
    )
  )

g6 <- ggplot(cost_breakdown, aes(x = alpha, y = custo_usd, color = componente, linetype = componente)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 1.8) +
  facet_wrap(~ rota, scales = "free_y") +
  labs(
    x = expression(alpha),
    y = "Custo (USD/viagem)",
    color = "Componente",
    linetype = "Componente",
    title = "Decomposicao do custo entre combustivel e compliance ETS"
  ) +
  theme_minimal(base_size = 12)

save_plot(g6, "grafico_06_decomposicao_custo.png")

# -----------------------------
# Gráfico 7 - Fronteira de viabilidade regulatória
# -----------------------------
frontier_E6 <- res_E6 %>%
  mutate(
    rota = factor(rota, levels = c("soja", "sebo bovino", "UCO", "TCO")),
    alpha_f = factor(alpha),
    policy_f = factor(gamma_ref_signal_eur, levels = sort(unique(gamma_ref_signal_eur)))
  )

g7 <- ggplot(frontier_E6, aes(x = alpha_f, y = policy_f, fill = factor(V))) +
  geom_tile(color = "white") +
  facet_wrap(~ rota) +
  labs(
    x = expression(alpha),
    y = expression("Sinal regulatorio " * "(" * EUR/tCO[2] * ")"),
    fill = "Viavel",
    title = "Fronteira de viabilidade por mistura e sinal regulatorio"
  ) +
  theme_minimal(base_size = 12)

save_plot(g7, "grafico_07_fronteira_viabilidade.png")

# -----------------------------
# Gráfico 8 - Heatmap de break-even
# -----------------------------
heat_break_even <- res_E1 %>%
  mutate(
    rota = factor(rota, levels = c("soja", "sebo bovino", "UCO", "TCO")),
    alpha_f = factor(alpha)
  )

g8 <- ggplot(heat_break_even, aes(x = alpha_f, y = rota, fill = break_even_EUR_tCO2)) +
  geom_tile(color = "white") +
  labs(
    x = expression(alpha),
    y = "Rota do biodiesel",
    fill = expression("Break-even" ~ "(" * EUR/tCO[2] * ")"),
    title = "Preco de carbono de equilibrio por rota e fracao de mistura"
  ) +
  theme_minimal(base_size = 12)

save_plot(g8, "grafico_08_heatmap_break_even.png")

# ============================================================
# Tabelas-resumo
# ============================================================

# Resumo E1
resumo_E1 <- res_E1 %>%
  group_by(rota) %>%
  summarise(
    G_min_t = min(G_t, na.rm = TRUE),
    G_max_t = max(G_t, na.rm = TRUE),
    C_min_USD = min(C_USD, na.rm = TRUE),
    C_max_USD = max(C_USD, na.rm = TRUE),
    MAC_min = min(MAC_USD_tCO2, na.rm = TRUE),
    MAC_max = max(MAC_USD_tCO2, na.rm = TRUE),
    n_viaveis = sum(V, na.rm = TRUE),
    .groups = "drop"
  )

write_csv(resumo_E1, "resultados/tabelas/resumo_E1.csv")

resumo_break_even <- res_E1 %>%
  group_by(rota) %>%
  slice_min(order_by = break_even_EUR_tCO2, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  transmute(
    rota,
    alpha_break_even_min = alpha,
    break_even_min_eur_tco2 = break_even_EUR_tCO2,
    reducao_emissoes_pct = 100 * Delta_G_t / G0_t,
    custo_total_usd = C_USD
  )

write_csv(resumo_break_even, "resultados/tabelas/resumo_break_even.csv")

resumo_E7_tco <- res_E7 %>%
  group_by(tco_fe_mult, tco_price_mult) %>%
  summarise(
    break_even_min_eur_tco2 = min(break_even_EUR_tCO2, na.rm = TRUE),
    alpha_break_even_min = alpha[which.min(break_even_EUR_tCO2)],
    n_viaveis = sum(V, na.rm = TRUE),
    .groups = "drop"
  )

write_csv(resumo_E7_tco, "resultados/tabelas/resumo_E7_tco.csv")

# Tabela específica alpha = 0.24
tab_B24 <- res_E1 %>%
  filter(abs(alpha - 0.24) < 1e-9) %>%
  select(
    rota, alpha, E_util_GJ, C_USD, G_t, Delta_G_t, Delta_C_USD, MAC_USD_tCO2, V
  )

write_csv(tab_B24, "resultados/tabelas/tabela_B24.csv")

# Reprodução do exemplo numérico da Seção III.9 segundo o modelo executado
calc_exemplo_capitulo3 <- function() {
  base_row <- calc_cenario(alpha = 0, rota = "sebo bovino") %>%
    slice(1)

  mix_rows <- res_E1 %>%
    filter(abs(alpha - 0.24) < 1e-9) %>%
    transmute(
      cenario = recode(
        rota,
        "soja" = "B24 Soja",
        "sebo bovino" = "B24 Sebo",
        "UCO" = "B24 UCO",
        "TCO" = "B24 TCO"
      ),
      massa_total_kg = F_kg,
      massa_bunker_kg = m_b_kg,
      massa_biodiesel_kg = m_bio_kg,
      energia_GJ = E_util_GJ,
      custo_USD = C_USD,
      CO2_t = G_t,
      reducao_pct = 100 * Delta_G_t / G0_t,
      MAC_USD_tCO2 = MAC_USD_tCO2
    )

  bind_rows(
    tibble(
      cenario = "bunker fuel",
      massa_total_kg = base_row$F_kg,
      massa_bunker_kg = base_row$F_kg,
      massa_biodiesel_kg = 0,
      energia_GJ = base_row$E_util_GJ,
      custo_USD = base_row$C_USD,
      CO2_t = base_row$G_t,
      reducao_pct = 0,
      MAC_USD_tCO2 = NA_real_
    ),
    mix_rows
  ) %>%
    mutate(
      cenario = factor(
        cenario,
        levels = c("bunker fuel", "B24 Sebo", "B24 UCO", "B24 TCO", "B24 Soja")
      )
    ) %>%
    arrange(cenario) %>%
    mutate(
      massa_total_kg = round(massa_total_kg, 0),
      massa_bunker_kg = round(massa_bunker_kg, 0),
      massa_biodiesel_kg = round(massa_biodiesel_kg, 0),
      energia_GJ = round(energia_GJ, 3),
      custo_USD = round(custo_USD, 0),
      CO2_t = round(CO2_t, 3),
      reducao_pct = round(reducao_pct, 3),
      MAC_USD_tCO2 = round(MAC_USD_tCO2, 3)
    )
}

tab_capitulo3_B24 <- calc_exemplo_capitulo3()

write_csv(tab_capitulo3_B24, "resultados/tabelas/tabela_capitulo3_B24.csv")

# ============================================================
# Mensagem final
# ============================================================
cat("\nPlanejamento experimental executado com sucesso.\n")
cat("Arquivos salvos em:\n")
cat("- resultados/tabelas/\n")
cat("- resultados/graficos/\n\n")
