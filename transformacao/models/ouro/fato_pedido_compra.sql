/*
  Fato pedido de compra — Protheus (SC7010). Grao: recno_origem.
*/

select
    f.recno_origem,
    coalesce(df.sk_fornecedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_fornecedor,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    coalesce(dc.sk_cond_pgto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_cond_pgto,
    f.filial,
    f.pedido,
    f.item,
    f.unidade,
    f.quantidade,
    f.qtd_entregue,
    f.valor_unitario,
    f.valor_total,
    f.status_encerramento,
    f.status_pedido,
    f.comprador,
    f.solicitacao,
    f.solicitante,
    f.dt_emissao as data_emissao,
    f.dt_inicio_compra as data_inicio_compra,
    f.dt_inicio_transito as data_inicio_transito,
    f.dt_entregue as data_entregue,
    f.residuo,
    f.cod_aprovacao,
    f.centro_resultado,
    f._carregado_em
from {{ ref('stg_pedido_compra') }} f
left join {{ ref('dim_fornecedor') }} df on df.chave_fornecedor = f.chave_fornecedor
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
left join {{ ref('dim_cond_pgto') }} dc on dc.cod_cond_pgto = f.cod_cond_pgto
