/*
  Fato refaturamento — Protheus (SD2010, agregado por NF/produto). Sem
  cliente: o legado nao rastreia isso neste grao (agregado por
  GROUP BY, perde o item e portanto a rastreabilidade por venda).
*/

select
    f.recno_origem,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    f.dt_emissao as data_emissao,
    f.filial,
    f.nfe,
    f.serie,
    f.cfop,
    f.nf_origem_refatura,
    f.qtd,
    f.um,
    f.total,
    f.preco_unit
from {{ ref('stg_refaturamento') }} f
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
