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

- `resultados/tabelas/`
  Tabelas e bases intermediárias associadas aos experimentos E1--E6 do artigo.

- `legado/`
  Materiais que não entram na versão atual do artigo, mas foram mantidos para rastreabilidade.

- `legado/resultados/`
  Gráficos e tabelas legados, incluindo:
  - gráficos analíticos não usados no artigo;
  - saídas do experimento E7;
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
- Os cinco gráficos em `resultados/graficos/` foram conferidos contra os arquivos do manuscrito e permanecem visualmente idênticos.
