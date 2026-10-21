/*
  Fato motivo de rescisao com valor pago — Protheus (SRG010+SRR010).
  Grao: filial+matricula+cod_motivo+data_demissao.
*/

with base as (

    select
        *,
        {{ dbt_utils.generate_surrogate_key(['filial', 'matricula', 'cod_motivo', 'dt_demissao']) }} as sk_rescisao
    from {{ ref('stg_motivo_rescisao') }}

)

select
    f.sk_rescisao,
    coalesce(df.sk_funcionario, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_funcionario,
    f.filial,
    f.matricula,
    f.cod_motivo,
    f.motivo,
    f.dt_demissao as data_demissao,
    f.valor
from base f
left join {{ ref('dim_funcionario') }} df on df.chave_funcionario = f.filial || f.matricula
