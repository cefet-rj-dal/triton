# Dados ANP usados no E7

Arquivos oficiais baixados em 21/07/2026 para documentar o recorte de março de 2026 do experimento E7.

## Preços B100

- Arquivo local: `anp-precos-medios-ponderados-semanais-2013-em-diante.xls`
- Página de origem: https://www.gov.br/anp/pt-br/assuntos/precos-e-defesa-da-concorrencia/precos/precos-de-produtores-e-importadores-de-derivados-de-petroleo-e-biodiesel
- Link disponibilizado pela ANP na página: `Preços Médios Ponderados Semanais a partir de 2013`
- Uso no simulador: médias semanais de março de 2026 para Biodiesel (B100), por região, sem ICMS.

## Matéria-prima e produção de biodiesel

- Arquivo local: `anp-biodiesel-materia-prima.csv`
- Arquivo local: `anp-biodiesel-producao.csv`
- Página de origem: https://www.gov.br/anp/pt-br/centrais-de-conteudo/paineis-dinamicos-da-anp/paineis-e-mapa-dinamicos-de-produtores-de-combustiveis-e-derivados/painel-dinamico-de-produtores-de-biodiesel
- Link disponibilizado pela ANP na página: `Base de dados utilizada no painel`
- Uso no simulador: confirmação dos cinco maiores estados produtores no recorte de março de 2026 e documentação da composição estadual por matéria-prima.

## Convenções

- Recorte temporal: março de 2026.
- Densidade do B100: `0,88 kg/L`.
- Câmbio usado para converter B100 de R$/L para USD/kg: `5,2296 R$/USD`, média mensal de março de 2026 reportada na série FRED/BCB para BRL por USD.
- Série cambial: https://fred.stlouisfed.org/series/EXBZUS
