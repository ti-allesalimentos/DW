/*
  Fato tributo por item de NF de saida, formato normalizado —
  Protheus (SD2010 x F2D010/F2B010). Grao: sk_linha.
*/

select
    f.sk_linha,
    f.recno_sd2,
    f.recno_f2d,
    f.filial,
    f.tipo_mov,
    f.dt_emissao as data_emissao,
    f.nfe,
    f.serie,
    coalesce(dc.sk_cliente, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_cliente,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    f.cfop,
    f.tributo,
    f.cod_tributo,
    f.descricao_tributo,
    f.base_tributo,
    f.aliq_tributo,
    f.valor_tributo,
    f._carregado_em
from {{ ref('stg_impostos_saida') }} f
left join {{ ref('dim_cliente') }} dc on dc.chave_cliente = f.chave_cliente
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
