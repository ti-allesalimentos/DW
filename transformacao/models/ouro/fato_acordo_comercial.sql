/*
  Fato acordo comercial — Protheus (SD1010, TES 050/052). Grao: item de
  NF de entrada. Sem vendedor (nao existe no legado para este fato).
*/

select
    f.recno_origem,
    coalesce(dc.sk_cliente, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_cliente,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    f.dt_emissao as data_emissao,
    f.filial,
    f.item_nf,
    f.tipo,
    f.nf_origem,
    f.item_origem,
    f.qtd,
    f.um,
    f.vr_unit,
    f.preco_unit,
    f.total,
    f._carregado_em
from {{ ref('stg_acordo_comercial') }} f
left join {{ ref('dim_cliente') }} dc on dc.chave_cliente = f.chave_cliente
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
