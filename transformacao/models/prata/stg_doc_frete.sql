/*
  Documento de frete com ocorrencia de transporte (GW4010 + GU3/GW3/
  GW1/GWL/GWD/AC9). Grao: documento x anexo (recno_origem + recno_ac9)
  — um documento pode ter varios objetos anexados no AC9010 (fotos,
  PDFs da ocorrencia), entao o grao real nao e 1 linha por GW4010.
  Replica sqlDocFrete (fLogistica.m), incluindo o SELECT DISTINCT do
  legado (colapsa copias com o mesmo conteudo que a cadeia de joins
  produz).

  Achado: o join com AC9010 usa uma chave concatenada (GWL_FILIAL +
  GWL_NROCO, 13 caracteres) contra AC9_CODENT, que e CHAR(70) — largo
  porque e compartilhado por varias entidades diferentes (SC7, SF1,
  SA1...). SQL Server compara CHAR por padding automatico (ignora
  espaco a direita); Postgres nao — sem btrim() dos dois lados, esse
  join simplesmente nunca casava (media 12,4 mil linhas de anexo
  perdidas, confirmado comparando com e sem o btrim).
*/

select distinct
    case
        when {{ trim_protheus('gw3.gw3_tpdf') }} = '1' then 'NORMAL'
        when {{ trim_protheus('gw3.gw3_tpdf') }} = '2' then 'COMPLEMENTAR VALOR'
        when {{ trim_protheus('gw3.gw3_tpdf') }} = '3' then 'COMPLEMENTAR IMPOSTO'
        when {{ trim_protheus('gw3.gw3_tpdf') }} = '4' then 'REENTREGA'
        when {{ trim_protheus('gw3.gw3_tpdf') }} = '5' then 'DEVOLUCAO'
        when {{ trim_protheus('gw3.gw3_tpdf') }} = '6' then 'REDESPACHO'
        when {{ trim_protheus('gw3.gw3_tpdf') }} = '7' then 'SERVICO'
        else 'OUTRO'
    end as tipo_documento,
    {{ trim_protheus('gw4.gw4_filial') }}  as filial,
    {{ data_protheus('gw3.gw3_dtemis') }}  as dt_emissao,
    {{ trim_protheus('gw4.gw4_nrdf') }}    as numero_df,
    {{ trim_protheus('gw4.gw4_nrdc') }}    as numero_dc,
    left(btrim(gw1.gw1_nrrom), 6)           as numero_romaneio,
    {{ trim_protheus('gw4.gw4_emisdf') }}  as cod_transportador,
    {{ data_protheus('gw3.gw3_dtfis') }}   as dt_fiscal,
    {{ trim_protheus('gwd.gwd_dsocor') }}  as descricao_ocorrencia,
    gw3.gw3_vldf                             as valor_documento,
    {{ trim_protheus('gw4.gw4_cdesp') }}   as especie_doc,
    {{ trim_protheus('gw4.gw4_serdf') }}   as serie_df,
    {{ trim_protheus('ac9.ac9_codobj') }}  as cod_objeto,
    gw4.r_e_c_n_o_ as recno_origem,
    ac9.r_e_c_n_o_ as recno_ac9,
    gw4._carregado_em
from {{ source('bronze', 'gw4010') }} gw4
left join {{ source('bronze', 'gu3010') }} gu3
    on gu3.d_e_l_e_t_ <> '*' and gw4.gw4_emisdf = gu3.gu3_cdemit
left join {{ source('bronze', 'gw3010') }} gw3
    on gw3.d_e_l_e_t_ <> '*'
   and gw4.gw4_filial = gw3.gw3_filial
   and gw4.gw4_cdesp = gw3.gw3_cdesp
   and gw4.gw4_emisdf = gw3.gw3_emisdf
   and gw4.gw4_serdf = gw3.gw3_serdf
   and gw4.gw4_nrdf = gw3.gw3_nrdf
left join {{ source('bronze', 'gw1010') }} gw1
    on gw1.d_e_l_e_t_ <> '*'
   and gw4.gw4_filial = gw1.gw1_filial
   and gw4.gw4_emisdc = gw1.gw1_emisdc
   and gw4.gw4_serdc = gw1.gw1_serdc
   and gw4.gw4_nrdc = gw1.gw1_nrdc
left join {{ source('bronze', 'gwl010') }} gwl
    on gwl.d_e_l_e_t_ <> '*'
   and gw4.gw4_filial = gwl.gwl_filial
   and gw4.gw4_nrdc = gwl.gwl_nrdc
   and gw4.gw4_emisdc = gwl.gwl_emitdc
   and gw4.gw4_serdc = gwl.gwl_serdc
   and gw4.gw4_tpdc = gwl.gwl_tpdc
left join {{ source('bronze', 'gwd010') }} gwd
    on gwd.d_e_l_e_t_ <> '*'
   and gwl.gwl_filial = gwd.gwd_filial
   and gwl.gwl_nroco = gwd.gwd_nroco
   and gw1.gw1_emisdc = gwd.gwd_cdtrp
left join {{ source('bronze', 'ac9010') }} ac9
    on ac9.d_e_l_e_t_ <> '*'
   and ac9.ac9_entida = 'GWD'
   -- ac9_codent e CHAR(70) largo (compartilhado por varias entidades);
   -- a concatenacao filial+nroco tem so 13 — sem o padding automatico
   -- do SQL Server (ANSI, ignora espaco a direita), o Postgres nunca
   -- casaria sem o btrim dos dois lados.
   and btrim(gwl.gwl_filial || gwl.gwl_nroco) = btrim(ac9.ac9_codent)
where gw4.d_e_l_e_t_ <> '*'
