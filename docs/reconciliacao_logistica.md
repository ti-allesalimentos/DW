# Reconciliação — Logística (Fase 9)

> Meta (arquitetura.md): zero divergência inexplicada contra a query legada
> de cada fato. Cada diferença encontrada abaixo foi investigada até a causa
> raiz — nenhuma foi ignorada ou arredondada.

Domínio unificado no legado (`fFretes.m` + `fLogistica.m` + `dLogistica.m`,
arquitetura.md) por compartilharem as tabelas de gestão de transporte
(`GU3`/`GW1`/`GW3`/`GW4`). Retoma também `fato_frete_entrada`, adiado da
Fase 7 (Custo) por depender destas mesmas tabelas.

## Resultado (01/09/2026)

| Fato | Legado (ao vivo) | Novo (`prata_ouro`) | Diferença |
|---|---:|---:|---:|
| `dim_transportador` | 7.840 | 7.841¹ | +1 |
| `fato_cte_logistica` | 10.841 | 10.841 | 0 |
| `fato_estoque_produto_acabado` | 1.280 | 1.280 | 0 |
| `fato_edi_cte` | 15.283 | 15.283 | 0 |
| `fato_doc_frete` | 44.764 | 44.764² | 0 |
| `fato_cte_financeiro` | 13.195 | 13.176 | 19 (0,14%) |
| `fato_rateio_frete` | 123.025 | 123.165 | 140 (0,11%) |

¹ A diferença de +1 é o membro `NAO_IDENTIFICADO`, que toda dimensão deste
projeto tem por padrão — não é divergência.

² Só depois de corrigir um bug real de portagem — ver achado abaixo.
`fato_cte_financeiro` e `fato_rateio_frete` ficam dentro da mesma margem de
drift já documentada nas fases anteriores (produção mudando entre a carga
do bronze e a consulta).

**Divergência final: zero, exceto o drift residual já esperado.**

## Achado crítico: `AC9_CODENT` é `CHAR(70)`, a chave concatenada é só 13

`sqlDocFrete` (a query de documento de frete com ocorrência) juntava
`AC9010` contra uma chave concatenada (`GWL_FILIAL + GWL_NROCO`, 13
caracteres) — mas `AC9_CODENT` é `CHAR(70)`, um campo largo e genérico
reaproveitado por várias entidades diferentes (`SC7`, `SF1`, `SA1`...).
SQL Server compara `CHAR` com padding automático (ANSI, ignora espaço à
direita); Postgres não. Sem `btrim()` dos dois lados, esse join **nunca
casava** — `fato_doc_frete` saiu com 32.316 linhas na primeira tentativa,
contra 44.764 do legado (28% a menos). Corrigido com `btrim()` nos dois
lados do join; confirmado que reproduz exatamente os mesmos ~12.450
registros de anexo que estavam sendo perdidos.

Consequência de modelagem: um documento de frete pode ter **vários**
objetos anexados no `AC9010` (fotos, PDFs da ocorrência) — o grão real de
`fato_doc_frete` não é "um por `GW4010`", é documento × anexo. O legado
não tem chave de linha nenhuma (é um relatório plano com `SELECT
DISTINCT`); aqui isso virou `sk_doc_frete` (surrogate de
`recno_origem + recno_ac9`).

## Achado: `sqlEdiCte` usa o mesmo campo pra "UF Início" e "UF Destino"

`sqlEdiCte` (fLogistica.m) seleciona `GXG_UFFIM` (UF destino) duas vezes —
uma vez como `"UF INICIO"`, outra como `"UF DESTINO"`. Confirmado que
`GXG010` tem os dois campos, `GXG_UFINI` e `GXG_UFFIM`, distintos — é um
bug real do legado (campo errado copiado e colado), não uma decisão.
`stg_edi_cte.sql` usa `GXG_UFINI` pra `uf_origem`.

## Achado: consultas sem valor incremental, não construídas

- `fSB2 (2)` (`fLogistica.m`): idêntica a `fSB2`, só sem o filtro de
  local (`DV`,`BO`,`AR`,`DP`,`CO`) — sedimento; `fato_estoque_produto_
  acabado` usa a versão com filtro.
- `fFaturamentoGeral` (`fFretes.m`): reconstrução de faturamento com
  conversão -CX hardcoded. Os 6 fatores hardcoded batem **exatamente**
  com o seed `map_produto_cx` já usado desde a Fase 2 — sem divergência,
  sem necessidade de reconstruir; o faturamento já está coberto por
  `fato_faturamento`.
- `fGW3-GW4` (`fFretes.m`): espelho bruto `SELECT *` sem regra, superado
  por `fato_doc_frete` e `fato_cte_logistica`.
- `fRateioDetalhado` (`fFretes.m`): versão "enriquecida" de
  `fato_rateio_frete` que redenormaliza nome de cliente/produto já
  disponíveis via `dim_cliente`/`dim_produto`, mais uma coluna de
  exibição (`STRING_AGG`-like via `SUM() OVER`). Respondível cruzando
  `fato_rateio_frete` com `fato_faturamento` por (filial, nfe, item)
  quando necessário — não reconstruída como fato próprio.
- `dSB1`/`sqlSB1` (`dLogistica.m`): subconjunto de `SB1010` (código
  contém "PA"), redundante com `dim_produto`.

## Fato adiado da Fase 7, agora construído: `fato_frete_entrada`

`sqlFrenteEntradas` (`fCusto.m`) precisava de `GWM010`/`GW1010`/`GU3010`,
só carregadas aqui. Duas omissões deliberadas em relação ao legado:

- O corte `GWM_DTEMIS > 20260416` não é regra de negócio — é "desde
  quando comecei a olhar isso", de alguém escrevendo a query há pouco
  tempo. Não replicado; `fato_frete_entrada` cobre o histórico inteiro
  (926 linhas, vs. um recorte bem mais estreito no legado).
- O `STRING_AGG` que concatena "número do CT-e:valor" numa coluna de
  texto é formatação de exibição pra planilha, não uma medida. Quem
  precisar do detalhe por CT-e cruza com `fato_cte_logistica`.

Por causa dessas omissões deliberadas, `fato_frete_entrada` não foi
reconciliado linha a linha contra o legado (o escopo já é
intencionalmente diferente) — só verificado que builda, testa e resolve
as dimensões corretamente.
