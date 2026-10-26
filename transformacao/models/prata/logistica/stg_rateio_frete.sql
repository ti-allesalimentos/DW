/*
  Rateio de frete por item de NF (GWM010). Grao: recno_origem. Replica
  sqlRateio (fFretes.m) — o filtro de data do legado (GWM_DTEMIS >
  '20250201') e a mesma data de entrada do Protheus usada em todo o
  projeto (INICIO_PROTHEUS), nao uma regra adicional; sem efeito
  pratico aqui porque o bronze nao tem nada antes disso mesmo.
*/

select
    {{ trim_protheus('gwm_filial') }}   as filial,
    {{ trim_protheus('gwm_tpdoc') }}    as tipo_documento,
    {{ trim_protheus('gwm_cdtrp') }}    as cod_transportador,
    {{ trim_protheus('gwm_nrdoc') }}    as numero_cte,
    {{ trim_protheus('gwm_cdesp') }}    as especie,
    {{ data_protheus('gwm_dtemis') }}   as dt_emissao,
    {{ trim_protheus('gwm_nrdc') }}     as nfe,
    {{ trim_protheus('gwm_seqgw8') }}   as item,
    {{ trim_protheus('gwm_item') }}     as cod_produto,
    gwm_vlfret                           as valor_frete,
    gwm_pcrat / 100                      as perc_rateio,
    r_e_c_n_o_ as recno_origem,
    _carregado_em
from {{ source('bronze', 'gwm010') }}
where d_e_l_e_t_ <> '*'
