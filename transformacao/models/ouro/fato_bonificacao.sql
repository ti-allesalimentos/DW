/*
  Fato bonificacao — Protheus (SD2010, CFOP de bonificacao/amostra
  gratis). Grao: item de nota fiscal. Mesmas dimensoes conformadas do
  fato_faturamento.
*/

select
    f.recno_origem,
    coalesce(dc.sk_cliente, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_cliente,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    coalesce(dv.sk_vendedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_vendedor,
    f.dt_emissao as data_emissao,
    f.filial,
    f.nfe,
    f.serie,
    f.item_nf,
    f.cfop,
    f.qtd,
    f.um,
    f.total,
    f.preco_unit,
    f._carregado_em
from {{ ref('stg_bonificacao') }} f
left join {{ ref('dim_cliente') }} dc on dc.chave_cliente = f.chave_cliente
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
left join {{ ref('dim_vendedor') }} dv on dv.cod_vendedor = f.cod_vendedor
