/*
  Movimento bancario de NCC — nota de credito (SE5010, tipo 'NCC'),
  conformado. Grao: recno_origem. Replica sqlMovimentoBancarioNCC
  (fFinanceiro.m).
*/

select
    {{ trim_protheus('e5_filorig') }}  as filial,
    {{ data_protheus('e5_data') }}     as dt_movimento,
    {{ trim_protheus('e5_tipo') }}     as tipo,
    {{ trim_protheus('e5_naturez') }}  as cod_natureza,
    {{ trim_protheus('e5_histor') }}   as observacao,
    {{ trim_protheus('e5_tipodoc') }}  as tipo_doc,
    {{ trim_protheus('e5_prefixo') }}  as prefixo,
    {{ trim_protheus('e5_parcela') }}  as parcela,
    {{ trim_protheus('e5_clifor') }}   as cod_clifor,
    {{ trim_protheus('e5_loja') }}     as loja,
    {{ trim_protheus('e5_benef') }}    as beneficiario,
    {{ trim_protheus('e5_numero') }}   as titulo,
    {{ trim_protheus('e5_motbx') }}    as motivo_baixa,
    e5_valor - e5_vljuros - e5_vlmulta + e5_vldesco as valor_titulo,
    e5_valor                           as valor_quitado,
    r_e_c_n_o_ as recno_origem,
    _carregado_em
from {{ source('bronze', 'se5010') }}
where d_e_l_e_t_ <> '*'
  and {{ trim_protheus('e5_tipo') }} = 'NCC'
  and {{ trim_protheus('e5_origem') }} <> 'MATA103'
