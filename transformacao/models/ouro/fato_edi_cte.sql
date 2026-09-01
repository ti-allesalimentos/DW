/*
  Fato CT-e importado via EDI — Protheus (GXG010+GU3010). Grao:
  recno_origem.
*/

select
    f.recno_origem,
    coalesce(dt.sk_transportador, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_transportador,
    f.filial,
    f.arquivo,
    f.numero_cte,
    f.dt_emissao as data_emissao,
    f.dt_importacao as data_importacao,
    f.especie,
    f.valor,
    f.peso,
    f.uf_origem,
    f.uf_destino,
    f.situacao,
    f._carregado_em
from {{ ref('stg_edi_cte') }} f
left join {{ ref('dim_transportador') }} dt on dt.cod_transportador = f.cod_transportador
