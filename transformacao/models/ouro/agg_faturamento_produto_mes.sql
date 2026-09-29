/*
  Agregado mensal de faturamento por produto — grao: ano_mes x filial x
  sk_produto.

  Irmao de agg_faturamento_mes/agg_faturamento_cliente_mes (mesma regra de
  Venda Real, mesmo netting contra fato_devolucoes): serve a abertura por
  produto da Analise Detalhada do portal.
*/

with fat as (

    select
        f.recno_origem,
        f.filial,
        f.nfe,
        f.item_nf,
        to_char(f.data_emissao, 'YYYY-MM') as ano_mes,
        f.sk_produto,
        f.total as valor,
        case when f.um = 'KG' then f.qtd else 0 end as kg
    from {{ ref('fato_faturamento') }} f

),

dev as (

    select
        d.filial,
        d.nf_origem as nfe,
        d.item_origem as item_nf,
        d.total as valor_dev,
        case when d.um = 'KG' then d.qtd else 0 end as kg_dev
    from {{ ref('fato_devolucoes') }} d

),

liquido as (

    select
        fat.ano_mes,
        fat.filial,
        fat.sk_produto,
        fat.nfe,
        fat.valor                              as valor_bruto,
        coalesce(dev.valor_dev, 0)             as valor_devolucao,
        fat.valor - coalesce(dev.valor_dev, 0) as valor_liquido,
        fat.kg - coalesce(dev.kg_dev, 0)       as kg_liquido
    from fat
    left join dev
        on dev.filial = fat.filial
       and dev.nfe = fat.nfe
       and dev.item_nf = fat.item_nf

)

select
    ano_mes,
    filial,
    sk_produto,
    count(distinct nfe)                       as qtd_notas,
    round(sum(valor_bruto)::numeric, 2)       as valor_bruto,
    round(sum(valor_devolucao)::numeric, 2)   as valor_devolucao,
    round(sum(valor_liquido)::numeric, 2)     as valor_liquido,
    round(sum(kg_liquido)::numeric, 2)        as kg_liquido
from liquido
group by 1, 2, 3
