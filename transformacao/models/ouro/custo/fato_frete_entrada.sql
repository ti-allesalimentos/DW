/*
  Fato frete rateado em NF de entrada — Protheus (GWM010, tipo doc
  '1'). Grao: filial+nf+item+serie+fornecedor.
*/

with base as (

    select
        *,
        {{ dbt_utils.generate_surrogate_key(['filial', 'nfe', 'item', 'serie', 'chave_fornecedor']) }} as sk_frete_entrada
    from {{ ref('stg_frete_entrada') }}

)

select
    f.sk_frete_entrada,
    f.filial,
    f.nfe,
    f.item,
    f.serie,
    coalesce(df.sk_fornecedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_fornecedor,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    f.dt_emissao as data_emissao,
    f.um,
    f.qtd,
    f.vr_unitario,
    f.vr_total,
    f.vr_frete,
    f.percentual
from base f
left join {{ ref('dim_fornecedor') }} df on df.chave_fornecedor = f.chave_fornecedor
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
