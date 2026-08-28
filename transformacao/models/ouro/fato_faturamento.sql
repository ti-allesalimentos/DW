/*
  Fato faturamento — Protheus (SD2010), grao: item de nota fiscal de saida.

  Junta stg_faturamento as dimensoes conformadas por chave de negocio e
  resolve pra "nao identificado" quando a chave nao aparece na dimensao
  (mesmo hash que a dimensao gera pra esse membro — ver dim_*.sql).
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
    f.num_pedido,
    f.qtd,
    f.um,
    f.total,
    f.preco_unit,
    f.desconto_zfr,
    f.aliq_icms,
    f.aliq_pis,
    f.aliq_cofins,
    f.aliq_icmsst,
    f._carregado_em
from {{ ref('stg_faturamento') }} f
left join {{ ref('dim_cliente') }} dc on dc.chave_cliente = f.chave_cliente
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
left join {{ ref('dim_vendedor') }} dv on dv.cod_vendedor = f.cod_vendedor
