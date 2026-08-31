/*
  Dimensao condicao de pagamento (SE4010), conformada. Grao:
  cod_cond_pgto. Flagada no inventario do legado (docs/
  inventario_dw_legado.md, cap. 3) como usada por 4 workbooks.
*/

with condicoes as (

    select
        {{ trim_protheus('e4_codigo') }} as cod_cond_pgto,
        {{ trim_protheus('e4_descri') }} as descricao,
        {{ trim_protheus('e4_tipo') }}   as tipo,
        {{ trim_protheus('e4_cond') }}   as condicao,
        e4_ddd                            as dias_prazo,
        _carregado_em
    from {{ source('bronze', 'se4010') }}
    where d_e_l_e_t_ <> '*'

),

dedup as (

    select distinct on (cod_cond_pgto)
        cod_cond_pgto, descricao, tipo, condicao, dias_prazo
    from condicoes
    order by cod_cond_pgto, _carregado_em desc

)

select
    {{ dbt_utils.generate_surrogate_key(['cod_cond_pgto']) }} as sk_cond_pgto,
    cod_cond_pgto,
    descricao,
    tipo,
    condicao,
    dias_prazo
from dedup

union all

select
    {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }},
    'NAO_IDENTIFICADO', 'Condição de pagamento não identificada', null, null, null
