/*
  Fato documento de frete com ocorrencia de transporte — Protheus
  (GW4010 + GU3/GW3/GW1/GWL/GWD/AC9). Grao: documento x anexo (um
  documento pode ter varios objetos anexados no AC9010).
*/

select
    {{ dbt_utils.generate_surrogate_key(['f.recno_origem', 'f.recno_ac9']) }} as sk_doc_frete,
    f.recno_origem,
    coalesce(dt.sk_transportador, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_transportador,
    f.tipo_documento,
    f.filial,
    f.dt_emissao as data_emissao,
    f.numero_df,
    f.numero_dc,
    f.numero_romaneio,
    f.dt_fiscal as data_fiscal,
    f.descricao_ocorrencia,
    f.valor_documento,
    f.especie_doc,
    f.serie_df,
    f.cod_objeto,
    f._carregado_em
from {{ ref('stg_doc_frete') }} f
left join {{ ref('dim_transportador') }} dt on dt.cod_transportador = f.cod_transportador
