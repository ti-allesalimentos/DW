/*
  Fato CT-e, lado financeiro — Protheus (SE2010+SA2010). Grao:
  recno_origem.
*/

select
    f.recno_origem,
    coalesce(df.sk_fornecedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_fornecedor,
    f.numero_cte,
    f.valor,
    f.dt_emissao as data_emissao,
    f.dt_baixa as data_baixa,
    f.status_baixa,
    f._carregado_em
from {{ ref('stg_cte_financeiro') }} f
left join {{ ref('dim_fornecedor') }} df on df.chave_fornecedor = f.chave_fornecedor
