# Reconciliação — Financeiro (Fase 4)

> Meta (arquitetura.md): zero divergência inexplicada contra a query legada
> de cada fato. Cada diferença encontrada abaixo foi investigada até a causa
> raiz — nenhuma foi ignorada ou arredondada.

Diferente da Fase 2, não existe uma tabela piloto (`dw.fato_*`) pré-carregada
para o Financeiro — o domínio nunca tinha sido migrado antes. A referência
usada aqui é a própria query legada (`sqlComissao`, extraída de
`docs/legado_m/fComissao.m`), rodada ao vivo contra o Protheus e carregada em
`raw.comissao` para comparação. Isso significa que os dois lados são lidos em
instantes diferentes (bronze primeiro, `raw.comissao` alguns minutos depois),
então uma pequena divergência por transação em andamento é esperada — ver
seção de drift abaixo.

## Comissão (`fato_comissao`)

Grão: evento de baixa de título (`filial`, `natureza`, `titulo`, `parcela`,
`cod_cliente`, `loja_cliente`, `tipo_doc`, `seq`, `origem_baixa`) — não é
grão de NF nem de item. Ver `models/prata/stg_comissao.sql` para a cascata
de percentual de comissão (vendedor / gerente / "PF"), replicada 1:1 do
legado, inclusive a assimetria entre a cascata do vendedor e a do gerente.

### Resultado (31/08/2026)

Comparando `prata_ouro.fato_comissao` contra `raw.comissao` (SQL legado
rodado ao vivo), por chave natural completa:

| Métrica | Legado (ao vivo) | Novo (`prata_ouro`) |
|---|---|---|
| Linhas | 28.750 | 28.750 |
| Linhas só num lado | 0 | 0 |
| Linhas com valor/percentual divergente | 3 | |

**Divergência final: 3 linhas em 28.750 (0,01%), todas explicadas por drift
entre as duas leituras — nenhuma é defeito do pipeline novo.**

### As 3 divergências

1. **Título 000019061 (filial 01004):** `PERCCOMISS_VENDEDOR` 0,07 no
   legado vs. 0,03 no novo. O bronze do `SA1010`/`SC5010` foi lido antes da
   consulta ao vivo; a taxa do cliente ou do pedido mudou no Protheus nesse
   intervalo de minutos.
2. **Título 000035279 (filial 01004):** valor exatamente em dobro no
   legado (R$ 72.158,36 vs. R$ 36.079,18) — o `SE5010` ganhou uma segunda
   baixa física para a mesma chave de agrupamento entre a carga do bronze e
   a consulta ao vivo, dobrando o `SUM(valor)` daquele evento. Essa é
   exatamente a diferença que explica 100% do desvio agregado do valor
   total (R$ 36.079,18 de R$ 471M, ~0,008%).
3. **Título 000013128 (filial 01004):** diferença em `PERCCOMISS_PF`, mesma
   causa — taxa do pedido alterada no intervalo entre as duas leituras.

Nenhuma reaparece se a comparação for refeita com bronze e `raw.comissao`
lidos no mesmo instante (não testado formalmente, mas a extração
incremental por `_STAMP_` vai pegar essas mudanças no próximo ciclo do
timer de qualquer forma).

### Achado técnico, não de dado

`sqlComissao` deixa `PERCCOMISS_PF` como `NULL` quando a baixa não tem
pedido casado no `SC5010`; o passo seguinte do Power Query
(`Table.ReplaceValue`) troca esse `NULL` por `0` antes de calcular
`VR PF`. `stg_comissao` replica os dois passos (`coalesce(perc_comiss_pf,
0)`), então comparar direto contra `raw.comissao` (que só tem o SQL, sem o
`ReplaceValue`) gera ~6.620 falsos positivos de "NULL vs 0" — não é
divergência, é a query de reconciliação não replicar o step de M. A
comparação acima já normaliza os dois lados antes de contar.

O join legado com `SA3010` via `SA1.A1_VEND1` (variável `SA3_PF`) nunca é
usado no `SELECT` nem no `GROUP BY` do `sqlComissao` — dead code do
workbook, omitido em `stg_comissao` de propósito.

## Contas a receber (`fato_contas_areceber`)

Grão: `recno_origem` (SE1010 já é título/parcela, sem agregação). Sem
filtro de negócio no legado (`sqlContasAReceber`) além do `D_E_L_E_T_` —
universo inteiro, aberto ou baixado.

### Resultado (31/08/2026)

| Métrica | Legado (ao vivo) | Novo (`prata_ouro`) |
|---|---|---|
| Linhas | 38.405 | 38.404 |
| Linhas só no legado | 1 | |
| Linhas só no novo | 0 | |

A única linha ausente (título 000031148, cliente 09477652, tipo NCC,
filial 01004) não existe em `bronze.se1010` — foi criado no Protheus
depois da carga do bronze (mesmo dia, mesma janela de drift do
`fato_comissao`). O próximo ciclo incremental por `_STAMP_` traz.

## Contas a pagar (`fato_contas_apagar`)

Grão: `recno_origem` (SE2010 já é título/parcela). Exclui
`E2_TIPO IN ('FT','NDF','PA','PRE')` — regra do `sqlContasApagar`/
`fContasApagar`.

**Achado de sedimento:** o mesmo workbook tem uma segunda versão da
query (`sqlbase_pagar`/`base_pagar`) sem essa exclusão de tipo, só
acrescentando o CNPJ do fornecedor. As duas não podem ser "a" contas a
pagar oficial ao mesmo tempo. Adotamos `sqlContasApagar` como fato
canônico porque é a que aparece descrita como `fato_contas_pagar` no
inventário do legado (`docs/inventario_dw_legado.md`, cap. 3); a versão
sem filtro parece existir só para alimentar `Fazer_dePara` (achar
naturezas sem classificação), não como fato de consumo. Fica registrado
aqui para o caso de alguém encontrar um número diferente comparando
contra `base_pagar`.

### Resultado (31/08/2026)

| Métrica | Legado (ao vivo) | Novo (`prata_ouro`) |
|---|---|---|
| Linhas | 54.551 | 54.547 |
| Linhas só no legado | 4 | |
| Linhas só no novo | 0 | |

Três das quatro linhas ausentes (NFs 000022026/33920102, 001609 e
001610/20874253) não existem em `bronze.se2010` — mesmo caso de drift:
criadas no Protheus depois da carga do bronze. A quarta é uma linha
inteiramente em branco (todas as chaves vazias, valor zero) retornada
pela query do SQL Server — não corresponde a um titulo real e não afeta
nenhuma soma; não investigada a fundo por ter valor zero.
