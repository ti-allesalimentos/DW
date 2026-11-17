{{
  config(
    indexes=[
      {'columns': ['data_emissao']},
      {'columns': ['sk_cliente']},
      {'columns': ['sk_produto']},
    ]
  )
}}

/*
  Agregado DIARIO de faturamento — irmao de agg_faturamento_mes, com o MESMO
  grao e a MESMA regra de Venda Real, trocando ano_mes por data_emissao:
  data_emissao x filial x sk_cliente x sk_vendedor x sk_supervisor x
  sk_gerente x sk_produto x familia.

  Existe pra comparar PERIODOS PARCIAIS (ex.: 01/11 a 17/11 contra 01/11 a
  17/11 do ano anterior — YoY do mes em andamento), coisa que o agregado
  mensal nao responde: ele so sabe o mes inteiro. Fora isso, quem nao
  precisa de recorte por dia segue no mensal (bem menor).

  Faturamento Liquido = Bruto - Devolucao - Desconto Comercial; o Acordo
  Comercial segue aqui so como coluna informativa (fora do liquido desde
  11/11/2026). Devolucao e Acordo caem na data da PROPRIA NF, nao na da
  venda original, e herdam vendedor/supervisor/gerente da venda via
  nf_origem/item_origem — igual ao mensal. Somar este modelo por mes
  reproduz agg_faturamento_mes (teste de reconciliacao no _models.yml).
*/

with vendas as (

    select
        f.filial,
        f.nfe,
        f.data_emissao,
        f.sk_cliente,
        f.sk_vendedor,
        f.sk_supervisor,
        f.sk_gerente,
        f.sk_produto,
        coalesce(p.familia, 'SEM FAMILIA') as familia,
        f.total as valor,
        f.valor_desconto_comercial,
        case when f.um = 'KG' then f.qtd else 0 end as kg
    from {{ ref('fato_faturamento') }} f
    left join {{ ref('dim_produto') }} p on p.sk_produto = f.sk_produto

),

devolucoes as (

    -- data da PROPRIA devolucao; vendedor/supervisor/gerente
    -- vem da venda original (join por nf_origem/item_origem); produto/
    -- familia vem da propria linha de devolucao.
    select
        d.data_emissao,
        d.filial,
        coalesce(vo.sk_cliente, d.sk_cliente) as sk_cliente,
        vo.sk_vendedor,
        vo.sk_supervisor,
        vo.sk_gerente,
        d.sk_produto,
        coalesce(p.familia, 'SEM FAMILIA') as familia,
        d.total as valor,
        case when d.um = 'KG' then d.qtd else 0 end as kg
    from {{ ref('fato_devolucoes') }} d
    left join {{ ref('fato_faturamento') }} vo
        on vo.filial = d.filial and vo.nfe = d.nf_origem and vo.item_nf = d.item_origem
    left join {{ ref('dim_produto') }} p on p.sk_produto = d.sk_produto

),

acordos as (

    select
        a.data_emissao,
        a.filial,
        coalesce(vo.sk_cliente, a.sk_cliente) as sk_cliente,
        vo.sk_vendedor,
        vo.sk_supervisor,
        vo.sk_gerente,
        a.sk_produto,
        coalesce(p.familia, 'SEM FAMILIA') as familia,
        a.total as valor
    from {{ ref('fato_acordo_comercial') }} a
    left join {{ ref('fato_faturamento') }} vo
        on vo.filial = a.filial and vo.nfe = a.nf_origem and vo.item_nf = a.item_origem
    left join {{ ref('dim_produto') }} p on p.sk_produto = a.sk_produto

),

agg_vendas as (
    select
        data_emissao, filial, sk_cliente, sk_vendedor, sk_supervisor, sk_gerente, sk_produto, familia,
        count(distinct nfe)                              as qtd_notas,
        round(sum(valor)::numeric, 2)                    as valor_bruto,
        round(sum(kg)::numeric, 2)                       as kg_bruto,
        round(sum(valor_desconto_comercial)::numeric, 2) as valor_desconto_comercial
    from vendas
    group by 1, 2, 3, 4, 5, 6, 7, 8
),

agg_dev as (
    select
        data_emissao, filial, sk_cliente, sk_vendedor, sk_supervisor, sk_gerente, sk_produto, familia,
        round(sum(valor)::numeric, 2) as valor_devolucao,
        round(sum(kg)::numeric, 2)    as kg_devolvido
    from devolucoes
    group by 1, 2, 3, 4, 5, 6, 7, 8
),

agg_acordo as (
    select
        data_emissao, filial, sk_cliente, sk_vendedor, sk_supervisor, sk_gerente, sk_produto, familia,
        round(sum(valor)::numeric, 2) as valor_acordo_comercial
    from acordos
    group by 1, 2, 3, 4, 5, 6, 7, 8
)

select
    coalesce(v.data_emissao, d.data_emissao, a.data_emissao)     as data_emissao,
    coalesce(v.filial, d.filial, a.filial)                       as filial,
    coalesce(v.sk_cliente, d.sk_cliente, a.sk_cliente)           as sk_cliente,
    coalesce(v.sk_vendedor, d.sk_vendedor, a.sk_vendedor)        as sk_vendedor,
    coalesce(v.sk_supervisor, d.sk_supervisor, a.sk_supervisor)  as sk_supervisor,
    coalesce(v.sk_gerente, d.sk_gerente, a.sk_gerente)           as sk_gerente,
    coalesce(v.sk_produto, d.sk_produto, a.sk_produto)           as sk_produto,
    coalesce(v.familia, d.familia, a.familia)                    as familia,
    coalesce(v.qtd_notas, 0)                                     as qtd_notas,
    coalesce(v.valor_bruto, 0)                                   as valor_bruto,
    coalesce(v.kg_bruto, 0)                                      as kg_bruto,
    coalesce(v.valor_desconto_comercial, 0)                      as valor_desconto_comercial,
    coalesce(d.valor_devolucao, 0)                                as valor_devolucao,
    coalesce(d.kg_devolvido, 0)                                   as kg_devolvido,
    coalesce(a.valor_acordo_comercial, 0)                         as valor_acordo_comercial,
    coalesce(v.valor_bruto, 0) - coalesce(d.valor_devolucao, 0)
        - coalesce(v.valor_desconto_comercial, 0)
                                                                   as valor_liquido,
    coalesce(v.kg_bruto, 0) - coalesce(d.kg_devolvido, 0)         as kg_liquido
from agg_vendas v
full outer join agg_dev d
    on d.data_emissao = v.data_emissao and d.filial = v.filial and d.sk_cliente = v.sk_cliente
   and d.sk_vendedor is not distinct from v.sk_vendedor
   and d.sk_supervisor is not distinct from v.sk_supervisor
   and d.sk_gerente is not distinct from v.sk_gerente
   and d.sk_produto is not distinct from v.sk_produto
   and d.familia = v.familia
full outer join agg_acordo a
    on a.data_emissao = coalesce(v.data_emissao, d.data_emissao)
   and a.filial = coalesce(v.filial, d.filial)
   and a.sk_cliente = coalesce(v.sk_cliente, d.sk_cliente)
   and a.sk_vendedor is not distinct from coalesce(v.sk_vendedor, d.sk_vendedor)
   and a.sk_supervisor is not distinct from coalesce(v.sk_supervisor, d.sk_supervisor)
   and a.sk_gerente is not distinct from coalesce(v.sk_gerente, d.sk_gerente)
   and a.sk_produto is not distinct from coalesce(v.sk_produto, d.sk_produto)
   and a.familia = coalesce(v.familia, d.familia)
