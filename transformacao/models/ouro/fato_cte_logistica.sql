/*
  Fato CT-e, lado logistico — Protheus (GW3010). Grao: recno_origem.
*/

select
    f.recno_origem,
    coalesce(dt.sk_transportador, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_transportador,
    f.numero_cte,
    f.serie_cte,
    f.dt_emissao as data_emissao,
    f.valor,
    f._carregado_em
from {{ ref('stg_cte_logistica') }} f
left join {{ ref('dim_transportador') }} dt on dt.cod_transportador = f.cod_transportador
