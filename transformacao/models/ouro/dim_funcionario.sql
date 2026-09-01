/*
  Dimensao funcionario (SRA010), conformada. Grao: chave_funcionario
  (filial || matricula). Replica sqldFuncionarios
  (fGestaoPessoas.m), com duas colunas convertidas de texto pra
  numerico (o legado guarda percentual como string) — periculosidade
  e insalubridade sao valores calculaveis, nao rotulos.
*/

with funcionarios as (

    select
        {{ trim_protheus('ra_filial') }}   as filial,
        {{ trim_protheus('ra_mat') }}      as matricula,
        {{ trim_protheus('ra_nome') }}     as nome,
        {{ trim_protheus('ra_sexo') }}     as sexo,
        {{ data_protheus('ra_nasc') }}     as dt_nascimento,
        {{ data_protheus('ra_admissa') }}  as dt_admissao,
        {{ data_protheus('ra_demissa') }}  as dt_demissao,
        {{ trim_protheus('ra_sitfolh') }}  as situacao,
        {{ trim_protheus('ra_cc') }}       as cod_centro_custo,
        {{ trim_protheus('ra_codfunc') }}  as cod_funcao,
        ra_salario                           as salario,
        ra_hrsmes                            as hr_jornada_mes,
        case when {{ trim_protheus('ra_adcperi') }} = '2' then 0.30 else 0.00 end as perc_periculosidade,
        case
            when {{ trim_protheus('ra_adcins') }} = '1' then 0.00
            when {{ trim_protheus('ra_adcins') }} = '2' then 0.10
            when {{ trim_protheus('ra_adcins') }} = '3' then 0.20
            when {{ trim_protheus('ra_adcins') }} = '4' then 0.30
        end as perc_insalubridade,
        _carregado_em
    from {{ source('bronze', 'sra010') }}
    where d_e_l_e_t_ <> '*'

),

dedup as (

    select distinct on (filial, matricula) *
    from funcionarios
    order by filial, matricula, _carregado_em desc

)

select
    {{ dbt_utils.generate_surrogate_key(['filial', 'matricula']) }} as sk_funcionario,
    filial || matricula as chave_funcionario,
    filial,
    matricula,
    nome,
    sexo,
    dt_nascimento,
    dt_admissao,
    dt_demissao,
    situacao,
    cod_centro_custo,
    cod_funcao,
    salario,
    hr_jornada_mes,
    perc_periculosidade,
    perc_insalubridade
from dedup

union all

select
    {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }},
    'NAO_IDENTIFICADO', null, null, 'Funcionário não identificado',
    null, null, null, null, null, null, null, null, null, null, null
