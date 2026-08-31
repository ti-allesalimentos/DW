/*
  Fato descontos obtidos de fornecedores — Protheus (SE2010).
  Grao: recno_origem.
*/

select
    f.recno_origem,
    coalesce(df.sk_fornecedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_fornecedor,
    coalesce(dn.sk_natureza, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_natureza,
    f.dt_emissao as data_emissao,
    f.valor,
    f._carregado_em
from {{ ref('stg_descontos_obtidos') }} f
left join {{ ref('dim_fornecedor') }} df on df.chave_fornecedor = f.chave_fornecedor
left join {{ ref('dim_natureza_financeira') }} dn on dn.cod_natureza = f.cod_natureza
