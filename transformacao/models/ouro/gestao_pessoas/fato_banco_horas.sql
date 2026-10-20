/*
  Fato banco de horas — Protheus (SPI010), snapshot por funcionario
  (nao um historico de lancamentos). Grao: sk_funcionario.

  Inner join em dim_funcionario de proposito (nao left join com
  NAO_IDENTIFICADO, diferente de fato_dupla_funcao/fato_historico_salarial):
  replica exatamente o join do Oryon Board (modulos/bi/gp_banco_horas.py),
  que so mostra banco de horas de quem esta no cadastro filtrado de
  funcionarios (sem socio/PJ). Se SPI010 tiver lancamento pra uma
  matricula fora desse cadastro, cai fora aqui tambem.
*/

select
    df.sk_funcionario,
    b.chave_funcionario,
    b.credito_horas,
    b.debito_horas,
    b.saldo_horas,
    b.dt_referencia
from {{ ref('stg_banco_horas') }} b
join {{ ref('dim_funcionario') }} df on df.chave_funcionario = b.chave_funcionario
