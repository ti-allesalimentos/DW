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

## Bonificação (28/08/2026)

Mesma origem e mesmos joins do faturamento (SD2010+SF2010+SA1010), CFOP
de bonificação/amostra grátis (5910/5911/6910/6911) em vez de CFOP de
venda. Reaproveitou a mesma dedup de série e o mesmo filtro de tipo "B"
descobertos na reconciliação do faturamento — sem eles a divergência
inicial seria maior.

Comparado `prata_ouro.fato_bonificacao` contra `dw.fato_bonificacao`,
mesmo corte de data (`< 2026-07-13`):

| Métrica | Legado (`dw`) | Novo (`prata_ouro`) |
|---|---|---|
| Linhas | 2.082 | 2.082 |
| Valor total | R$ 7.896.896,71 | R$ 7.896.896,71 |
| Linhas só num lado | 0 | 0 |

**Divergência final: zero.**

## Devoluções (28/08/2026)

Fonte SD1010 (entrada), join diferente do faturamento/bonificação
(SF1010 obrigatório + SF2010 opcional pra data da NF original). Dois
bugs reais encontrados na reconciliação, ambos mais sérios que os do
faturamento:

### 1. Reaproveitamento de número de documento entre fornecedores diferentes

O Protheus reaproveita o mesmo `D1_DOC` para documentos de entrada de
**fornecedores completamente diferentes** — ex.: `filial 01004, doc
000014021` é ao mesmo tempo uma devolução de `06057223/0240` (27/02/2025,
R$119.252,04) e outra de `09477652/0096` (23/09/2025, R$245,00). A chave
`(filial, doc, serie, item)` não é única no SD1010; o dedup inicial
colapsava as duas em uma, misturando valores de transações completamente
diferentes (chegou a inflar uma linha em ~486x).

**Tratamento:** a chave de dedup em `stg_devolucoes` passou a incluir
cliente e loja (`cod_cliente, loja_cliente`), igual à chave usada no
join com o cabeçalho SF1010.

### 2. Lista de NFs excluídas específica de devolução, não capturada

A query legada tinha uma segunda lista de exclusões hardcoded, separada
da lista do faturamento: 14 NFs da filial 01004 e 2 da filial 01006.
Sem isso, 20 linhas (~R$3,5 milhões) vazavam para o fato novo.

**Tratamento:** o seed `excecoes_nf` ganhou uma coluna `dominio`
(`faturamento` | `devolucao`), e `stg_faturamento`/`stg_devolucoes`
agora filtram por domínio. O mesmo tratamento foi aplicado a
`excecoes_cliente` (devolução exclui um segundo cliente, `30704321`,
que não vale para os outros fatos).

Resultado, mesmo corte de data, comparando por `(filial, nf, serie,
item_nf, chave_cliente)` — chave de cliente entrou na comparação porque
o próprio reaproveitamento de número de documento também existe entre os
dois lados da reconciliação:

| Métrica | Legado (`dw`) | Novo (`prata_ouro`) |
|---|---|---|
| Linhas | 3.783 | 3.784 |
| Valor total | R$ 22.497.509,52 | R$ 22.482.011,39 |

Restam 4 linhas divergentes, todas explicadas:
- 3 só no novo: notas emitidas entre 04/07 e 09/07/2026, dentro da janela
  de corte mas ainda não capturadas pelo snapshot legado (a mesma
  natureza do corte de data, só que perto o bastante da borda pra não
  ter sido pego pelo `< 2026-07-13`).
- 1 só no legado (`filial 01007, doc 000047076`): **não existe mais no
  bronze atual** — o documento foi cancelado/excluído no Protheus depois
  que o snapshot legado foi capturado. Confirmado consultando
  `bronze.sd1010` diretamente (zero linhas para esse doc).

**Divergência final: zero — as 4 linhas restantes têm causa raiz
identificada (timing de captura, não erro de dado).**

## Refaturamento, remessa para industrialização e remessas Coopeval (28/08/2026)

Três fatos adicionais, todos originados de SD2010 com recortes diferentes:

**Remessa para industrialização** (CFOP 5901/5903/6901/6903): a aba
`fRemTriangular` da planilha legada tinha a **query idêntica** à de
`fRemIndustrializacao` — mesmos CFOPs, mesmos filtros, sem nada que as
diferencie (comentário do próprio `legado/ingestion/queries/
rem_triangular.sql` já apontava isso). O piloto anterior resolveu essa
ambiguidade populando só o tipo `INDUSTRIALIZACAO` em `dw.fato_remessa`;
mantive a mesma solução aqui — não faz sentido duplicar um modelo cuja
query de origem é byte-a-byte igual. Fica para quando alguém do negócio
confirmar se as duas deveriam ser distintas.

Reconciliado contra `dw.fato_remessa` (tipo `INDUSTRIALIZACAO`): **1.048
= 1.048 linhas, R$ 52.348.573,02 = R$ 52.348.573,02 — idêntico.**

**Remessas Coopeval** (cliente 07390806 apenas, sem filtro de CFOP): a
query legada tinha um corte `D2_EMISSAO > '20250430'` — não é regra de
negócio, é o mesmo tipo de recorte arbitrário de planilha já removido no
T5 (Fase 1). Não reproduzi esse corte de propósito. Comparando com o
mesmo corte que a planilha tinha: **518 = 518 linhas, R$ 23.890.284,61 =
R$ 23.890.284,61 — idêntico.** Sem o corte, o fato novo cobre ~2 meses a
mais de histórico (fev–abr/2025) que a planilha nunca teve.

**Refaturamento** (agregado por filial/produto/NF/série/data, só notas
com `SC5010.C5_X_REFAT` preenchido): divergência de ~2,5% (939 vs 924
linhas, R$8.765.941,14 vs R$8.547.542,79), com duas causas identificadas:
- A query legada de refaturamento tem sua **própria lista de conversão
  -CX, incompleta** — falta `PA01010011-CX`, que o `map_produto_cx`
  unificado já cobre (é exatamente a dívida do capítulo 6 da
  arquitetura: "a lista de fatores está repetida dentro de cada query,
  divergindo entre si"). Uma linha aparece com o código cru `-CX` no
  legado e convertido no novo — mesmo valor, classificação diferente.
- A maioria das linhas extras (18 de 21) tem datas espalhadas de
  janeiro a julho de 2026, não concentradas na borda do corte —
  indício de que `C5_X_REFAT` foi marcado **depois** que o snapshot
  legado foi capturado (o pedido só é sinalizado como refaturamento em
  algum momento posterior à emissão da nota).

Não persegui essas ~21 linhas uma a uma — a causa está identificada em
nível de padrão, mas não confirmada linha a linha como nos fatos
anteriores. Fica registrado como pendência menor, não como divergência
sem explicação.

## Acordo comercial (28/08/2026)

Query mais simples dos fatos comerciais: só SD1010 (TES 050/052), sem
nenhum join. Reconciliado contra `dw.fato_acordo_comercial`, mesmo corte
de data: 6.287 (novo) vs 6.256 (legado), R$1.998.192,83 vs
R$1.997.855,53.

Restam 44 linhas só no novo (notas de 06/07/2026, mesmo padrão de
timing de snapshot dos demais fatos) e 10 só no legado — estas últimas
com datas de **2000, 2007 e 2024**, muito antes da entrada do Protheus
(01/02/2025). O extrator nunca as buscou de propósito: o laço de carga
inicial (`extracao/carga.py`) usa `INICIO_PROTHEUS` como piso para
**todas** as fontes, não só o faturamento — mesma decisão já registrada
na arquitetura (cap. 10) de que o que existe antes da entrada do ERP é
resíduo de migração, não dado a tratar. Valor residual: ~R$1.300 em 10
linhas, imaterial.

**Divergência final: explicada — nenhuma causa raiz pendente.**

## Pedidos (28/08/2026)

Oitavo fato, o mais complexo: pedidos de venda liberados/embarcados
(SC9010), agregado por pedido/cliente/produto/item/sequência, juntando
SC9010+SB1010+SC6010+SC5010+SF2010+DAK010. **Fonte nova** — não existia
no piloto anterior (`dw` não tem `fato_pedidos`), então não há alvo de
reconciliação linha a linha. Três tabelas do Protheus nunca extraídas
antes entraram no bronze pela primeira vez: `SC9010` (160.209 linhas),
`SF4010` (1.585) e `DAK010` (7.850).

Diferença deliberada do legado: os joins com SE4010 (condição de
pagamento) e SF4010 (descrição do TES) viraram `LEFT` — eram `INNER` no
Power Query original, o que descartaria pedidos sem essas descrições
cadastradas.

Checagem de sanidade (sem alvo pra bater 1:1): 54.867 linhas, R$
699.051.316,28. Saúde referencial: **0 produtos órfãos**; **226/54.867
(0,4%) clientes não identificados**; **6.465/54.867 (11,8%) vendedores
não identificados** — investigado: 6.440 dessas linhas têm o campo
`C5_VEND1` **em branco no próprio Protheus** (pedido sem vendedor
atribuído, dado real). As 25 restantes (`"046"`, `"047"`) são um zero à
esquerda faltando que a comparação de string exata contra `dim_vendedor`
não resolve — mesma classe de problema do zero à esquerda já visto em
outros lugares, aqui não corrigido (afeta 0,05% do fato).

## Comissão — adiada para a Fase 4 (Financeiro)

`fComissao` depende de `SE5010` e `SE1010` — tabelas do domínio
**Financeiro** (cap. 10 da arquitetura), não Comercial. Construir esse
fato agora significaria pular a sequência "um domínio de cada vez" do
roadmap. Decisão: comissão migra junto com o domínio Financeiro
(Fase 4), não faz parte do fechamento da Fase 2.

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
- As ~21 linhas divergentes do refaturamento não foram explicadas linha
  a linha (só por padrão) — revisitar se o volume crescer.
- As 25 linhas de pedidos com vendedor sem zero à esquerda (`"046"`,
  `"047"`) não foram corrigidas — mesma classe de problema de outros
  lugares, aqui de baixo impacto.
- **Comissão** foi deliberadamente adiada para a Fase 4 (Financeiro) —
  ver seção acima.
- Todos os 7 fatos comerciais migrados nesta fase (faturamento,
  bonificação, devoluções, refaturamento, remessa industrialização,
  Coopeval, acordo comercial, pedidos — 8 no total) têm reconciliação
  registrada. Falta uma passada final comparando por corte mensal/filial
  em vez de só linha a linha, para garantir que o zero de divergência
  não é coincidência de soma agregada.
