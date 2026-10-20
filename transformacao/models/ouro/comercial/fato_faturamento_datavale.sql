/*
  Fato faturamento — historico DATAVALE (ERP anterior, 02/2024 a 01/2025).

  Mantido separado de fato_faturamento por decisao explicita: os graos
  nao sao iguais (aqui nao ha CFOP, serie/item de NF nem impostos por
  linha) — unificar os dois num fato so fica para quando o grao comum
  for definido. Ate la, convivem lado a lado no ouro, ambos ligados as
  mesmas dimensoes conformadas (dim_cliente, dim_produto, dim_vendedor,
  dim_calendario).
*/

select
    f.seq_nota_fiscal,
    coalesce(dc.sk_cliente, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_cliente,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    coalesce(dv.sk_vendedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_vendedor,
    f.dt_emissao as data_emissao,
    f.filial,
    f.qtd,
    f.um,
    f.preco_unit,
    f.total
from {{ ref('stg_faturamento_datavale') }} f
left join {{ ref('dim_cliente') }} dc on dc.chave_cliente = f.chave_cliente
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
left join {{ ref('dim_vendedor') }} dv on dv.cod_vendedor = f.cod_vendedor
