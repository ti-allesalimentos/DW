/*
  Fato consumo de materia-prima/insumo por OP — Protheus (SD3010, CFOP
  contendo 'RE'). Grao: filial + op + cod_produto + data.
*/

with base as (

    select
        *,
        {{ dbt_utils.generate_surrogate_key(['filial', 'op', 'cod_produto', 'um', 'tipo_movimento', 'grupo_produto', 'dt_entrada']) }} as sk_consumo
    from {{ ref('stg_consumo_producao') }}

)

select
    f.sk_consumo,
    f.filial,
    coalesce(dpp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto_pai,
    f.op,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    f.um,
    f.qtd_total,
    f.tipo_movimento,
    f.grupo_produto,
    f.dt_entrada as data_entrada
from base f
left join {{ ref('dim_produto') }} dpp on dpp.cod_produto = f.cod_produto_pai
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
