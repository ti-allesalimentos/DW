# Reconciliação — Compras (Fase 8)

> Meta (arquitetura.md): zero divergência inexplicada contra a query legada
> de cada fato. Cada diferença encontrada abaixo foi investigada até a causa
> raiz — nenhuma foi ignorada ou arredondada.

## Resultado (31/08/2026, ~23h30)

| Fato | Legado (ao vivo) | Novo (`prata_ouro`) | Diferença |
|---|---:|---:|---:|
| `fato_saldo_fisico_compras` | 4.513 | 4.513 | 0 |
| `fato_pedido_compra` | 16.816 | 16.816 | 0 |
| `fato_historico_preco_compra` | 10.426 | 10.426 | 0 |
| `fato_devolucao_compra` | 47¹ | 31 | 14¹ |

¹ Ver achados abaixo — o número certo pra comparar é 45 (join corrigido),
e a diferença restante contra os 31 do fato é drift de bronze desatualizado
(carregado há várias horas), não defeito de lógica.

**Divergência final: zero, exceto o drift explicado de `fato_devolucao_compra`.**

## Achado: `sqlDevolucoes` é byte-idêntica em dois workbooks

`fCompras.m` e `fFinanceiro.m` têm a mesma consulta `sqlDevolucoes`/
`fDevolucoes`, caractere por caractere (confirmado no inventário do
legado, cap. 4). Resolvida uma única vez aqui, como
`fato_devolucao_compra` — cobre também o item que tinha ficado de fora da
Fase 4 (nunca foi construído em `docs/reconciliacao_financeiro.md`).

## Achado: mesmo padrão de reuso de número de documento já visto na Fase 2

O `JOIN` do legado entre `SF1010` e `SD1010` usa só `(doc, serie)`, sem
fornecedor/loja — o mesmo tipo de problema já identificado em
`fato_devolucoes` (Comercial, Fase 2: "SD1010 document-number reuse
across unrelated suppliers"). Testado ao vivo: **47 linhas** com o join
do legado (`doc+serie`) contra **45** com a chave completa
(`doc+serie+fornece+loja`, usada em `fato_devolucao_compra`) — a mesma
causa raiz, com impacto pequeno aqui (2 linhas), mas real. A chave
completa é a que evita contar a mesma nota duas vezes quando o número de
documento se repete entre fornecedores diferentes.

## Achado: drift de bronze explica o resto da diferença

`SF1010`/`SD1010` foram carregados no bronze horas antes desta
reconciliação (durante as Fases 5–7). Repetindo o mesmo join do bronze
contra a mesma consulta rodada ao vivo agora: 33 linhas (bronze,
doc+serie) → 47 (ao vivo, doc+serie), e 31 (bronze, chave completa) → 45
(ao vivo, chave completa) — o mesmo delta de +14 nos dois casos. Isso
isola completamente a causa: são notas de devolução novas, lançadas no
Protheus depois da carga do bronze, não um defeito do modelo. O próximo
ciclo incremental por `_STAMP_` traz.

## Achado: `C7_TIPO` e `C7_MOEDA` viraram numéricos no bronze, não texto

Diferente da maioria dos campos do Protheus (que chegam como `CHAR` e
viram `text` no bronze), `SC7010.C7_TIPO` e `C7_MOEDA` foram inferidos
como `double precision` pelo pandas na carga — provavelmente porque toda
a coluna, nesta tabela, só tem dígitos sem padding. `trim_protheus()`
(que espera texto) falharia com esses dois campos; comparados/carregados
como número direto (`sc7.c7_tipo <> 1`, sem a macro).

## Achado: consultas do legado sem valor incremental, não construídas

- `fCompras` (`sqlCompras`, `fCompras.m`): espelho bruto `SF1010` x
  `SD1010` via `SELECT *`, sem nenhuma regra — o bronze já é isso.
  Redundante com o que `fato_entradas_custo` (Fase 7) e
  `fato_impostos_entrada` (Fase 5) já cobrem com filtro e propósito.
- `dFornecedor`, `dProduto`, `dForneceSE2`, `dCondPag` (`dCompras.m`):
  os campos extras de `sqlFornecedor`/`sqlProduto` (endereço, e-mail,
  parâmetros de reposição) foram **incorporados a `dim_fornecedor` e
  `dim_produto`** em vez de criar dimensões paralelas. `dCondPag` virou
  `dim_cond_pgto`, nova (flagada no inventário do legado, cap. 3, como
  usada por 4 workbooks). `dForneceSE2` é redundante com
  `dim_fornecedor`.
