/*
  Fato lancamento de estoque indireto (nao ligado a OP) — Protheus
  (SD3010, TM=505). Grao: recno_origem.
*/

select
    f.recno_origem,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    coalesce(dc.sk_centro_custo, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_centro_custo,
    f.filial,
    f.tipo_movimento,
    f.um,
    f.qtd,
    f.dt_emissao as data_emissao,
    f._carregado_em
from {{ ref('stg_lancamento_indireto') }} f
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
left join {{ ref('dim_centro_custo') }} dc on dc.cod_centro_custo = f.cod_centro_custo
