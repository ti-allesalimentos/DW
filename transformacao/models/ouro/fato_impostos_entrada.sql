/*
  Fato tributo por item de NF de entrada, formato normalizado —
  Protheus (SD1010 x F2D010/F2B010). Grao: sk_linha.
*/

select
    f.sk_linha,
    f.recno_sd1,
    f.recno_f2d,
    f.filial,
    f.tipo_mov,
    f.dt_entrada as data_entrada,
    f.dt_emissao as data_emissao,
    f.nfe,
    f.serie,
    coalesce(df.sk_fornecedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_fornecedor,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    f.cfop,
    f.tes,
    f.pedido,
    f.tributo,
    f.cod_tributo,
    f.descricao_tributo,
    f.base_tributo,
    f.aliq_tributo,
    f.valor_tributo,
    f._carregado_em
from {{ ref('stg_impostos_entrada') }} f
left join {{ ref('dim_fornecedor') }} df on df.chave_fornecedor = f.chave_fornecedor
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
