/*
  Rescisoes (SRG010), conformado. Grao: recno_origem.

  Fonte do Turnover do Oryon Board (modulos/bi/gp_turnover.py) — mais
  simples de proposito que stg_motivo_rescisao (que serve outro
  consumidor: MOTIVORESCISAO.m, com join em RCC010/SRR010 e valor pago).
  Aqui nao ha join nem filtro de socio/PJ: o fato_rescisao_rh faz inner
  join em dim_funcionario, que ja exclui socio/PJ e resolve nome/CC —
  mesmo efeito do INNER JOIN SRA010 que o Oryon faz na extracao.
*/

select
    {{ trim_protheus('rg_filial') }}  as filial,
    {{ trim_protheus('rg_mat') }}     as matricula,
    {{ trim_protheus('rg_tipores') }} as cod_motivo,
    {{ data_protheus('rg_datadem') }} as dt_demissao,
    r_e_c_n_o_ as recno_origem,
    _carregado_em
from {{ source('bronze', 'srg010') }}
where d_e_l_e_t_ <> '*'
