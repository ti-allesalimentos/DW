# Reconciliação — Custo (Fase 7)

> Meta (arquitetura.md): zero divergência inexplicada contra a query legada
> de cada fato. Cada diferença encontrada abaixo foi investigada até a causa
> raiz — nenhuma foi ignorada ou arredondada.

**Status: construção concluída, reconciliação ao vivo pendente.** O
Protheus ficou inacessível (timeout de conexão, 3 tentativas, confirmado às
19h18 do dia 31/08/2026 — fora do horário comercial, provável restrição de
rede noturna) no meio da Fase 7. Os 5 fatos abaixo foram construídos e
testados contra o bronze já carregado em fases anteriores (`SD3010`,
`SC2010`, `SB1010`, `SF1010`, `SD1010`, `CTT010`), mas ainda não comparados
contra a query legada ao vivo. `SB9010` (saldo inicial de estoque,
`dSaldoInicial`) não foi carregado — depende da mesma conexão.

**Pendências para quando a conexão voltar:**
1. Carregar `SB9010` e construir `fato_saldo_inicial_estoque`.
2. Rodar as 5 queries legadas (`sqlProdutoAcabado`, `sqlConsumo`,
   `sqlEntradas`, `sqlComissao` do `fCusto.m`, `sqlPerdas`) via `COUNT(*)`
   server-side, como nas Fases 5 e 6.
3. Atualizar esta seção com o resultado.

## Dois bugs de portagem Postgres encontrados e corrigidos

Nenhum dos dois é defeito do legado — são armadilhas da tradução SQL
Server → Postgres já conhecidas deste projeto, reencontradas aqui porque
`fCusto.m` reutiliza os mesmos padrões de `D3_OP` e `D3_ESTORNO` que
`APONTAMENTODEPRODUCAO.m`, mas em consultas novas que eu ainda não tinha
escrito.

**`D3_OP` (14 caracteres, com espaço à direita) comparado contra a
concatenação `C2_NUM+C2_ITEM+C2_SEQUEN` do SC2010 (11 caracteres, sem
padding extra).** No SQL Server essa comparação funciona por padding
automático (ANSI, ignora espaço à direita em `CHAR`); no Postgres não —
comparação de texto é exata. `stg_produto_acabado.sql`,
`stg_consumo_producao.sql` e `stg_perdas_producao.sql` vieram com **zero
linhas** até eu adicionar `btrim()` no lado do `D3_OP`. Achado equivalente
já resolvido em `stg_reprocesso.sql` (Fase 6) — dessa vez esqueci de
replicar a mesma correção nos três modelos novos.

**`trim_protheus()` converte `D3_ESTORNO` em branco pra `NULL`, quebrando
o filtro `<> 'S'`.** Mesmo padrão da Fase 4/5 (`E5_SITUACA`,
`stg_tarifas_bancarias.sql`): `D3_ESTORNO` vem `' '` (não `NULL`) em ~99,5%
das linhas válidas (882 de 886 pra `TM=507`), e `NULL <> 'S'` nunca é
verdadeiro em SQL — excluía a tabela inteira. Corrigido usando `btrim()`
puro nesse filtro específico em `stg_consumo_producao.sql` e
`stg_perdas_producao.sql`.

## Achado: nome `dComissao` reaproveitado, sem relação com a Fase 4

`fCusto.m` tem sua própria consulta `sqlComissao`/`dComissao` —
completamente diferente da de `fComissao.m` (Fase 4, baseada em `SE5010`,
comissão de vendas). A daqui é sobre notas de compra tipo 'C'/série 'COM'
(custo de comissão sobre compra, provavelmente frete/importação).
Já listado como uma "duplicação" no inventário do legado
(`docs/inventario_dw_legado.md`, cap. 4) — mas é coincidência de nome, não
duplicação de regra. Modelado aqui como `fato_custo_comissao_compra`,
nome deliberadamente diferente pra não confundir com `fato_comissao`.

## Achado: `sqlProdutoAcabado` filtra filial 01004 na planilha, não na regra

Mesmo padrão já visto no Industrial (Fase 6): `TM='010'` (produção de
produto acabado) ocorre nas filiais `01004` **e** `01006` (confirmado no
bronze). O filtro `[FILIAL] = "01004"` do legado é um `Table.SelectRows`
no Power Query, depois da consulta SQL — escopo de quem pediu o relatório,
não regra de negócio. `fato_produto_acabado` não replica essa restrição.

## Fatos construídos (contagens locais, sujeitas a confirmação)

| Fato | Linhas (bronze atual) |
|---|---:|
| `fato_produto_acabado` | 2.767 |
| `fato_consumo_producao` | 37.011 |
| `fato_perdas_producao` | 790 |
| `fato_entradas_custo` | 56.329 |
| `fato_custo_comissao_compra` | 705 |

## Adiado para a Fase de Logística

`dFrenteEntradas` (frete rateado por item de NF de entrada) usa tabelas de
gestão de transporte (`GWM010`, `GW1010`, `GU3010`, `GW3010`, `GW4010`)
que pertencem ao domínio Logística/Fretes (arquitetura.md, Fase 9), não
ainda carregadas. A query é complexa (CTE com `STRING_AGG`, múltiplos
`LEFT JOIN`) e cruza domínios — fica pra quando Logística for construído,
não faz sentido antecipar só a parte que toca custo.

`fCCusto`/`dCTT` (mesmo arquivo) são redundantes com
`fato_lancamento_indireto`/`dim_centro_custo`, já construídos na Fase 6 —
não recriados aqui.
