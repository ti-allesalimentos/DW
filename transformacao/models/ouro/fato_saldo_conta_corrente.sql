/*
  Fato saldo diario de conta corrente — Protheus (CQ0010). Grao:
  filial + conta + data.
*/

select
    f.filial,
    f.codigo_conta,
    coalesce(dc.sk_conta_contabil, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_conta_contabil,
    f.data,
    f.debito,
    f.credito,
    f.movimento,
    f.valor_realizado,
    f.valor_saldo_inicial,
    f.valor_saldo_atual
from {{ ref('stg_saldo_conta_corrente') }} f
left join {{ ref('dim_conta_contabil') }} dc on dc.codigo_conta = f.codigo_conta
