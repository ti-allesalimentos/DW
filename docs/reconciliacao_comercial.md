# Reconciliação — Faturamento (Fase 2)

> Meta da Fase 2 (arquitetura.md): zero divergência inexplicada contra a
> planilha de referência do faturamento. Cada diferença encontrada abaixo
> foi investigada até a causa raiz — nenhuma foi ignorada ou arredondada.

Referência usada: `dw.fato_faturamento`, do piloto anterior (schema `dw`,
preservado no Postgres como referência de comparação). Esse fato já havia
sido reconciliado 100% contra a planilha `fFaturamento.xlsx` real numa
rodada anterior — bater contra ele valida `prata_ouro.fato_faturamento`
transitivamente contra a planilha, sem precisar reabrir o Excel.

## Resultado final (28/08/2026)

Comparando `prata_ouro.fato_faturamento` contra `dw.fato_faturamento`,
restrito a `dt_emissao < '2026-07-13'` (ver nota sobre o corte abaixo):

| Métrica | Legado (`dw`) | Novo (`prata_ouro`) |
|---|---|---|
| Linhas | 41.948 | 41.948 |
| Valor total | R$ 443.952.614,17 | R$ 443.952.614,17 |
| Linhas só num lado | 0 | 0 |
| Linhas com valor divergente na mesma chave | 0 | |

**Divergência final: zero.**

## Corte de data (`< 2026-07-13`)

O snapshot do `dw.fato_faturamento` foi capturado em algum momento do dia
13/07/2026 — não é uma cópia completa daquele dia. Incluir esse dia na
comparação gera ~91 "divergências" que são só notas emitidas depois do
horário do snapshot, não erro de dado. Comparar com um corte de segurança
antes desse dia isola a comparação do efeito de dois sistemas capturados
em instantes diferentes.

## Divergências encontradas e corrigidas

Duas causas raiz explicavam a diferença de 93 linhas / ~R$481 mil antes
do corte de data (e mais 2 linhas / candidatas a erro depois dele):

### 1. Série duplicada por padding inconsistente no Protheus

O SD2010 tem duas linhas físicas distintas (RECNOs diferentes) para a
mesma nota/item — `filial 01004, doc 000013482, item 01` — diferindo
apenas no campo `D2_SERIE`: uma grava `'1'`, a outra `'01'`. Mesmo valor,
mesma data, mesmo CFOP. É sujeira de dado na origem (provável evento de
correção/re-chave no Protheus), não erro de extração.

**Tratamento:** `stg_faturamento` normaliza a série removendo zero à
esquerda antes de montar a chave de negócio, e deduplica pela chave
completa (`filial, nfe, serie, item_nf`), mantendo uma linha por `RECNO`
mais antigo. Sem isso, essa venda específica contava em dobro.

### 2. Nota tipo "B" (bonificação) sem o filtro que a query legada tinha

`filial 01004, doc 000013774, item 01` tem CFOP 6101 (uma CFOP de venda
normal), mas o cabeçalho no SF2010 marca `F2_TIPO = 'B'` — bonificação,
não venda. A query legada (`legado/ingestion/queries/faturamento.sql`)
já excluía isso com `AND SF2.F2_TIPO <> 'B'`; o `stg_faturamento.sql`
reescrito na Fase 1 não tinha reproduzido essa regra.

**Tratamento:** `stg_faturamento` agora junta o cabeçalho do SF2010 e
exclui `tipo_nf = 'B'` — incluindo itens sem cabeçalho correspondente no
SF2010, replicando o comportamento da query legada (que usava `LEFT JOIN`
sem tratar `NULL` no filtro, descartando esses itens por efeito colateral
do SQL de três valores). Bonificação passa a ter fato próprio
(`fato_bonificacao`, ainda não construído) em vez de vazar para o
faturamento.

## O que ainda não foi feito

- Reconciliação por outros cortes (mês a mês, por filial) para garantir
  que o zero de divergência não é coincidência de soma agregada. O
  reconciliação atual já compara linha a linha pela chave de negócio, o
  que é mais forte que bater só o total, mas vale repetir a cada carga
  incremental relevante.
- Reconciliação do `fato_faturamento_datavale` — não há uma referência
  legada equivalente para o histórico DATAVALE; a validação daquele fato
  foi feita por taxa de casamento do de-para (99,3%), documentada em
  `stg_faturamento_datavale.sql`.
- Os outros 7 fatos comerciais (devoluções, bonificação, refaturamento,
  remessas, acordo comercial, pedidos, comissão) ainda não foram
  migrados — cada um precisa da mesma reconciliação linha a linha antes
  de fechar a Fase 2.
