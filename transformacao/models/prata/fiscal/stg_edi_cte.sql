/*
  CT-e importado via EDI (GXG010+GU3010). Grao: recno_origem. Replica
  sqlEdiCte (fLogistica.m) — com uma correcao: o legado usa GXG_UFFIM
  (UF destino) tanto pra "UF INICIO" quanto pra "UF DESTINO" (bug real,
  confirmado — GXG010 tem os dois campos, GXG_UFINI e GXG_UFFIM,
  distintos). Usamos GXG_UFINI pra uf_origem aqui.
*/

select
    {{ trim_protheus('gxg_fildoc') }}  as filial,
    {{ trim_protheus('gxg_ediarq') }}  as arquivo,
    {{ trim_protheus('gxg_nrdf') }}    as numero_cte,
    {{ data_protheus('gxg_dtemis') }}  as dt_emissao,
    {{ data_protheus('gxg_dtimp') }}   as dt_importacao,
    {{ trim_protheus('gxg_cdesp') }}   as especie,
    {{ trim_protheus('gxg_emisdf') }}  as cod_transportador,
    gxg_frval                           as valor,
    gxg_pesor                           as peso,
    {{ trim_protheus('gxg_ufini') }}   as uf_origem,
    {{ trim_protheus('gxg_uffim') }}   as uf_destino,
    case
        when {{ trim_protheus('gxg_edisit') }} = '1' then 'IMPORTADO'
        when {{ trim_protheus('gxg_edisit') }} = '2' then 'IMPORTADO COM ERRO'
        when {{ trim_protheus('gxg_edisit') }} = '3' then 'REJEITADO'
        when {{ trim_protheus('gxg_edisit') }} = '4' then 'PROCESSADO'
        else 'ERRO IMPEDITIVO'
    end as situacao,
    r_e_c_n_o_ as recno_origem,
    _carregado_em
from {{ source('bronze', 'gxg010') }}
where d_e_l_e_t_ <> '*'
