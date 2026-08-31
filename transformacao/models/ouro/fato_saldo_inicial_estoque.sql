/*
  Fato saldo inicial de estoque — Protheus (SB9010). Grao: recno_origem.
*/

select
    f.recno_origem,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    f.filial,
    f.local_estoque,
    f.qtd_inicial,
    f.valor_inicial,
    f.custo_medio,
    f._carregado_em
from {{ ref('stg_saldo_inicial_estoque') }} f
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
