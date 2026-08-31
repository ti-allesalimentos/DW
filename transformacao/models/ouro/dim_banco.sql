/*
  Dimensao banco/conta corrente cadastrada (SA6010). Grao: cod_banco.
*/

with bancos as (

    select
        {{ trim_protheus('a6_cod') }}     as cod_banco,
        {{ trim_protheus('a6_agencia') }} as agencia,
        {{ trim_protheus('a6_numcon') }}  as conta,
        {{ trim_protheus('a6_nome') }}    as nome,
        {{ trim_protheus('a6_filial') }}  as filial,
        _carregado_em
    from {{ source('bronze', 'sa6010') }}
    where d_e_l_e_t_ <> '*'

),

dedup as (

    select distinct on (cod_banco)
        cod_banco, agencia, conta, nome, filial
    from bancos
    order by cod_banco, _carregado_em desc

)

select
    {{ dbt_utils.generate_surrogate_key(['cod_banco']) }} as sk_banco,
    cod_banco,
    agencia,
    conta,
    nome,
    filial
from dedup

union all

select
    {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }},
    'NAO_IDENTIFICADO', null, null, 'Banco não identificado', null
