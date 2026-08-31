/*
  Dimensao centro de custo (CTT010), conformada. Grao: cod_centro_custo.
  Flagada no inventario do legado (docs/inventario_dw_legado.md, cap. 3)
  como usada por 3+ workbooks — build unica aqui, reaproveitada por
  qualquer fato que precise (comeca com fato_lancamento_indireto).
*/

with centros as (

    select
        {{ trim_protheus('ctt_custo') }}   as cod_centro_custo,
        {{ trim_protheus('ctt_desc01') }}  as descricao,
        _carregado_em
    from {{ source('bronze', 'ctt010') }}
    where d_e_l_e_t_ <> '*'

),

dedup as (

    select distinct on (cod_centro_custo)
        cod_centro_custo, descricao
    from centros
    order by cod_centro_custo, _carregado_em desc

)

select
    {{ dbt_utils.generate_surrogate_key(['cod_centro_custo']) }} as sk_centro_custo,
    cod_centro_custo,
    descricao
from dedup

union all

select
    {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }},
    'NAO_IDENTIFICADO', 'Centro de custo não identificado'
