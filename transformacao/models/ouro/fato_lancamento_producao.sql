/*
  Fato lancamento de estoque em producao (massa/insumos) — Protheus
  (SD3010). Grao: recno_origem.
*/

select
    f.recno_origem,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
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
    f.classificacao,
    f._carregado_em
from {{ ref('stg_lancamento_producao') }} f
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
