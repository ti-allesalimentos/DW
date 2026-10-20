/*
  Dimensao motivo de baixa de titulo (F7G010). Grao: sigla.
*/

with motivos as (

    select
        {{ trim_protheus('f7g_sigla') }}   as sigla,
        {{ trim_protheus('f7g_descri') }}  as descricao,
        _carregado_em
    from {{ source('bronze', 'f7g010') }}
    where d_e_l_e_t_ <> '*'

),

dedup as (

    select distinct on (sigla)
        sigla, descricao
    from motivos
    order by sigla, _carregado_em desc

)

select
    {{ dbt_utils.generate_surrogate_key(['sigla']) }} as sk_motivo_baixa,
    sigla,
    descricao
from dedup

union all

select
    {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }},
    'NAO_IDENTIFICADO', 'Motivo não identificado'
