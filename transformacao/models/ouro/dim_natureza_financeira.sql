/*
  Dimensao natureza financeira, conformada. Grao: cod_natureza (SED010,
  ED_CODIGO). Usada por contas a receber, contas a pagar e movimento
  bancario — 3+ consumidores no legado, exatamente o criterio do
  inventario (docs/inventario_dw_legado.md, cap. 3) pra virar dimensao
  em vez de lookup repetido em cada fato.
*/

with naturezas as (

    select
        {{ trim_protheus('ed_codigo') }}  as cod_natureza,
        {{ trim_protheus('ed_descric') }} as descricao,
        _carregado_em
    from {{ source('bronze', 'sed010') }}
    where d_e_l_e_t_ <> '*'

),

dedup as (

    select distinct on (cod_natureza)
        cod_natureza, descricao
    from naturezas
    order by cod_natureza, _carregado_em desc

)

select
    {{ dbt_utils.generate_surrogate_key(['cod_natureza']) }} as sk_natureza,
    cod_natureza,
    descricao
from dedup

union all

select
    {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }},
    'NAO_IDENTIFICADO', 'Natureza não identificada'
