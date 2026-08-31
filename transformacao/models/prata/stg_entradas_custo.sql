/*
  Itens de NF de entrada (compra/devolucao de compra) usados pra
  custeio (SF1010+SD1010). Grao: recno_origem (SD1010, item da nota).
  Replica sqlEntradas (fCusto.m).

  Duas NFs excluidas no legado por numero literal ('0000000NF',
  '20062501Q') — sedimento sem explicacao no workbook, replicado
  fielmente por nao ter como validar se ainda se aplica.
*/

select
    {{ trim_protheus('sf1.f1_filial') }}   as filial,
    {{ trim_protheus('sf1.f1_doc') }}      as nfe,
    {{ trim_protheus('sf1.f1_serie') }}    as serie,
    {{ trim_protheus('sf1.f1_fornece') }}  as cod_fornecedor,
    {{ trim_protheus('sf1.f1_loja') }}     as loja_fornecedor,
    {{ trim_protheus('sf1.f1_fornece') }} || {{ trim_protheus('sf1.f1_loja') }} as chave_fornecedor,
    {{ trim_protheus('sf1.f1_cond') }}     as cond_pagamento,
    {{ data_protheus('sf1.f1_emissao') }}  as dt_emissao,
    {{ data_protheus('sf1.f1_dtdigit') }}  as dt_lancamento,
    {{ trim_protheus('sf1.f1_tipo') }}     as tipo_nf,
    {{ trim_protheus('sd1.d1_cod') }}      as cod_produto,
    {{ trim_protheus('sd1.d1_um') }}       as um,
    sd1.d1_quant                            as qtd,
    sd1.d1_vunit                            as vr_unitario,
    sd1.d1_total                            as vr_total,
    sd1.r_e_c_n_o_ as recno_origem,
    sd1._carregado_em
from {{ source('bronze', 'sf1010') }} sf1
inner join {{ source('bronze', 'sd1010') }} sd1
    on sd1.d_e_l_e_t_ <> '*'
   and sd1.d1_filial = sf1.f1_filial
   and sd1.d1_doc = sf1.f1_doc
   and sd1.d1_serie = sf1.f1_serie
   and sd1.d1_fornece = sf1.f1_fornece
   and sd1.d1_loja = sf1.f1_loja
where sf1.d_e_l_e_t_ <> '*'
  and {{ trim_protheus('sf1.f1_tipo') }} in ('N', 'C')
  and btrim(sf1.f1_doc) <> '0000000NF'
  and btrim(sf1.f1_doc) <> '20062501Q'
