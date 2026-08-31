/*
  Fato historico de preco de compra por produto — Protheus (SC7010).
  Grao: recno_origem.
*/

select
    f.recno_origem,
    coalesce(df.sk_fornecedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_fornecedor,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    coalesce(dc.sk_cond_pgto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_cond_pgto,
    f.filial,
    f.pedido,
    f.item,
    f.dt_emissao as data_emissao,
    f.status_pedido,
    f.qtd_pedida,
    f.qtd_entregue,
    f.qtd_compras_produto,
    f.cod_moeda,
    f.preco_unit,
    f.valor_total,
    f.preco_unit_calc,
    f.preco_anterior,
    f.var_pct_vs_anterior,
    f.preco_medio_hist,
    f.desvio_pct_vs_media,
    f.comprador,
    f.solicitacao,
    f.item_solicitacao,
    f.solicitante,
    f.dt_inicio_compra as data_inicio_compra,
    f.dt_inicio_transito as data_inicio_transito,
    f.dt_prevista as data_prevista,
    f.qtd_recebida_nf,
    f.valor_recebido_nf,
    f.preco_unit_nf,
    f.qtde_notas,
    f.ultima_entrada as data_ultima_entrada,
    f._carregado_em
from {{ ref('stg_historico_preco_compra') }} f
left join {{ ref('dim_fornecedor') }} df on df.chave_fornecedor = f.chave_fornecedor
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
left join {{ ref('dim_cond_pgto') }} dc on dc.cod_cond_pgto = f.cod_cond_pgto
