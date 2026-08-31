/*
  Fato ordem de producao — Protheus (SC2010). Grao: recno_origem.
*/

select
    f.recno_origem,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    f.filial,
    f.op,
    f.numero,
    f.item,
    f.sequencia,
    f.qtd_prevista,
    f.um,
    f.dt_prevista_inicio as data_prevista_inicio,
    f.dt_prevista_fim as data_prevista_fim,
    f.dt_emissao as data_emissao,
    f.qtd_produzida,
    f.dt_fechamento as data_fechamento,
    f._carregado_em
from {{ ref('stg_ordem_producao') }} f
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
