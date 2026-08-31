/*
  Fato contas a pagar — Protheus (SE2010). Grao: titulo/parcela. Exclui
  tipos FT/NDF/PA/PRE (ver nota em stg_contas_apagar.sql).
*/

select
    f.recno_origem,
    coalesce(df.sk_fornecedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_fornecedor,
    coalesce(dn.sk_natureza, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_natureza,
    f.filial,
    f.prefixo,
    f.titulo,
    f.parcela,
    f.tipo,
    f.dt_emissao as data_emissao,
    f.dt_vencimento_real as data_vencimento_real,
    f.renegociado,
    f.juros,
    f.valor_liquido,
    f.dt_baixa as data_baixa,
    f.forma_pagamento,
    f.valor,
    f.saldo,
    f.prioridade,
    f.situacao,
    f.decrescimo,
    f.fatura,
    f.liquidacao,
    f._carregado_em
from {{ ref('stg_contas_apagar') }} f
left join {{ ref('dim_fornecedor') }} df on df.chave_fornecedor = f.chave_fornecedor
left join {{ ref('dim_natureza_financeira') }} dn on dn.cod_natureza = f.cod_natureza
