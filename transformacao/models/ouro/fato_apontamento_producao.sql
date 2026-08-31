/*
  Fato apontamento de producao — Protheus (SH6010). Grao: recno_origem.
*/

select
    f.recno_origem,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    f.filial,
    f.op,
    f.cod_operacao,
    f.operacao,
    f.recurso,
    f.dt_producao as data_producao,
    f.hora_inicio,
    f.hora_fim,
    f.qtd_produzida,
    f.qtd_produzida_cx,
    f.lote,
    f.identificador,
    f._carregado_em
from {{ ref('stg_apontamento_producao') }} f
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
