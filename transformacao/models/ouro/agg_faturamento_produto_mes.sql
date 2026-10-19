{{
  config(
    indexes=[
      {'columns': ['ano_mes']},
      {'columns': ['sk_produto']},
    ]
  )
}}

/*
  Agregado mensal de faturamento por produto — grao: ano_mes x filial x
  sk_produto.

  Irmao de agg_faturamento_mes/agg_faturamento_cliente_mes, com a MESMA
  regra de Venda Real: Liquido = Bruto - Devolucao - Desconto Comercial -
  Acordo Comercial (decisao de 29/09/2026). Devolucao e Acordo caem no mes
  da PROPRIA NF, no produto da propria linha. Serve a abertura por produto
  da Analise Detalhada do portal.
*/

with eventos as (

    select
        to_char(f.data_emissao, 'YYYY-MM')              as ano_mes,
        f.filial,
        f.sk_produto,
        f.nfe,
        f.total                                         as valor_bruto,
        case when f.um = 'KG' then f.qtd else 0 end     as kg_bruto,
        f.valor_desconto_comercial                      as valor_desconto,
        0::double precision                             as valor_devolucao,
        0::double precision                             as kg_devolvido,
        0::double precision                             as valor_acordo
    from {{ ref('fato_faturamento') }} f

    union all

    select
        to_char(d.data_emissao, 'YYYY-MM'),
        d.filial,
        d.sk_produto,
        null,
        0, 0, 0,
        d.total,
        case when d.um = 'KG' then d.qtd else 0 end,
        0
    from {{ ref('fato_devolucoes') }} d

    union all

    select
        to_char(a.data_emissao, 'YYYY-MM'),
        a.filial,
        a.sk_produto,
        null,
        0, 0, 0, 0, 0,
        a.total
    from {{ ref('fato_acordo_comercial') }} a

)

select
    ano_mes,
    filial,
    sk_produto,
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
group by 1, 2, 3
