/*
  Fato pedidos — Protheus (SC9010, liberacao/embarque). Grao: pedido +
  cliente + produto + item + sequencia.

  Gerente resolvido contra a mesma dim_vendedor (SA3010 nao distingue
  vendedor de gerente por tabela, so por papel no pedido).
*/

select
    f.recno_origem,
    coalesce(dc.sk_cliente, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_cliente,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    coalesce(dv.sk_vendedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_vendedor,
    coalesce(dg.sk_vendedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_gerente,
    f.dt_emissao_pedido as data_emissao_pedido,
    f.dt_emissao_nf as data_emissao_nf,
    f.dt_embarque as data_embarque,
    f.filial,
    f.pedido,
    f.item,
    f.sequen,
    f.tipo_entrega,
    f.tes,
    f.local_armazem,
    f.nfe,
    f.serie,
    f.carga,
    f.qtd,
    f.preco_unit,
    f.total,
    f.peso_bruto,
    f._carregado_em
from {{ ref('stg_pedidos') }} f
left join {{ ref('dim_cliente') }} dc on dc.chave_cliente = f.chave_cliente
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
left join {{ ref('dim_vendedor') }} dv on dv.cod_vendedor = f.cod_vendedor
left join {{ ref('dim_vendedor') }} dg on dg.cod_vendedor = f.cod_gerente
