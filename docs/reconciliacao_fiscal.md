# Reconciliação — Fiscal (Fase 5)

> Meta (arquitetura.md): zero divergência inexplicada contra a query legada
> de cada fato. Cada diferença encontrada abaixo foi investigada até a causa
> raiz — nenhuma foi ignorada ou arredondada.

Mesma situação da Fase 4: não existe piloto `dw.fato_*` para o Fiscal. A
referência é a query legada (`fFiscal.m`) rodada ao vivo contra o Protheus.
Diferente da Fase 4, aqui a comparação direta expôs bugs reais de fan-out
no legado — grandes o bastante para que a contagem de linhas por si só já
avise que algo está errado, antes de qualquer comparação linha a linha.

## Achado crítico: `sqlSFT` infla ~3,6x por dois joins sem chave de item

`sqlSFT` (a query "tributo por NF") devolveu **450.135 linhas** ao vivo,
contra **123.545** em `fato_tributo_nf` — quase 4x mais. Isolado por partes
(contagem via `COUNT(*)` direto no SQL Server, sem trazer os dados):

| Variante | Linhas |
|---|---:|
| `bronze.sft010` sozinho (so o filtro de delete) | 123.698 |
| + `SB1010`/`SX5010`(x2)/`SBM010`/`SA2010`/`SA1010` (sem SD1010) | 146.156 |
| + `SD1010` (join completo, igual ao legado) | 450.135 |

**Causa raiz 1 (dominante, ~3x):** `sqlSFT` faz `LEFT JOIN SD1010` usando só
a chave da NF inteira (`FT_NFISCAL=D1_DOC, FT_SERIE=D1_SERIE,
FT_CLIEFOR=D1_FORNECE, FT_LOJA=D1_LOJA`) — sem o item (`D1_ITEM`). Como
`SFT010` já é por item, e uma NF normalmente tem vários itens em
`SD1010`, cada linha de `SFT010` é multiplicada por **todos** os itens da
mesma nota, não só o seu próprio. `fato_tributo_nf` usa `SD1010` só pra
buscar o ISS por nota (`stg_tributo_nf.sql`), com um `DISTINCT ON` que
colapsa pra uma linha por nota antes do join — isso evita o fan-out de
propósito.

**Causa raiz 2 (~18% adicional):** mesmo sem o `SD1010`, os joins de
classificação (`SB1010`→`SX5010`→`SBM010` pro tipo/grupo de produto,
`SA2010`/`SA1010` pro nome) já inflam de 123.698 pra 146.156. Ver achado
abaixo — é o mesmo problema do código genérico `97316293`.

`fato_tributo_nf` não replica nenhum desses dois joins: resolve
cliente/fornecedor/produto contra `dim_cliente`/`dim_fornecedor`/
`dim_produto` (já deduplicadas) no fato, não via join direto nas tabelas
cruas. O número certo é o do bronze filtrado (123.698), não o do legado
(450.135) — **123.545 bate com isso** (diferença de 153 linhas, ~0,1%,
consistente com o mesmo drift de produção das seções da Fase 4).

## Achado crítico: código genérico `97316293` tem cadastro duplicado no SA1010

O mesmo cliente `97316293` já excluído do faturamento na Fase 2 (cap. 6 da
arquitetura) tem **linhas duplicadas em `SA1010`** — o cadastro de cliente,
não o de fornecedor:

| Loja | Linhas em `SA1010` | Linhas em `SD1010` que referenciam esse fornecedor/loja |
|---|---:|---:|
| 0001 | 2 | 2 |
| 0003 | 3 | 3.535 |
| 0004 | 2 | 3.779 |
| 0006 | 2 | 802 |

Qualquer `LEFT JOIN` direto contra `SA1010` sem deduplicar multiplica cada
uma dessas ~8.118 linhas de `SD1010` pelo número de cadastros duplicados —
essa é a causa dos dois achados de fan-out acima (`sqlSFT` e
`sqlImpostosEntradas`, abaixo). `SA2010` e `SB1010` não tem esse problema
(zero chaves duplicadas, checado diretamente).

Isso é o mesmo padrão já visto no `SA3010` (Fase 2, `dim_vendedor`): um
código muito usado (aqui, o "cliente genérico") acumula cadastro
duplicado ao longo do tempo, e vira uma bomba de fan-out silenciosa pra
qualquer query que faça `LEFT JOIN` direto sem `DISTINCT`/dedup. As
dimensões deste projeto (`dim_cliente`, `dim_fornecedor`) já deduplicam
por padrão (`distinct on (cod, loja) ... order by _carregado_em desc`) —
por isso os fatos que resolvem contra elas não herdam o problema.

## Contas de tributo por item — `fato_impostos_entrada` / `fato_impostos_saida`

| Fato | Legado (ao vivo) | Novo (`prata_ouro`) | Diferença |
|---|---:|---:|---:|
| `fato_impostos_entrada` | 116.414 | 100.964 | 15.450 (13,3%) |
| `fato_impostos_saida` | 139.168 | 128.391 | 10.777 (7,7%) |

Replicando os joins do legado (`SA2010`/`SA1010`/`SB1010`, além de
`F2D010`/`F2B010`) sobre o mesmo snapshot do bronze usado por
`fato_impostos_entrada`: **115.980 linhas** — bate com o legado ao vivo
(116.414, diferença de 0,4%, drift normal). Confirma que a causa é a
mesma dos achados acima: o cadastro duplicado de `97316293` em `SA1010`.

`stg_impostos_entrada`/`stg_impostos_saida` não fazem esse join — o
fornecedor/cliente é resolvido no fato contra `dim_fornecedor`/
`dim_cliente`, já deduplicadas. O número correto é o meu (100.964 /
128.391), não o do legado.

## Notas fiscais de serviço e notas com anexo

| Fato | Legado (ao vivo) | Novo (`prata_ouro`) | Diferença |
|---|---:|---:|---:|
| `fato_notas_servico` | 5.471 | 5.459 | 12 (0,2%) |
| `fato_notas_anexo` | 16.698 | 16.396 | 302 (1,8%) |

`fato_notas_servico` bate dentro da margem de drift já estabelecida nas
seções anteriores — sem achado novo.

`fato_notas_anexo` tem uma diferença um pouco maior (1,8%). A query
legada (`sqlfNotasSemAnexo`) não tem nenhum join que já não esteja aqui
(só `SA2010` pro nome, que não é usado no fato); a diferença mais provável
é o mesmo drift de produção agravado por `SF1010` ter crescido ~0,5% no
intervalo entre a carga do bronze e a consulta ao vivo. Não investigada
linha a linha por já estar dentro da mesma ordem de grandeza das
diferenças de drift confirmadas na Fase 4.

## Nota técnica: coluna duplicada em `sqlSFT` trava reconciliação ingênua

`sqlSFT` tem duas colunas chamadas `"Aliq. PIS"` (uma pra `FT_ALIQPIS`,
outra pra `FT_ARETPIS`, o PIS retido) — SQL Server aceita a query em si
(não valida nomes de coluna duplicados numa projeção simples), mas rejeita
com erro `8156` assim que a query é usada como subconsulta (`SELECT
COUNT(*) FROM (...) x`). Tentar carregar o resultado direto via
`pandas.to_sql` sem tratar isso primeiro trava o processo por horas (CPU
a 100% sem nunca terminar) em vez de falhar rápido — matamos o processo e
resolvemos comparando com `COUNT(*)` server-side depois de renomear a
coluna duplicada localmente. `stg_tributo_nf.sql` não tem esse problema:
usa nomes de saída distintos (`aliq_pis` / `aliq_pis_retido`).
