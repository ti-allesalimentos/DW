/*
  Fato estoque de produto acabado por local — Protheus (SB2010).
  Grao: recno_origem.
*/

select
    f.recno_origem,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    f.filial,
    f.local_estoque,
    f.qtd_atual,
    f.qtd_segunda_um,
    f._carregado_em
from {{ ref('stg_estoque_produto_acabado') }} f
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
