/*
  Fato historico de alteracao de salario base — Protheus (SR3010).
  Grao: recno_origem.
*/

select
    f.recno_origem,
    coalesce(df.sk_funcionario, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_funcionario,
    f.filial,
    f.matricula,
    f.dt_alteracao as data_alteracao,
    f.valor,
    f._carregado_em
from {{ ref('stg_historico_salarial') }} f
left join {{ ref('dim_funcionario') }} df on df.chave_funcionario = f.filial || f.matricula
