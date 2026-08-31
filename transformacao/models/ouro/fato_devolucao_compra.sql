/*
  Fato devolucao em nota de entrada — Protheus (SF1010+SD1010, tipo
  'D'). Grao: recno_origem.
*/

select
    f.recno_origem,
    coalesce(df.sk_fornecedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_fornecedor,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    f.filial,
    f.nfe,
    f.serie,
    f.item,
    f.valor_total,
    f.dt_emissao as data_emissao,
    f._carregado_em
from {{ ref('stg_devolucao_compra') }} f
left join {{ ref('dim_fornecedor') }} df on df.chave_fornecedor = f.chave_fornecedor
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
