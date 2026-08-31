/*
  Fato producao de produto acabado por OP — Protheus (SD3010, TM=10).
  Grao: filial + op + cod_produto (sem chave natural de linha, o
  legado ja agrega assim).
*/

with base as (

    select
        *,
        {{ dbt_utils.generate_surrogate_key(['filial', 'op', 'cod_produto', 'um', 'tipo_movimento', 'grupo_produto']) }} as sk_producao
    from {{ ref('stg_produto_acabado') }}

)

select
    f.sk_producao,
    f.filial,
    coalesce(dpp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto_pai,
    f.op,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    f.um,
    f.qtd_total,
    f.tipo_movimento,
    f.grupo_produto,
    f.dt_producao as data_producao
from base f
left join {{ ref('dim_produto') }} dpp on dpp.cod_produto = f.cod_produto_pai
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
