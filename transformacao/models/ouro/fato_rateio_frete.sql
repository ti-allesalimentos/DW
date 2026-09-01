/*
  Fato rateio de frete por item de NF — Protheus (GWM010).
  Grao: recno_origem.
*/

select
    f.recno_origem,
    coalesce(dt.sk_transportador, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_transportador,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    f.filial,
    f.tipo_documento,
    f.numero_cte,
    f.especie,
    f.dt_emissao as data_emissao,
    f.nfe,
    f.item,
    f.valor_frete,
    f.perc_rateio,
    f._carregado_em
from {{ ref('stg_rateio_frete') }} f
left join {{ ref('dim_transportador') }} dt on dt.cod_transportador = f.cod_transportador
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
