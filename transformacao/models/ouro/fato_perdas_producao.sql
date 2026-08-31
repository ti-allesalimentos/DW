/*
  Fato perdas de producao por OP — Protheus (SD3010, TM=507). Grao:
  filial + op + cod_produto + data.
*/

with base as (

    select
        *,
        {{ dbt_utils.generate_surrogate_key(['filial', 'op', 'cod_produto', 'dt_lancamento']) }} as sk_perda
    from {{ ref('stg_perdas_producao') }}

)

select
    f.sk_perda,
    f.filial,
    coalesce(dpp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto_pai,
    f.op,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    f.qtd_total,
    f.dt_lancamento as data_lancamento
from base f
left join {{ ref('dim_produto') }} dpp on dpp.cod_produto = f.cod_produto_pai
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
