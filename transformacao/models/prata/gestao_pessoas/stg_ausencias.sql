/*
  Afastamentos/ausencias (SR8010). Grao: recno_origem.

  Alimenta a regra de "afastado" do Oryon Board (headcount): existe uma
  ausencia ativa numa data de referencia com tipoafa <> '001' e
  duracao > 15 dias — ja validada contra a planilha do RH
  (modulos/bi/gp_headcount.py). Essa avaliacao e ponto-no-tempo (depende
  de uma data de referencia arbitraria), entao fica pro consumidor, nao
  pra este modelo.

  data_protheus() zera a sentinela 19000101 de dt_fim, mas nao cobre o
  caso de dt_fim <= dt_inicio com uma data valida e ainda assim absurda
  (Protheus permite) — o Oryon trata isso como "sem data fim" (ausencia
  em aberto); replique com
  `case when dt_fim > dt_inicio then dt_fim end` em quem consumir.
*/

select
    {{ trim_protheus('r8_filial') }}  as filial,
    {{ trim_protheus('r8_mat') }}     as matricula,
    {{ trim_protheus('r8_tipoafa') }} as tipo_afastamento,
    {{ data_protheus('r8_dataini') }} as dt_inicio,
    {{ data_protheus('r8_datafim') }} as dt_fim,
    -- R8_DURACAO ja chega numerico no bronze (double precision), igual
    -- PI_QUANT/PC_QUANTC — nao e texto de largura fixa como os campos
    -- _protheus() acima.
    round(r8_duracao)::int as duracao_dias,
    r_e_c_n_o_ as recno_origem,
    _carregado_em
from {{ source('bronze', 'sr8010') }}
where d_e_l_e_t_ <> '*'
