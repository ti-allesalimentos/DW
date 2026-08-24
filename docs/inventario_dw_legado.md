# Inventário do DW legado (Excel/Power Query)

> Extração automatizada do código Power Query embutido nos workbooks de
> `P:\T.I\01. BASES`. Este documento é o mapa completo do que existe hoje —
> a base factual para modelar o novo DW.
> 21/08/2026. Complementa `docs/arquitetura.md` (v1.2).

---

## 1. Método

O código Power Query (linguagem M) de um workbook Excel fica guardado em
`customXml/itemN.xml`, codificado em UTF-16, contendo um blob base64 que é, ele
próprio, um arquivo zip com `Formulas/Section1.m` dentro. O script
`docs/legado_m/extrair_m.py` desempacota isso e grava um `.m` legível por workbook.

Resultado: **22 workbooks processados, 272 consultas extraídas**, cobrindo
**70 tabelas distintas do Protheus**. Os arquivos estão em `docs/legado_m/`.

Isto substitui, para as áreas já cobertas, o passo de descoberta previsto no
capítulo 8 da arquitetura: não é preciso vasculhar `SX2`/`SX3` para saber quais
tabelas a Alles usa — as consultas em produção já respondem.

---

## 2. Panorama

O DW atual são cerca de **600 MB de planilha** atualizados por uma macro VBA
(`atualizador_1.9.xlsm`) cuja programação vive numa tabela Excel dentro do
`config.xlsm`. Cada workbook expõe uma consulta `__STATUS__` que devolve a data da
última carga — um controle de frescor rudimentar, mas que existe e funciona.

| Workbook | Área | Tamanho | Consultas | Principais tabelas |
|----------|------|---------:|----------:|--------------------|
| `fGestaoPessoas` | Gestão de Pessoas | 191 MB | 27 | SRA, SRC, SRD, SRG, SRV, SR3, SR8, SP8, SPC, SPH, SPI, SPK, RCC, RG1 |
| `fFiscal` | Fiscal | 156 MB | 28 | SFT, SDT, SDS, SF1, SF2, SD1, SD2, SE2, SED, SCR, SAK, AC9 |
| `fFinanceiro` | Financeiro | 95 MB | 61 | SE1, SE2, SE5, SED, SEV, CT1, CTT, CQ0, FK5, FK7, FRV, SA6, SIG |
| `fFretes` | Logística | 36 MB | 14 | GU3, GW1, GW3, GW4, GWM, SF4, SD2, SF2, SE2 |
| `fCompras` | Compras | 35 MB | 12 | SC1, SC7, SD1, SF1, SB2, SA2, SE4 |
| `APONTAMENTODEPRODUCAO` | Industrial | 16 MB | 13 | SC2, SD3, SG2, SH6, SB1 |
| `PEDIDOSDEVENDACONSOLIDADO` | Comercial | 10 MB | 6 | SC5, SC6, SC9, SF2, SF4, SE4, DAK |
| `fFaturamento` | Comercial | 9 MB | 21 | SD2, SF2, SD1, SF1, SC5, SA1, SB1 |
| `fCusto` | Custo | 6 MB | 20 | SB9, SC2, SD3, SD1, SF1, CTT, GU3, GW1, GW3, GW4, GWM, GU3 |
| `fComissao` | Comercial | 5 MB | 4 | SE1, SE5, SC5, SA3, SA1 |
| `dCalendario` | Dimensão | 5 MB | 4 | — (gerado) |
| `fLogistica` | Logística | 3.8 MB | 7 | SB2, GWD, GWL, GXG, GU3, GW1, GW3, GW4, AC9 |
| `fManual` | Dimensões manuais | 2 MB | 1 | — (manual) |
| `dCompras` | Dimensão | 1.7 MB | 10 | SA2, SE4, SE2, SB1 |
| `dClientes` | Dimensão | 1 MB | 12 | SA1, SE4, SB1 |
| `dProdutos` | Dimensão | 0.6 MB | 7 | SB1, SBM |
| `dSaldoAtual` | Dimensão | 0.2 MB | 5 | SB2, SB1 |
| `dNatFin` | Dimensão | 0.07 MB | 5 | SED |
| `MOTIVORESCISAO` | Dimensão (RH) | 0.05 MB | 2 | — |
| `dVendedores` | Dimensão | 0.05 MB | 4 | SA3 |
| `dLogistica` | Dimensão | 0.02 MB | 3 | SB1 |
| `config` / `atualizador_1.9` | Orquestração | — | 10 | — |

---

## 3. Dimensões conformadas — o que o novo DW precisa unificar

Estas tabelas do Protheus são consumidas por três ou mais workbooks. Cada
consumidor hoje aplica seu próprio TRIM, seu próprio filtro e seu próprio conjunto de
colunas — é exatamente aqui que os números divergem entre áreas. No modelo alvo, cada
uma vira **uma** dimensão conformada, construída uma vez na prata.

| Tabela | Nº de workbooks | Dimensão alvo |
|--------|----------------:|---------------|
| `SB1010` produtos | 12 | `dim_produto` |
| `SA1010` clientes | 8 | `dim_cliente` |
| `SA2010` fornecedores | 7 | `dim_fornecedor` |
| `SA3010` vendedores | 5 | `dim_vendedor` |
| `SF1010` / `SD1010` NF entrada | 5 | fatos de entrada |
| `SC5010` pedidos de venda | 4 | `fato_pedido` |
| `SE4010` condições de pagamento | 4 | `dim_cond_pgto` |
| `SF2010` / `SD2010` NF saída | 4 / 3 | `fato_faturamento` |
| `SE2010` contas a pagar | 4 | `fato_contas_pagar` |
| `SED010` naturezas financeiras | 3 | `dim_natureza_financeira` |
| `SBM010` grupos de produto | 3 | `dim_grupo_produto` |
| `SB2010` saldos de estoque | 3 | `fato_estoque` |
| `CTT010` centros de custo | 3 | `dim_centro_custo` |
| `GU3/GW1/GW3/GW4` gestão de transporte | 3 | `fato_frete` |

Que `SB1010` seja lido por doze workbooks diferentes é a medida exata do problema:
doze definições possíveis de "produto" convivendo na mesma empresa.

---

## 4. Duplicações explícitas

Consultas com o mesmo nome em workbooks diferentes — mesma intenção, implementações
que já podem ter divergido:

| Consulta | Aparece em |
|----------|------------|
| `sqlComissao` / `dComissao` | `fComissao`, `fCusto` |
| `sqlDevolucoes` / `fDevolucoes` | `fCompras`, `fFinanceiro` |
| `sqlSemClassificar` / `fSemClassificar` | `fFinanceiro`, `fFiscal` |
| `dVendedores` | `dVendedores`, `fComissao` |

Some-se a isso as seis cópias de `faturamento.sql` nos repositórios de relatório
(cap. 9 da arquitetura). São, no mínimo, **dez lugares** onde a mesma pergunta é
respondida por código diferente.

---

## 5. Achados críticos

**Dois cortes de data dentro do mesmo workbook.** O `fFaturamento.m` tem consultas
filtrando `D2_EMISSAO > '20250131'` e outras filtrando `D2_EMISSAO > '20250430'`. Não
é decisão de negócio — é sedimento. Duas abas do mesmo arquivo cobrem períodos
diferentes, e quem cruza uma com a outra obtém um número que não existe.

**O endereço do Protheus está embutido em 22 arquivos.** Cada workbook carrega a
string de conexão com host, porta e base. Trocar o servidor hoje significa editar 22
planilhas à mão. No modelo alvo isso vive em um `.env`, num lugar só.

**Toda carga falha antes de passar.** O `log_persistente.txt` mostra o padrão
`Iniciando → Falha na tentativa 2 → Concluído` em **todos** os workbooks, todos os
dias. O pipeline funciona por causa do retry, não apesar dele. Um dia o retry não vai
bastar.

**Restos de execuções interrompidas.** Dois arquivos `.tmp` órfãos na pasta, um deles
com 128 MB, além de quatro arquivos de lock `~$` — sinais de travamentos que ninguém
limpou.

**O ponto de ruptura está próximo.** Um workbook de 191 MB e outro de 156 MB estão no
limite do que o Excel sustenta. A migração não é melhoria de conforto; é substituição
de uma estrutura que já dá sinais de fadiga.

---

## 6. Impacto no roadmap

O inventário revelou três domínios que não estavam nas sete áreas originais:

- **Fiscal** (`fFiscal`, 156 MB, 28 consultas, 19 tabelas) — grande e específico
  demais para ser apêndice do Financeiro. Merece domínio próprio.
- **Custo** (`fCusto`, 20 consultas) — entrelaçado com o Industrial (`SC2`, `SD3`) e
  com Fretes (`GW*`). Candidato a domínio próprio, construído logo após o Industrial.
- **Comissão** (`fComissao`) e **Pedidos** (`PEDIDOSDEVENDACONSOLIDADO`) — cabem
  naturalmente dentro do Comercial.

E confirmou que **Fretes e Logística compartilham as mesmas tabelas de TMS**
(`GU3`, `GW1`, `GW3`, `GW4`) — devem ser um domínio só, não dois.

Sugestão de sequência revista, mantendo o princípio de uma área por vez:

Comercial (faturamento + pedidos + comissão) → Financeiro → Fiscal → Industrial →
Custo → Compras → Logística (fretes + logística) → Gestão de Pessoas → Marketing.

---

## 7. Próximos passos

1. **Decidir o escopo de domínios** à luz do capítulo 6.
2. **Ler o M do comercial em profundidade** — `fFaturamento.m` tem as 21 consultas que
   sustentam o número oficial da empresa, incluindo as exclusões de NF. É a
   especificação da Fase 2.
3. **Extrair também o VBA** do `atualizador_1.9.xlsm`, que contém a lógica de
   orquestração (ordem de carga, retry, log) — útil para não perder regra na migração.
4. **Reconciliar as duas janelas de data** do `fFaturamento` antes de tratá-lo como
   referência.
