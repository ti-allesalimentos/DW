/*
  Fato tributo por NF — Protheus (SFT010). Grao: recno_origem.

  cod_cliefor pode ser cliente ou fornecedor (FT_CLIEFOR nao distingue
  por tabela); os dois joins abaixo caem em NAO_IDENTIFICADO quando nao
  se aplicam, entao uma nota de saida sempre resolve por dim_cliente e
  uma de entrada por dim_fornecedor.
*/

select
    f.recno_origem,
    f.filial,
    f.tipo_mov,
    f.tipo_lancamento,
    f.dt_entrada as data_entrada,
    f.dt_emissao as data_emissao,
    f.especie,
    f.nfe,
    f.serie,
    coalesce(dc.sk_cliente, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_cliente,
    coalesce(df.sk_fornecedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_fornecedor,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    f.cfop,
    f.cod_servico_iss,
    f.cod_ncm,
    f.valor_contabil,
    f.valor_total,
    f.sit_trib_icms,
    f.aliq_icms,
    f.base_icms,
    f.valor_icms,
    f.valor_isento_icms,
    f.valor_outro_icms,
    f.sit_trib_ipi,
    f.base_ipi,
    f.aliq_ipi,
    f.valor_ipi,
    f.valor_isento_ipi,
    f.valor_outro_ipi,
    f.base_icms_st,
    f.aliq_icms_st,
    f.valor_icms_st,
    f.valor_icms_diferido,
    f.cst_pis,
    f.base_pis,
    f.aliq_pis,
    f.valor_pis,
    f.cst_cofins,
    f.base_cofins,
    f.aliq_cofins,
    f.valor_cofins,
    f.base_irrf,
    f.aliq_irrf,
    f.valor_irrf,
    f.base_inss,
    f.aliq_inss,
    f.valor_inss,
    f.base_pis_retido,
    f.aliq_pis_retido,
    f.valor_pis_retido,
    f.base_cofins_retido,
    f.aliq_cofins_retido,
    f.valor_cofins_retido,
    f.base_csll_retido,
    f.aliq_csll_retido,
    f.valor_csll_retido,
    f.base_iss,
    f.aliq_iss,
    f.valor_iss,
    f._carregado_em
from {{ ref('stg_tributo_nf') }} f
left join {{ ref('dim_cliente') }} dc on dc.chave_cliente = f.chave_cliefor
left join {{ ref('dim_fornecedor') }} df on df.chave_fornecedor = f.chave_cliefor
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
