/*
  Fato hora extra apontada — Protheus (SPC010/SPH010). Grao:
  sk_funcionario + ano_mes + tipo_he. So horas; o valor em R$ depende do
  salario vigente (fato_historico_salarial), periculosidade/insalubridade
  (dim_funcionario), dupla funcao (fato_dupla_funcao) e do salario minimo
  do periodo — este ultimo e cadastro manual do RH, fora do Protheus, e
  continua no Oryon (gp_salario_minimo). Por isso o calculo do valor fica
  no Oryon Board (modulos/bi/gp_hora_extra.py), nao aqui.

  Inner join em dim_funcionario de proposito (mesmo padrao do
  fato_banco_horas): replica o Oryon Board, que descarta apontamento de
  quem nao esta no cadastro filtrado de funcionarios.
*/

select
    df.sk_funcionario,
    h.chave_funcionario,
    h.ano_mes,
    h.tipo_he,
    h.horas
from {{ ref('stg_apontamento_hora_extra') }} h
join {{ ref('dim_funcionario') }} df on df.chave_funcionario = h.chave_funcionario
