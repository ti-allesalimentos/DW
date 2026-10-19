{{
  config(
    materialized='incremental',
    incremental_strategy='append',
    pre_hook="{% if is_incremental() %}delete from {{ this }} where data_emissao >= current_date - interval '60 days'{% endif %}",
    indexes=[
      {'columns': ['data_emissao']},
      {'columns': ['recno_origem'], 'unique': True},
    ]
  )
}}

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

{% if is_incremental() %}
where f.dt_emissao >= current_date - interval '60 days'
{% endif %}
