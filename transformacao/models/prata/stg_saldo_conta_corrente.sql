/*
  Saldo diario de conta corrente (CQ0010), conformado. Grao: filial +
  conta + data.

  Replica sqlConsulta (fFinanceiro.m) — a query real e um LEFT JOIN de
  CQ0010 contra ele mesmo pra recalcular saldo acumulado via soma de
  todo dia anterior; aqui o mesmo resultado sai direto de uma window
  function, sem o self-join.

  "VALOR_REALIZADO" do legado tem um bug real: o CASE que deveria
  devolver o modulo do movimento (`CASE WHEN MOVIMENTO<0 THEN
  -MOVIMENTO ELSE -MOVIMENTO END`) calcula -MOVIMENTO nas duas
  ramificacoes — nunca e um valor absoluto, e sim sempre
  credito-debito invertido. Replicado de proposito (ver
  docs/reconciliacao_financeiro.md); o saldo acumulado
  (valor_saldo_atual) fica correto porque as duas inversoes se
  cancelam na formula final.
*/

with diario as (

    select
        {{ trim_protheus('cq0_filial') }} as filial,
        btrim(cq0_conta)                  as codigo_conta,
        {{ data_protheus('cq0_data') }}   as data,
        sum(cq0_debito)                   as debito,
        sum(cq0_credit)                   as credito,
        sum(cq0_debito) - sum(cq0_credit) as movimento
    from {{ source('bronze', 'cq0010') }}
    where d_e_l_e_t_ <> '*'
      and {{ trim_protheus('cq0_lp') }} = 'N'
    group by 1, 2, 3

),

com_saldo as (

    select
        *,
        sum(movimento) over (
            partition by filial, codigo_conta
            order by data
            rows between unbounded preceding and current row
        ) as saldo_atual
    from diario

)

select
    filial,
    codigo_conta,
    data,
    debito,
    credito,
    movimento,
    -movimento as valor_realizado,
    saldo_atual - movimento as valor_saldo_inicial,
    saldo_atual as valor_saldo_atual
from com_saldo
