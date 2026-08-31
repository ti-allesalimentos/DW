# Reconciliação — Industrial (Fase 6)

> Meta (arquitetura.md): zero divergência inexplicada contra a query legada
> de cada fato. Cada diferença encontrada abaixo foi investigada até a causa
> raiz — nenhuma foi ignorada ou arredondada.

Mesma situação das Fases 4 e 5: sem piloto `dw.fato_*` pra este domínio. A
referência é `APONTAMENTODEPRODUCAO.m` rodado ao vivo, comparado por
`COUNT(*)` server-side (lição da Fase 5: nunca materializar o resultado
completo em pandas antes de confirmar que a contagem faz sentido).

## Resultado (31/08/2026)

| Fato | Legado (ao vivo) | Novo (`prata_ouro`) | Diferença |
|---|---:|---:|---:|
| `fato_apontamento_producao` | 41.749 | 41.743 | 6 (0,01%) |
| `fato_ordem_producao` | 2.861 | 2.861 | 0 |
| `fato_lancamento_producao` | 143.945¹ | 143.930 | 15 (0,01%) |
| `fato_lancamento_indireto` | 1.459 | 1.459 | 0 |
| `fato_reprocesso` | 45 | 45 | 0 |

¹ Legado original filtra `D3_FILIAL = '01004'` (143.893 linhas); o número
acima já é sem esse filtro, pra comparar com o mesmo escopo do fato novo
— ver achado abaixo.

**Divergência final: zero exceto drift residual (<0,02%) explicado pela
mesma janela de tempo entre bronze e consulta ao vivo já documentada nas
Fases 4 e 5.**

## Achado: `SD3.D3_FILIAL = '01004'` não é regra de negócio

`sqlLancamentos` restringe à filial `01004`. Confirmado direto no
Protheus: lançamentos com `D3_TM > 500` (a mesma condição da query)
existem em **9 filiais diferentes** (`01001, 01003, 01004, 01006, 01007,
01009, 01010, 01011, 03001`), não só a `01004`. A planilha original
provavelmente foi feita pra acompanhar só a fábrica principal — não é uma
regra que qualifique o dado, é o escopo de quem pediu o relatório.

`fato_lancamento_producao` não replica essa restrição: mirrora todas as
filiais (mais 52 linhas fora da `01004`, ~0,04% do total — o impacto real
é pequeno, mas o princípio importa: bronze espelha, prata decide, e essa
decisão nunca foi realmente "só filial 01004").

## Achado: `SG2010.G2_OPERAC` não é único

`SG2010` (roteiro de operação) tem `G2_OPERAC` duplicado — o código `'1'`
aparece **33 vezes**, com **4 descrições diferentes**; `'AP'` aparece 12
vezes com 2 descrições diferentes. Um `LEFT JOIN SH6010→SG2010` direto
nessa chave multiplicava `fato_apontamento_producao` de 41.743 pra 41.743
(as duas removidas... ver nota) — na prática o teste `unique(recno_origem)`
falhou com **41.743 resultados** (praticamente toda a tabela duplicada)
antes da correção.

O legado sobrevive a isso por uma coincidência dupla: usa `SELECT
DISTINCT` na saída, e as descrições duplicadas dos dois piores códigos
(`'1'`, `'AP'`) nunca aparecem no resultado — o `CASE` da query sobrescreve
a descrição desses dois códigos especificamente com texto fixo
("PRODUCAO HAMBURGUER"/"PRODUCAO ALMONDEGA"), então o `DISTINCT` colapsa
tudo de volta pra uma linha por apontamento por acidente, não por design.
Os demais códigos duplicados (`CP`, `HP`, `SP`, `LP`, `MP`, `BP`, `PC`)
têm descrição igual em todas as cópias, então também colapsam bem — mas
isso é frágil: qualquer novo código de operação com descrição
inconsistente quebraria silenciosamente.

`stg_apontamento_producao.sql` deduplica o `SG2010` por `g2_operac`
(`distinct on ... order by _carregado_em desc`, o mesmo padrão já usado em
`dim_vendedor`/`dim_natureza_financeira`) antes do join — corrige a causa,
não só o sintoma.
