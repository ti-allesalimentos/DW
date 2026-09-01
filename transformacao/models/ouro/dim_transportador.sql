/*
  Dimensao transportador (GU3010), conformada. Grao: cod_transportador.
*/

with transportadores as (

    select
        {{ trim_protheus('gu3_cdemit') }} as cod_transportador,
        {{ trim_protheus('gu3_nmemit') }} as nome,
        {{ trim_protheus('gu3_nmfan') }}  as nome_fantasia,
        {{ trim_protheus('gu3_idfed') }}  as cnpj,
        _carregado_em
    from {{ source('bronze', 'gu3010') }}
    where d_e_l_e_t_ <> '*'

),

dedup as (

    select distinct on (cod_transportador)
        cod_transportador, nome, nome_fantasia, cnpj
    from transportadores
    order by cod_transportador, _carregado_em desc

)

select
    {{ dbt_utils.generate_surrogate_key(['cod_transportador']) }} as sk_transportador,
    cod_transportador,
    nome,
    nome_fantasia,
    cnpj
from dedup

union all

select
    {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }},
    'NAO_IDENTIFICADO', 'Transportador não identificado', null, null
