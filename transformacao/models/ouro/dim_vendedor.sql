/*
  Dimensao vendedor, conformada. Grao: cod_vendedor.

  O SA3010 tem o mesmo codigo gravado com padding inconsistente em
  historico (ex.: "000004" e "4"); normaliza-se pelo valor numerico antes
  de deduplicar, senao o mesmo vendedor vira duas linhas na dimensao.
*/

with vendedores as (

    select
        btrim(a3_cod)                    as cod_vendedor,
        {{ trim_protheus('a3_nome') }}   as nome,
        {{ trim_protheus('a3_nreduz') }} as nome_reduzido,
        {{ trim_protheus('a3_filial') }} as filial,
        {{ trim_protheus('a3_est') }}    as uf,
        _carregado_em
    from {{ source('bronze', 'sa3010') }}
    where d_e_l_e_t_ <> '*'
      and a3_cod ~ '^\d+$'

),

dedup as (

    -- distinct on pelo valor numerico do codigo, nao pelo texto —
    -- "000004" e "4" sao o mesmo vendedor.
    select distinct on (cod_vendedor::int)
        cod_vendedor, nome, nome_reduzido, filial, uf
    from vendedores
    order by cod_vendedor::int, _carregado_em desc

)

select
    {{ dbt_utils.generate_surrogate_key(['cod_vendedor']) }} as sk_vendedor,
    cod_vendedor,
    nome,
    nome_reduzido,
    filial,
    uf
from dedup

union all

select
    {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }},
    'NAO_IDENTIFICADO', 'Vendedor não identificado', null, null, null
