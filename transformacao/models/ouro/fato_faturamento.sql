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
    coalesce(dsup.sk_vendedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_supervisor,
    coalesce(dger.sk_vendedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_gerente,
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
    f.cod_condpgto,
    f.perc_desconto_condpgto,
    f.perc_desconto_condespecial,
    f.valor_desconto_comercial,
    -- Comissao prevista no pedido (C5_COMIS1/C5_COMIS3), NAO a efetivada --
    -- a comissao real so existe na baixa do titulo (fato_comissao), sem
    -- vinculo com NF/item. Decisao do Lucas (01/10): usar a previsao do
    -- pedido sobre o bruto da linha pra exibir na Analise Detalhada.
    f.perc_comissao_vendedor,
    f.total * f.perc_comissao_vendedor as vr_comissao_vendedor,
    f.perc_comissao_gerente,
    f.total * f.perc_comissao_gerente as vr_comissao_gerente,
    f._carregado_em
from {{ ref('stg_faturamento') }} f
left join {{ ref('dim_cliente') }} dc on dc.chave_cliente = f.chave_cliente
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
left join {{ ref('dim_vendedor') }} dv on dv.cod_vendedor = f.cod_vendedor
-- Supervisor e outro registro do mesmo cadastro de vendedores (SA3010) --
-- o cliente carrega o codigo em A1_VEND3, resolvido pela mesma dim_vendedor.
left join {{ ref('dim_vendedor') }} dsup on dsup.cod_vendedor = f.cod_supervisor
-- Gerente tambem e um registro do SA3010, mas vem do PEDIDO (C5_VEND3),
-- nao do cadastro do cliente -- ver sc5010_dedup em stg_faturamento.sql.
left join {{ ref('dim_vendedor') }} dger on dger.cod_vendedor = f.cod_gerente
