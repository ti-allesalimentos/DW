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
    -- Comissao PREVISTA pela hierarquia do Protheus (item > pedido >
    -- cliente > cadastro, com flags X_COMI) -- ver stg_faturamento.sql. A
    -- efetivada so existe na baixa do titulo (fato_comissao). Percentual
    -- sobre o bruto da linha. sk_vendedor_comissao e o vendedor da
    -- comissao (C5_VEND1, fallback A1_VEND), que pode diferir de sk_vendedor
    -- (A1_VEND, usado nas analises de venda).
    coalesce(dvc.sk_vendedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_vendedor_comissao,
    coalesce(dpf.sk_vendedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_pf,
    f.perc_comissao_vendedor,
    f.total * f.perc_comissao_vendedor as vr_comissao_vendedor,
    f.origem_comissao_vendedor,
    f.perc_comissao_gerente,
    f.total * f.perc_comissao_gerente as vr_comissao_gerente,
    f.origem_comissao_gerente,
    f.perc_comissao_pf,
    f.total * f.perc_comissao_pf as vr_comissao_pf,
    f.cod_tabela_pedido,
    coalesce(dtp_uf.preco_unit, dtp_geral.preco_unit) as preco_tabela,
    f.preco_unit - coalesce(dtp_uf.preco_unit, dtp_geral.preco_unit) as desvio_preco_valor,
    case when coalesce(dtp_uf.preco_unit, dtp_geral.preco_unit) > 0
         then (f.preco_unit - coalesce(dtp_uf.preco_unit, dtp_geral.preco_unit))
              / coalesce(dtp_uf.preco_unit, dtp_geral.preco_unit)
    end as desvio_preco_pct,
    f._carregado_em
from {{ ref('stg_faturamento') }} f
left join {{ ref('dim_cliente') }} dc on dc.chave_cliente = f.chave_cliente
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
left join {{ ref('dim_vendedor') }} dv on dv.cod_vendedor = f.cod_vendedor
-- Supervisor e outro registro do mesmo cadastro de vendedores (SA3010) --
-- o cliente carrega o codigo em A1_VEND3, resolvido pela mesma dim_vendedor.
left join {{ ref('dim_vendedor') }} dsup on dsup.cod_vendedor = f.cod_supervisor
-- Gerente e Supervisor sao o mesmo papel: C5_VEND3 do pedido, com A1_VEND3
-- do cliente de fallback -- ver stg_faturamento.sql.
left join {{ ref('dim_vendedor') }} dger on dger.cod_vendedor = f.cod_gerente
left join {{ ref('dim_vendedor') }} dvc on dvc.cod_vendedor = f.cod_vendedor_comissao
left join {{ ref('dim_vendedor') }} dpf on dpf.cod_vendedor = f.cod_pf
-- DA0010/DA1010 usam uma filial "matriz" de 2 digitos (01-04), mais grossa
-- que a filial de venda do SD2010 (01001, 01003...) -- left() reproduz o
-- agrupamento. A tabela de preco so tem linha por UF quando o preco muda
-- naquele estado (742 de 803 combinacoes filial+tabela+produto tem so a
-- linha "geral", UF em branco) -- por isso o fallback: tenta a linha do
-- UF do cliente primeiro, cai pra geral se nao existir. Sem isso o match
-- ficava em 41% em vez de 95,5%.
left join {{ ref('dim_tabela_preco') }} dtp_uf
    on dtp_uf.filial = left(f.filial, 2)
   and dtp_uf.cod_tabela = f.cod_tabela_pedido
   and dtp_uf.sk_produto = dp.sk_produto
   and dtp_uf.uf = dc.uf
left join {{ ref('dim_tabela_preco') }} dtp_geral
    on dtp_geral.filial = left(f.filial, 2)
   and dtp_geral.cod_tabela = f.cod_tabela_pedido
   and dtp_geral.sk_produto = dp.sk_produto
   and (dtp_geral.uf is null or dtp_geral.uf = '')
