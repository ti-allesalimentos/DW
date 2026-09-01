/*
  Fato dupla funcao ativa — Protheus (RG1010). Grao: recno_origem.
*/

select
    f.recno_origem,
    coalesce(df.sk_funcionario, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_funcionario,
    f.filial,
    f.matricula,
    f._carregado_em
from {{ ref('stg_dupla_funcao') }} f
left join {{ ref('dim_funcionario') }} df on df.chave_funcionario = f.filial || f.matricula
