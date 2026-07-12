# MSc-Bel

Base computacional dos experimentos do artigo sobre viabilidade econômico-ambiental do biobunker na rota Santos--Roterdã.

## Estrutura

- `simulacao.R`
  Script principal do modelo e dos experimentos.

- `resultados/`
  Saídas usadas na versão atual do artigo.

- `resultados/graficos/`
  Gráficos que aparecem no artigo:
  - `grafico_01_emissoes_vs_alpha.png`
  - `grafico_03b_break_even_vs_alpha.png`
  - `grafico_04_tradeoff_deltaG_deltaC.png`
  - `grafico_06_decomposicao_custo.png`
  - `grafico_07_fronteira_viabilidade.png`
  - `grafico_09_break_even_estados.png`
  - `grafico_10_fronteira_viabilidade_estados.png`

- `resultados/tabelas/`
  Tabelas e bases intermediárias associadas aos experimentos E1--E7 do artigo, incluindo:
  - `E7_blends_estaduais_base.csv`
  - `E7_blends_estaduais_regulatorio.csv`
  - `E7_parametros_estaduais.csv`
  - `E7_primeiros_viaveis.csv`
  - `resumo_E7_estados.csv`

- `legado/`
  Materiais que não entram na versão atual do artigo, mas foram mantidos para rastreabilidade.

- `legado/resultados/`
  Gráficos e tabelas legados, incluindo:
  - gráficos analíticos não usados no artigo;
  - tabelas auxiliares de B24 herdadas da dissertação.

- `legado/apresentacao/`
  Arquivos de apresentação.

- `legado/references/`
  PDFs e materiais bibliográficos de apoio.

## Execução

Para regenerar os resultados:

```bash
Rscript simulacao.R
```

O script grava:

- saídas do artigo em `resultados/`;
- saídas legadas em `legado/resultados/`.

## Observações

- O script está documentado com comentários indicando a origem dos parâmetros usados no artigo.
- O experimento E7 adiciona uma verificação com blends estaduais observados da oferta brasileira de biodiesel, preservando a mesma base operacional e regulatória do artigo.
- Em E7, as rotas tecnológicas puras de E1--E6 não são substituídas; os blends estaduais funcionam como extensão empírica complementar do argumento do artigo.
