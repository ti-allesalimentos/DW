/*
  Fato reprocesso de producao — Protheus (SD3010, TM=200). Grao:
  recno_origem. cod_produto_pai identifica a ordem de producao
  original que gerou o material reprocessado.
*/

select
    f.recno_origem,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    coalesce(dpp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto_pai,
    f.filial,
    f.dt_emissao as data_emissao,
    f.tipo_movimento,
    f.armazem,
    f.endereco,
    f.horario,
    f.um,
    f.qtd,
    f.lote,
    f.op,
    f.id_sequencia,
    f.tipo,
    f.usuario,
    f._carregado_em
from {{ ref('stg_reprocesso') }} f
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
left join {{ ref('dim_produto') }} dpp on dpp.cod_produto = f.cod_produto_pai
