/*
  Agregado mensal de faturamento — grao: ano_mes x filial x familia x vendedor.

  Serve o portal do Oryon Board (area Faturamento & Comercial): a Visao
  Executiva le agregados pra responder em milissegundos, igual ao padrao ja
  usado no projeto Alimentare (ouro.agg_faturamento_mes_filial) — sem isso,
  cada card do portal recalcularia o netting de devolucao linha a linha a
  cada request.

  Venda Real = mesma regra canonica do resto do DW (Fase 12): total da nota
  MENOS a devolucao vinculada pela NF de origem (join fato_faturamento x
  fato_devolucoes por filial+nfe/nf_origem+item_nf/item_origem). Ver
  memoria "fase12-decisoes-fonte-faturamento" — nao expor uma variante bruta
  com nome parecido.

  Margem fica de fora de proposito — decisao de escopo da Fase 12, ainda nao
  ha custo real apurado pra sustentar isso.
*/

with fat as (

    select
        f.recno_origem,
        f.filial,
        f.nfe,
        f.item_nf,
        to_char(f.data_emissao, 'YYYY-MM') as ano_mes,
        f.sk_cliente,
        f.sk_vendedor,
        coalesce(p.familia, 'SEM FAMILIA') as familia,
        f.total as valor,
        case when f.um = 'KG' then f.qtd else 0 end as kg
    from {{ ref('fato_faturamento') }} f
    left join {{ ref('dim_produto') }} p on p.sk_produto = f.sk_produto

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
        fat.familia,
        fat.sk_vendedor,
        fat.sk_cliente,
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
    familia,
    sk_vendedor,
    count(distinct sk_cliente)                as qtd_clientes,
    count(distinct nfe)                       as qtd_notas,
    round(sum(valor_bruto)::numeric, 2)       as valor_bruto,
    round(sum(valor_devolucao)::numeric, 2)   as valor_devolucao,
    round(sum(valor_liquido)::numeric, 2)     as valor_liquido,
    round(sum(kg_liquido)::numeric, 2)        as kg_liquido
from liquido
group by 1, 2, 3, 4
