/*
  Fato rescisao (RH) — Protheus (SRG010), classificado
  Voluntario/Involuntario. Grao: recno_origem.

  Fonte do Turnover do Oryon Board — nao confundir com fato_motivo_rescisao
  (outro consumidor, outro grao, com valor pago). Inner join em
  dim_funcionario: exclui socio/PJ e resolve nome/centro de custo, igual
  ao INNER JOIN SRA010 que o Oryon faz na extracao (modulos/bi/gp_turnover.py).

  cod_motivo e zero-padded a 2 digitos antes do join na seed
  (motivos_rescisao_rh), igual ao `.zfill(2)` do Python original. Codigo
  sem correspondencia na seed vira "(nao classificado)"/OUTROS — nunca
  descarta a linha.
*/

select
    r.recno_origem,
    df.sk_funcionario,
    r.filial,
    r.matricula,
    df.nome,
    df.cod_centro_custo,
    r.cod_motivo,
    coalesce(m.descricao, '(nao classificado)') as motivo,
    coalesce(m.tipo, 'OUTROS')                  as tipo_rescisao,
    r.dt_demissao,
    r._carregado_em
from {{ ref('stg_rescisao_rh') }} r
join {{ ref('dim_funcionario') }} df on df.chave_funcionario = r.filial || r.matricula
left join {{ ref('motivos_rescisao_rh') }} m on m.cod_motivo = lpad(r.cod_motivo, 2, '0')
