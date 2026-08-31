/*
  Rateio de titulo por multiplas naturezas financeiras (SEV010),
  conformado. Grao: recno_origem — um titulo com custo dividido entre
  naturezas aparece em varias linhas, uma por percentual de rateio.
  Replica sqlfMultiplasNaturezas (fFinanceiro.m). SEV010 nao tem
  _STAMP_ (carga full, ver fontes.yml).
*/

select
    {{ trim_protheus('ev_filial') }}   as filial,
    {{ trim_protheus('ev_prefixo') }}  as prefixo,
    {{ trim_protheus('ev_num') }}      as titulo,
    {{ trim_protheus('ev_parcela') }}  as parcela,
    {{ trim_protheus('ev_clifor') }}   as cod_clifor,
    {{ trim_protheus('ev_loja') }}     as loja,
    {{ trim_protheus('ev_tipo') }}     as tipo,
    ev_valor                           as valor,
    {{ trim_protheus('ev_naturez') }}  as cod_natureza,
    ev_perc                            as perc_rateio,
    r_e_c_n_o_ as recno_origem,
    _carregado_em
from {{ source('bronze', 'sev010') }}
where d_e_l_e_t_ <> '*'
