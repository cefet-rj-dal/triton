# ============================================================
# Planejamento experimental do modelo de biobunker
# Base computacional usada para os resultados do artigo
# "Biobunker como Combustível de Transição no Transporte Marítimo:
# Uma Avaliação por Simulação da Viabilidade Econômico-Ambiental
# na Rota Santos--Roterdã"
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
  library(readxl)
  library(stringr)
  library(forcats)
})

# -----------------------------
# Diretórios de saída
# -----------------------------
dir.create("resultados", showWarnings = FALSE)
dir.create("resultados/tabelas", recursive = TRUE, showWarnings = FALSE)
dir.create("resultados/graficos", recursive = TRUE, showWarnings = FALSE)
dir.create("legado", showWarnings = FALSE)
dir.create("legado/resultados", recursive = TRUE, showWarnings = FALSE)
dir.create("legado/resultados/tabelas", recursive = TRUE, showWarnings = FALSE)
dir.create("legado/resultados/graficos", recursive = TRUE, showWarnings = FALSE)

# -----------------------------
# Dados oficiais de apoio
# -----------------------------

anp_preco_b100_path <- "dados/anp/anp-precos-medios-ponderados-semanais-2013-em-diante.xls"
anp_materia_prima_path <- "dados/anp/anp-biodiesel-materia-prima.csv"

# Fontes:
# - Precos B100:
#   https://www.gov.br/anp/pt-br/assuntos/precos-e-defesa-da-concorrencia/precos/precos-de-produtores-e-importadores-de-derivados-de-petroleo-e-biodiesel
# - Materia-prima/producao:
#   https://www.gov.br/anp/pt-br/centrais-de-conteudo/paineis-dinamicos-da-anp/paineis-e-mapa-dinamicos-de-produtores-de-combustiveis-e-derivados/painel-dinamico-de-produtores-de-biodiesel

# -----------------------------
# Parâmetros globais
# -----------------------------

# Rota-base: Santos -> Roterdã
# Fontes conforme o artigo:
# - Distância = 10.120 km: SeaRoutes (rota Santos--Roterdã), citado como searoutes2026.
# - Velocidade média = 25,93 km/h (14 nós): Brown et al. (2019), citado como brown_power_2019.
# - Consumo agregado = 40 t/dia: ordem de grandeza coerente com relatórios operacionais
#   para graneleiros, citado no artigo como marineaffairs2025.
D_base_km   <- 10120      # km
V_base_kmh  <- 25.93      # km/h
c_base_tday <- 40         # t/dia

# Conversões operacionais
c_base_th <- c_base_tday / 24  # t/h

# Misturas avaliadas
# Grade usada no artigo. Inclui B24 (alpha = 0.24), mantido como ponto
# intermediário de leitura e para inspeção da região em que a classificação
# passa a mudar nos experimentos regulatórios ampliados.
alpha_grid <- c(0.10, 0.15, 0.20, 0.24, 0.25, 0.30)

# Rotas de produção do biodiesel
# Neste trabalho, TCO = Technical Corn Oil (óleo técnico de milho).
# A sigla não se refere a Tall Oil Crude.
rotas_bio <- c("soja", "sebo bovino", "UCO", "TCO")

# Critérios de viabilidade
# Artigo:
# - delta_ref = 0,15 como limiar ambiental de referência.
# - gamma_ref_eur = 80 EUR/tCO2 como referência de mercado/regulatória.
# - gamma_comp_eur = 0 nos experimentos E1--E5, para que o cenário-base
#   represente a avaliação antes da internalização explícita de compliance.
delta_ref <- 0.15           # referência para critério ambiental
gamma_ref_eur <- 80         # EUR/tCO2, referência de mercado/regulatória

# Faixas para sensibilidade
# Artigo:
# - E4: delta de 0,10 a 0,25 com passo 0,01
# - E4: gamma_ref de 60 a 120 EUR/tCO2 com passo 10
delta_grid <- seq(0.10, 0.25, by = 0.01)
gamma_grid_eur <- seq(60, 120, by = 10)

# Câmbio de referência para comparar MAC (USD/tCO2) com gamma de referência (EUR/tCO2).
# Fonte: ECB euro foreign exchange reference rates, USD = 1.1581 em 11/03/2026.
# https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/index.en.html
eur_to_usd_ref <- 1.1581
gamma_ref <- gamma_ref_eur * eur_to_usd_ref
gamma_grid <- gamma_grid_eur * eur_to_usd_ref

# Recorte empirico do E7: marco de 2026
e7_mes_anp <- "03/2026"
e7_mes_inicio <- as.Date("2026-03-01")
e7_mes_fim <- as.Date("2026-03-31")
rho_bio_kg_l <- 0.88
usd_brl_mar2026 <- 5.2296

# Componente gamma^comp associado ao custo explícito de compliance do EU ETS
# na rota Santos -> Roterdã, em modelagem simplificada.
# Fontes e convenções do artigo:
# - preco de referência do EU ETS: 80 EUR/tCO2 no cenário-base, com apoio em
#   euets2023 / World Bank (2024) para a ordem de grandeza recente.
# - cobertura regulatória de 50% para viagens extra-UE -> UE.
# - phase-in = 100% para emissões de 2026 em diante.
# - biomassa sustentável elegível: fator zero para surrender no EU ETS.
gamma_comp_eur_ref <- 0
gamma_comp_usd_ref <- gamma_comp_eur_ref * eur_to_usd_ref
ets_coverage_ref <- 0.50
ets_phase_in_ref <- 1.00

# Sensibilidade econômica
pb_mult_grid    <- seq(0.75, 1.25, by = 0.05)
pbio_mult_grid  <- seq(0.75, 1.25, by = 0.05)

# Sensibilidade ambiental
fe_mult_grid <- seq(0.75, 1.25, by = 0.05)

# Sensibilidade operacional
op_mult_grid <- seq(0.85, 1.15, by = 0.05)

# -----------------------------
# Propriedades dos combustíveis
# -----------------------------

# Bunker fuel
# Fontes conforme o artigo:
# - PCI_b = 40,2 MJ/kg: IPCC (2006), categoria Residual Fuel Oil.
# - FE_b = 3,114 kgCO2/kg: IPCC (2006), categoria Residual Fuel Oil.
# - p_b = 0,50 USD/kg: ordem de grandeza adotada no artigo a partir de avaliações
#   tecnoeconômicas recentes sobre combustíveis marítimos renováveis.
# - eta_b = 0,45: valor médio representativo de modelagem comparativa.
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
# - Balaji et al. (2019), Data in Brief 27:104683,
#   doi:10.1016/j.dib.2019.104683, PMCID: PMC6838419.
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
  # p_bio = 1,60 USD/kg: ordem de grandeza-base usada no artigo, em linha com
  # comparações tecnoeconômicas recentes.
  p_bio   = c(1.60, 1.60, 1.60, 1.60),          # USD/kg
  # PCI_bio = 37,68 MJ/kg para soja / sebo / UCO: coerente com RenovaCalc.
  # PCI_bio = 36,64 MJ/kg para TCO: Balaji et al. (2019).
  # FE_bio = 1,32 / 0,64 / 0,56 kgCO2/kg para soja / sebo / UCO:
  #   referenciais do RenovaBio e sistematização metodológica recente
  #   (anp_renovacalc; pereira_renovacalc_2025).
  # FE_bio = 0,513 kgCO2/kg para TCO: convertido de Wang et al. (2015).
  FE_bio  = c(1.32, 0.64, 0.56, 0.513)          # kgCO2/kg: soja, sebo bovino, UCO, TCO
)

# Blends estaduais do experimento E7
# O E7 nao substitui a analise por rotas tecnologicas de E1--E6.
# Ele testa a mesma estrutura analitica do artigo em composicoes agregadas
# de oferta observada no Brasil, representadas pelos cinco maiores estados
# produtores de biodiesel no recorte ANP de marco de 2026.
#
# Convencoes:
# - O perfil operacional e regulatorio permanece o mesmo do artigo.
# - Os parametros abaixo representam blends estaduais agregados, e nao
#   rotas puras isoladas.
# - PCI_bio e eta_bio permanecem alinhados ao biodiesel FAME convencional,
#   preservando comparabilidade com a base do artigo.
# - p_bio e calculado a partir das medias regionais da ANP para B100 em
#   marco de 2026, convertidas de R$/L para USD/kg com rho_bio = 0,88 kg/L
#   e cambio medio mensal USD/BRL = 5,2296.
# - FE_bio representa o fator WTW agregado do blend estadual, obtido no
#   estudo auxiliar por media ponderada das materias-primas predominantes.
anp_preco_b100_raw <- read_excel(anp_preco_b100_path, skip = 9, col_names = FALSE)
names(anp_preco_b100_raw) <- c(
  "produto", "inicio", "fim", "Norte", "Nordeste", "Centro_Oeste",
  "Sul", "Sudeste", "Brasil", "extra"
)

to_num <- function(x) {
  suppressWarnings(as.numeric(str_replace(as.character(x), ",", ".")))
}

anp_preco_b100_mar2026 <- anp_preco_b100_raw %>%
  filter(
    str_detect(str_to_lower(produto), "biodiesel"),
    as.Date(inicio) >= e7_mes_inicio,
    as.Date(inicio) <= e7_mes_fim
  ) %>%
  mutate(across(c(Norte, Nordeste, Centro_Oeste, Sul, Sudeste, Brasil), to_num))

e7_precos_regionais_b100 <- anp_preco_b100_mar2026 %>%
  summarise(
    Norte = mean(Norte, na.rm = TRUE),
    Nordeste = mean(Nordeste, na.rm = TRUE),
    Centro_Oeste = mean(Centro_Oeste, na.rm = TRUE),
    Sul = mean(Sul, na.rm = TRUE),
    Sudeste = mean(Sudeste, na.rm = TRUE),
    Brasil = mean(Brasil, na.rm = TRUE)
  ) %>%
  pivot_longer(everything(), names_to = "regiao_preco", values_to = "preco_brl_l") %>%
  mutate(
    rho_bio_kg_l = rho_bio_kg_l,
    usd_brl = usd_brl_mar2026,
    preco_usd_kg = preco_brl_l / rho_bio_kg_l / usd_brl
  )

anp_materia_prima_mar2026 <- read_csv(
  anp_materia_prima_path,
  locale = locale(decimal_mark = ",", grouping_mark = "."),
  show_col_types = FALSE
) %>%
  rename(
    mes = 1,
    regiao = 2,
    estado = 3,
    materia_prima = 4,
    quantidade_m3 = 5
  ) %>%
  filter(mes == e7_mes_anp)

e7_top_estados_anp <- anp_materia_prima_mar2026 %>%
  group_by(estado) %>%
  summarise(producao_m3 = sum(quantidade_m3, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(producao_m3)) %>%
  slice_head(n = 5)

e7_materias_primas_estaduais <- anp_materia_prima_mar2026 %>%
  semi_join(e7_top_estados_anp, by = "estado") %>%
  group_by(estado) %>%
  mutate(
    producao_estado_m3 = sum(quantidade_m3, na.rm = TRUE),
    participacao = quantidade_m3 / producao_estado_m3
  ) %>%
  ungroup() %>%
  arrange(estado, desc(quantidade_m3))

fuel_tbl_estados_base <- tibble(
  rota = c("Bahia", paste0("Goi", "\u00e1", "s"), "Mato Grosso", paste0("Paran", "\u00e1"), "Rio Grande do Sul"),
  regiao_preco = c("Nordeste", "Centro_Oeste", "Centro_Oeste", "Sul", "Sul"),
  PCI_bio = c(37.68, 37.68, 37.68, 37.68, 37.68),
  eta_bio = c(0.43, 0.43, 0.43, 0.43, 0.43),
  FE_bio = c(1.14, 1.21, 1.18, 1.17, 1.24)
)

fuel_tbl_estados <- fuel_tbl_estados_base %>%
  left_join(e7_precos_regionais_b100, by = "regiao_preco") %>%
  transmute(
    rota,
    PCI_bio,
    eta_bio,
    p_bio = preco_usd_kg,
    FE_bio,
    regiao_preco,
    preco_brl_l,
    rho_bio_kg_l,
    usd_brl
  )

rotas_bio_estados <- fuel_tbl_estados$rota

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
  eta_mix <- eta_mix_ideal
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

save_plot <- function(plot_obj, filename, width = 9, height = 6, dpi = 300,
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

pathway_labels <- c(
  "soja" = "Soybean",
  "sebo bovino" = "Beef tallow",
  "UCO" = "UCO",
  "TCO" = "TCO"
)

pathway_levels <- unname(pathway_labels[c("soja", "sebo bovino", "UCO", "TCO")])
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

format_decimal_en <- function(x, digits = 1) {
  format(round(x, digits), decimal.mark = ".", big.mark = ",", nsmall = digits)
}

format_usd_k <- function(x) {
  paste0("$", trimws(format(round(x / 1000, 0), big.mark = ",")), "k")
}

# -----------------------------
# Experimento E1 - Cenário-base
# Corresponde à resposta-base da avaliação experimental do artigo.
# -----------------------------
res_E1 <- expand_grid(
  alpha = alpha_grid,
  rota = rotas_bio
) %>%
  pmap_dfr(\(alpha, rota) calc_cenario(alpha = alpha, rota = rota))

write_csv(res_E1, "resultados/tabelas/E1_cenario_base.csv")

# -----------------------------
# Experimento E2 - Sensibilidade econômica
# Artigo: multiplicadores {0,80; 1,00; 1,20} para preços do combustível
# fóssil e do biodiesel.
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
# Experimento E3 - Sensibilidade ambiental
# Artigo: multiplicadores {0,90; 1,00; 1,10} para fatores de emissão WTW.
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
# Experimento E4 - Sensibilidade regulatória
# Artigo: combinacoes de delta e gamma_ref no dominio regulatório de referência.
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
# Experimento E5 - Sensibilidade operacional
# Artigo: multiplicadores {0,90; 1,00; 1,10} para distância, velocidade e consumo.
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
# Experimento E6 - Caminhos de viabilidade regulatória
# Artigo: trajetórias regulatórias que mantêm a referência de carbono no valor
# de E1--E5 e variam apenas o custo explícito de compliance.
# -----------------------------
policy_tbl <- tibble(
  policy_path = sprintf("gamma_comp_%03d", seq(0, 700, by = 10)),
  gamma_ref_signal_eur = rep(gamma_ref_eur, length(seq(0, 700, by = 10))),
  gamma_comp_signal_eur = seq(0, 700, by = 10)
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

# Leitura complementar de E6: efeito da referência de carbono sobre o menor
# custo explícito de compliance necessário para alcançar viabilidade.
gamma_ref_comp_grid_eur <- seq(80, 350, by = 10)
gamma_comp_comp_grid_eur <- seq(80, 700, by = 10)

res_E6_interacao_ref_comp <- expand_grid(
  alpha = alpha_grid,
  rota = rotas_bio,
  gamma_ref_signal_eur = gamma_ref_comp_grid_eur,
  gamma_comp_signal_eur = gamma_comp_comp_grid_eur
) %>%
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
      list(data, gamma_ref_signal_eur, gamma_comp_signal_eur),
      \(data, gamma_ref_signal_eur, gamma_comp_signal_eur) {
        bind_cols(
          tibble(
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

write_csv(
  res_E6_interacao_ref_comp,
  "resultados/tabelas/E6_interacao_gamma_ref_gamma_comp.csv"
)

gamma_comp_min_por_ref <- res_E6_interacao_ref_comp %>%
  filter(V == 1) %>%
  group_by(gamma_ref_signal_eur) %>%
  arrange(gamma_comp_signal_eur, alpha, .by_group = TRUE) %>%
  slice(1) %>%
  ungroup() %>%
  select(gamma_ref_signal_eur, gamma_comp_signal_eur)

resumo_E6_interacao_mac <- expand_grid(
  rota = rotas_bio,
  gamma_ref_signal_eur = gamma_ref_comp_grid_eur
) %>%
  left_join(gamma_comp_min_por_ref, by = "gamma_ref_signal_eur") %>%
  left_join(
    res_E6_interacao_ref_comp %>%
      filter(abs(alpha - 0.24) < 1e-9) %>%
      select(
        rota,
        gamma_ref_signal_eur,
        gamma_comp_signal_eur,
        mac_eur_tco2 = break_even_EUR_tCO2,
        V
      ),
    by = c("rota", "gamma_ref_signal_eur", "gamma_comp_signal_eur")
  )

linha_gamma_comp <- gamma_comp_min_por_ref %>%
  transmute(
    item = "gamma_comp",
    gamma_ref_signal_eur,
    valor = gamma_comp_signal_eur
  )

linhas_mac <- resumo_E6_interacao_mac %>%
  transmute(
    item = rota,
    gamma_ref_signal_eur,
    valor = mac_eur_tco2
  )

resumo_E6_interacao_ref_comp <- bind_rows(
  linha_gamma_comp,
  linhas_mac
) %>%
  mutate(
    item = factor(
      item,
      levels = c("gamma_comp", "UCO", "TCO", "sebo bovino", "soja")
    )
  ) %>%
  arrange(item, gamma_ref_signal_eur) %>%
  mutate(
    gamma_ref_signal_eur = paste0("gamma_ref_", gamma_ref_signal_eur)
  ) %>%
  pivot_wider(names_from = gamma_ref_signal_eur, values_from = valor)

write_csv(
  resumo_E6_interacao_ref_comp,
  "resultados/tabelas/resumo_E6_interacao_gamma_ref_gamma_comp.csv"
)

# -----------------------------
# Experimento E7 - Blends estaduais observados
# Verifica se a fronteira de viabilidade obtida para rotas tecnologicas
# permanece consistente quando o biodiesel e representado por composicoes
# agregadas dos principais estados produtores brasileiros.
# -----------------------------
res_E7 <- expand_grid(
  alpha = alpha_grid,
  rota = rotas_bio_estados
) %>%
  pmap_dfr(\(alpha, rota) {
    calc_cenario(
      alpha = alpha,
      rota = rota,
      fuel_data = fuel_tbl_estados
    )
  })

write_csv(res_E7, "resultados/tabelas/E7_blends_estaduais_base.csv")

res_E7_reg <- expand_grid(
  alpha = alpha_grid,
  rota = rotas_bio_estados,
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
          gamma_comp_val_eur = gamma_comp_signal_eur,
          fuel_data = fuel_tbl_estados
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

write_csv(res_E7_reg, "resultados/tabelas/E7_blends_estaduais_regulatorio.csv")
write_csv(fuel_tbl_estados, "resultados/tabelas/E7_parametros_estaduais.csv")
write_csv(e7_precos_regionais_b100, "resultados/tabelas/E7_precos_regionais_b100_anp_mar2026.csv")
write_csv(e7_top_estados_anp, "resultados/tabelas/E7_top_estados_anp_mar2026.csv")
write_csv(e7_materias_primas_estaduais, "resultados/tabelas/E7_materias_primas_estaduais_anp_mar2026.csv")

# ============================================================
# Gráficos principais
# Mapeamento com o artigo:
# - grafico_01_emissoes_vs_alpha.png -> Figura de emissões da Seção 4
# - grafico_03b_break_even_vs_alpha.png -> Figura de break-even da Seção 4
# - grafico_04_tradeoff_deltaG_deltaC.png -> Figura de trade-off da Seção 4
# - grafico_06_decomposicao_custo.png -> Figura de decomposição de custo da Seção 4
# - grafico_07_fronteira_viabilidade.png -> Figura de fronteira de viabilidade da Seção 4
# Gráficos 02, 03, 05 e 08 permanecem como apoio analítico e não aparecem
# na versão atual do artigo.
# - grafico_09_break_even_estados.png -> Figura adicional do E7
# - grafico_10_fronteira_viabilidade_estados.png -> Figura adicional do E7
# ============================================================

# -----------------------------
# Gráfico 1 - Emissões vs alpha
# -----------------------------
g1_data <- res_E1 %>%
  mutate(
    pathway = factor(recode(rota, !!!pathway_labels), levels = pathway_levels)
  )

g1 <- ggplot(g1_data, aes(x = alpha, y = G_t, group = pathway, linetype = pathway)) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.8) +
  labs(
    x = expression(alpha),
    y = "Total emissions (tCO2/voyage)",
    linetype = "Biodiesel pathway"
  ) +
  theme_triton()

save_plot(g1, "grafico_01_emissoes_vs_alpha.png", width = 10, height = 6.5)

# -----------------------------
# Gráfico 2 - Custo total vs alpha
# -----------------------------
g2 <- ggplot(g1_data, aes(x = alpha, y = C_USD, group = pathway, linetype = pathway)) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.8) +
  labs(
    x = expression(alpha),
    y = "Total cost (USD/voyage)",
    linetype = "Biodiesel pathway"
  ) +
  theme_triton()

save_plot(g2, "grafico_02_custo_vs_alpha.png",
          width = 10, height = 6.5,
          base_dir = file.path("legado", "resultados", "graficos"))

# -----------------------------
# Gráfico 3 - MAC vs alpha
# -----------------------------
g3 <- ggplot(g1_data, aes(x = alpha, y = MAC_USD_tCO2, group = pathway, linetype = pathway)) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.8) +
  geom_hline(yintercept = gamma_ref, linewidth = 0.8) +
  labs(
    x = expression(alpha),
    y = expression("MAC " * "(" * USD/tCO[2] * ")"),
    linetype = "Biodiesel pathway"
  ) +
  theme_triton()

save_plot(g3, "grafico_03_mac_vs_alpha.png",
          width = 10, height = 6.5,
          base_dir = file.path("legado", "resultados", "graficos"))

# -----------------------------
# Gráfico 3B - Break-even carbon price vs alpha
# -----------------------------
policy_lines <- tibble(
  y = c(80, 150, 200, 300, 400),
  label = c(
    "gamma_ref 80",
    "gamma_ref 150",
    "gamma_ref 200",
    "gamma_ref 300",
    "gamma_ref 400"
  )
)

break_even_E1_rota <- res_E1 %>%
  group_by(rota) %>%
  summarise(
    break_even_EUR_tCO2 = first(break_even_EUR_tCO2),
    .groups = "drop"
  ) %>%
  mutate(
    pathway = factor(recode(rota, !!!pathway_labels), levels = pathway_levels)
  )

g3b <- ggplot(
  break_even_E1_rota,
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

save_plot(g3b, "grafico_03b_break_even_vs_alpha.png", width = 10, height = 6.5)

# -----------------------------
# Gráfico 4 - Trade-off DeltaG vs DeltaC
# -----------------------------
g4 <- ggplot(g1_data, aes(x = Delta_G_t, y = Delta_C_USD, linetype = pathway)) +
  geom_point(size = 2.8) +
  geom_path(linewidth = 1.0) +
  labs(
    x = "Emission reduction (tCO2/voyage)",
    y = "Incremental cost (USD/voyage)",
    linetype = "Biodiesel pathway"
  ) +
  theme_triton()

save_plot(g4, "grafico_04_tradeoff_deltaG_deltaC.png", width = 10, height = 6.5)

# -----------------------------
# Gráfico 5 - Heatmap de viabilidade
# -----------------------------
heat_E4 <- res_E4 %>%
  filter(delta_ref == delta_ref[1] | delta_ref == 0.15) %>%
  filter(gamma_ref_eur == gamma_ref_eur[1] | gamma_ref_eur == 80) %>%
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
          width = 10, height = 6.5,
          base_dir = file.path("legado", "resultados", "graficos"))

# -----------------------------
# Gráfico 6 - Decomposição do custo total no B24
# -----------------------------
cost_compare <- res_E6 %>%
  filter(gamma_comp_signal_eur == 650, abs(alpha - 0.24) < 1e-9) %>%
  mutate(
    pathway = factor(recode(rota, !!!pathway_labels), levels = pathway_levels)
  )

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
  mutate(
    component = factor(component, levels = c("Fuel cost", "Compliance cost"))
  )

total_labels_g6 <- cost_compare_plot %>%
  group_by(scenario) %>%
  summarise(custo_total = sum(custo_usd), .groups = "drop") %>%
  mutate(
    label = format_usd_k(custo_total)
  )

g6 <- ggplot(cost_compare_plot, aes(x = scenario, y = custo_usd, fill = component)) +
  geom_col(width = 0.68) +
  geom_text(
    data = total_labels_g6,
    aes(x = scenario, y = custo_total, label = label),
    inherit.aes = FALSE,
    vjust = -0.35,
    size = 5.0
  ) +
  scale_fill_manual(
    values = c(
      "Fuel cost" = "grey45",
      "Compliance cost" = "#2C7FB8"
    )
  ) +
  scale_y_continuous(labels = format_usd_k) +
  labs(
    x = NULL,
    y = "Total cost (USD/voyage)",
    fill = "Cost component"
  ) +
  coord_cartesian(ylim = c(0, max(total_labels_g6$custo_total) * 1.08)) +
  theme_triton() +
  theme(
    axis.text.x = element_text(angle = 15, hjust = 1)
  )

save_plot(g6, "grafico_06_decomposicao_custo.png", width = 10.5, height = 6.5)

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
  mutate(
    cenario = factor(cenario, levels = c("Biobunker", "Bunker fuel with compliance"))
  )

g6_legacy <- ggplot(cost_compare_legacy, aes(x = alpha, y = custo_usd, color = cenario, linetype = cenario)) +
  geom_line(linewidth = 1.0) +
  geom_point(size = 2.8) +
  facet_wrap(~ pathway, scales = "free_y") +
  scale_color_manual(
    values = c(
      "Biobunker" = "#C43C39",
      "Bunker fuel with compliance" = "#2C7FB8"
    )
  ) +
  scale_linetype_manual(
    values = c(
      "Biobunker" = "solid",
      "Bunker fuel with compliance" = "solid"
    )
  ) +
  labs(
    x = expression(alpha),
    y = "Total cost (USD/voyage)",
    color = "Scenario",
    linetype = "Scenario"
  ) +
  theme_triton()

save_plot(g6_legacy, "grafico_06_comparacao_custo_total_legacy.png",
          width = 10.5, height = 6.5,
          base_dir = file.path("legado", "resultados", "graficos"))

# -----------------------------
# Gráfico 7 - Fronteira de viabilidade regulatória
# -----------------------------
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
  scale_fill_manual(
    values = c(
      "Non-viable" = "#F8766D",
      "Economic criterion only" = "#F2C94C",
      "Viable" = "#00BFC4"
    )
  ) +
  labs(
    x = expression(alpha),
    y = expression("Compliance " * gamma^{comp} * " (" * EUR/tCO[2] * ")"),
    fill = "Classification"
  ) +
  theme_triton()

save_plot(g7, "grafico_07_fronteira_viabilidade.png", width = 10.5, height = 7)

# -----------------------------
# Gráfico 8 - Heatmap de break-even
# -----------------------------
heat_break_even <- res_E1 %>%
  mutate(
    pathway = factor(recode(rota, !!!pathway_labels), levels = pathway_levels),
    alpha_f = factor(alpha)
  )

g8 <- ggplot(heat_break_even, aes(x = alpha_f, y = pathway, fill = break_even_EUR_tCO2)) +
  geom_tile(color = "white") +
  labs(
    x = expression(alpha),
    y = "Biodiesel pathway",
    fill = expression("Break-even" ~ "(" * EUR/tCO[2] * ")")
  ) +
  theme_triton()

save_plot(g8, "grafico_08_heatmap_break_even.png",
          width = 10, height = 6.5,
          base_dir = file.path("legado", "resultados", "graficos"))

# -----------------------------
# Gráfico 9 - Break-even por blend estadual
# -----------------------------
cores_estados <- c(
  "Bahia" = "#1f77b4",
  "Goias" = "#d62728",
  "Mato Grosso" = "#2ca02c",
  "Parana" = "#ff7f0e",
  "Rio Grande do Sul" = "#9467bd"
)

g9_data <- res_E7 %>%
  mutate(
    state = factor(label_state(rota), levels = state_levels)
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
    y = expression("Break-even carbon price " * "(" * EUR/tCO[2] * ")"),
    color = "State blend",
    linetype = "State blend"
  ) +
  theme_triton()

save_plot(g9, "grafico_09_break_even_estados.png", width = 10.5, height = 6.5)

# -----------------------------
# Gráfico 10 - Fronteira regulatória dos blends estaduais
# -----------------------------
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

resumo_sensibilidade_E2_E5 <- bind_rows(
  res_E2 %>% mutate(experimento = "E2"),
  res_E3 %>% mutate(experimento = "E3"),
  res_E4 %>% mutate(experimento = "E4"),
  res_E5 %>% mutate(experimento = "E5")
) %>%
  group_by(experimento, rota) %>%
  summarise(
    cenarios_avaliados = n(),
    break_even_min_eur_tco2 = min(break_even_EUR_tCO2, na.rm = TRUE),
    break_even_max_eur_tco2 = max(break_even_EUR_tCO2, na.rm = TRUE),
    break_even_media_eur_tco2 = mean(break_even_EUR_tCO2, na.rm = TRUE),
    break_even_dp_eur_tco2 = sd(break_even_EUR_tCO2, na.rm = TRUE),
    cenarios_viaveis = sum(V, na.rm = TRUE),
    .groups = "drop"
  )

write_csv(resumo_sensibilidade_E2_E5, "resultados/tabelas/resumo_sensibilidade_E2_E5.csv")

resumo_E7 <- res_E7 %>%
  group_by(rota) %>%
  summarise(
    break_even_min_eur_tco2 = min(break_even_EUR_tCO2, na.rm = TRUE),
    alpha_break_even_min = alpha[which.min(break_even_EUR_tCO2)],
    n_viaveis = sum(V, na.rm = TRUE),
    .groups = "drop"
  )

write_csv(resumo_E7, "resultados/tabelas/resumo_E7_estados.csv")

primeiros_viaveis_E7 <- res_E7_reg %>%
  filter(V == 1) %>%
  group_by(rota) %>%
  arrange(gamma_comp_signal_eur, alpha, .by_group = TRUE) %>%
  slice(1) %>%
  ungroup() %>%
  select(
    rota,
    alpha,
    gamma_ref_signal_eur,
    gamma_comp_signal_eur,
    break_even_EUR_tCO2,
    Delta_G_t
  )

write_csv(primeiros_viaveis_E7, "resultados/tabelas/E7_primeiros_viaveis.csv")

# Tabela específica alpha = 0.24
tab_B24 <- res_E1 %>%
  filter(abs(alpha - 0.24) < 1e-9) %>%
  select(
    rota, alpha, E_util_GJ, C_USD, G_t, Delta_G_t, Delta_C_USD, MAC_USD_tCO2, V
  )

write_csv(tab_B24, "legado/resultados/tabelas/tabela_B24.csv")

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

write_csv(tab_capitulo3_B24, "legado/resultados/tabelas/tabela_capitulo3_B24.csv")

# ============================================================
# Mensagem final
# ============================================================
cat("\nPlanejamento experimental executado com sucesso.\n")
cat("Arquivos salvos em:\n")
cat("- resultados/tabelas/\n")
cat("- resultados/graficos/\n\n")
