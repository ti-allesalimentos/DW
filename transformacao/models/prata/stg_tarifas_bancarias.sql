/*
  Tarifas bancarias (SE5010, naturezas especificas de tarifa/IOF/juros
  de aplicacao), conformado. Grao: recno_origem. Replica
  sqlfTarifasBancarias (fFinanceiro.m).

  E5_SITUACA vem em branco (' ') pra quase toda linha valida — o legado
  compara o CHAR bruto (`<> 'C'`), onde ' ' <> 'C' e verdadeiro. Usar
  trim_protheus() aqui (que converte '' em NULL) quebraria o filtro:
  NULL <> 'C' nunca e verdadeiro, e excluiria 90% das linhas por
  engano. Por isso os dois filtros de desigualdade usam btrim() puro,
  nao a macro.
*/

select
    {{ trim_protheus('e5_filorig') }}   as filial,
    {{ data_protheus('e5_data') }}      as dt_movimento,
    e5_valor                            as valor_titulo,
    {{ trim_protheus('e5_histor') }}    as historico,
    {{ trim_protheus('e5_naturez') }}   as cod_natureza,
    {{ trim_protheus('e5_banco') }} || {{ trim_protheus('e5_agencia') }} || {{ trim_protheus('e5_conta') }} as chave_banco,
    r_e_c_n_o_ as recno_origem,
    _carregado_em
from {{ source('bronze', 'se5010') }}
where d_e_l_e_t_ <> '*'
  and btrim(e5_situaca) <> 'C'
  and btrim(e5_tipodoc) <> 'ES'
  and {{ trim_protheus('e5_naturez') }} in (
        '0502001', '0406004', '0406005', '0406006', '0406007', '0406008',
        '0406009', '0406010', '0406011', '0406018', '0406003', '0102001'
      )
