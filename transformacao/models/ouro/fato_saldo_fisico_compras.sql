/*
  Fato saldo fisico de estoque pra compras — Protheus (SB2010).
  Grao: filial + produto.
*/

with base as (

    select
        *,
        {{ dbt_utils.generate_surrogate_key(['filial', 'cod_produto']) }} as sk_saldo
    from {{ ref('stg_saldo_fisico_compras') }}

)

select
    f.sk_saldo,
    f.filial,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    f.qtd_atual
from base f
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
