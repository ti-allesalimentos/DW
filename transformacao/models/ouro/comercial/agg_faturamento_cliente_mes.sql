{{
  config(
    indexes=[
      {'columns': ['ano_mes']},
      {'columns': ['sk_cliente']},
    ]
  )
}}

/*
  Agregado mensal de faturamento por cliente — grao: ano_mes x filial x
  sk_cliente x familia.

  Irmao de agg_faturamento_mes, com a MESMA regra de Venda Real:
  Liquido = Bruto - Devolucao - Desconto Comercial - Acordo Comercial
  (decisao de 29/09/2026). Devolucao e Acordo caem no mes da PROPRIA NF e
  herdam cliente (quando a origem e achada) via nf_origem/item_origem; a
  familia vem do produto da propria linha de devolucao/acordo.

  Existe pras telas que precisam abrir por cliente em vez de colapsar tudo
  num total — Analise Detalhada (ranking por cliente), Positivacao e
  Carteira (cliente comprou ou nao em cada mes) e Curva ABC e Mix
  (concentracao de clientes). Cardinalidade bem maior que
  agg_faturamento_mes, por isso um modelo separado.
*/

with eventos as (

    -- venda
    select
        to_char(f.data_emissao, 'YYYY-MM')              as ano_mes,
        f.filial,
        f.sk_cliente,
        coalesce(p.familia, 'SEM FAMILIA')              as familia,
        f.nfe,
        f.total                                         as valor_bruto,
        case when f.um = 'KG' then f.qtd else 0 end     as kg_bruto,
        f.valor_desconto_comercial                      as valor_desconto,
        0::double precision                             as valor_devolucao,
        0::double precision                             as kg_devolvido,
        0::double precision                             as valor_acordo
    from {{ ref('fato_faturamento') }} f
    left join {{ ref('dim_produto') }} p on p.sk_produto = f.sk_produto

    union all

    -- devolucao, no mes da propria devolucao
    select
        to_char(d.data_emissao, 'YYYY-MM'),
        d.filial,
        coalesce(vo.sk_cliente, d.sk_cliente),
        coalesce(p.familia, 'SEM FAMILIA'),
        null,
        0, 0, 0,
        d.total,
        case when d.um = 'KG' then d.qtd else 0 end,
        0
    from {{ ref('fato_devolucoes') }} d
    left join {{ ref('fato_faturamento') }} vo
        on vo.filial = d.filial and vo.nfe = d.nf_origem and vo.item_nf = d.item_origem
    left join {{ ref('dim_produto') }} p on p.sk_produto = d.sk_produto

    union all

    -- acordo comercial, no mes da propria NF de entrada
    select
        to_char(a.data_emissao, 'YYYY-MM'),
        a.filial,
        coalesce(vo.sk_cliente, a.sk_cliente),
        coalesce(p.familia, 'SEM FAMILIA'),
        null,
        0, 0, 0, 0, 0,
        a.total
    from {{ ref('fato_acordo_comercial') }} a
    left join {{ ref('fato_faturamento') }} vo
        on vo.filial = a.filial and vo.nfe = a.nf_origem and vo.item_nf = a.item_origem
    left join {{ ref('dim_produto') }} p on p.sk_produto = a.sk_produto

)

select
    ano_mes,
    filial,
    sk_cliente,
    familia,
    count(distinct nfe)                                         as qtd_notas,
    round(sum(valor_bruto)::numeric, 2)                         as valor_bruto,
    round(sum(valor_devolucao)::numeric, 2)                     as valor_devolucao,
    round(sum(valor_desconto)::numeric, 2)                      as valor_desconto_comercial,
    round(sum(valor_acordo)::numeric, 2)                        as valor_acordo_comercial,
    round((sum(valor_bruto) - sum(valor_devolucao) - sum(valor_desconto) - sum(valor_acordo))::numeric, 2)
                                                                as valor_liquido,
    round(sum(kg_bruto)::numeric, 2)                            as kg_bruto,
    round(sum(kg_devolvido)::numeric, 2)                        as kg_devolvido,
    round((sum(kg_bruto) - sum(kg_devolvido))::numeric, 2)      as kg_liquido
from eventos
group by 1, 2, 3, 4
