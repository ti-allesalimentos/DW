/*
  Fato ausencia/afastamento — Protheus (SR8010). Grao: recno_origem.

  Alimenta o headcount do Oryon Board: uma pessoa esta "afastada" numa
  data de referencia quando existe aqui uma linha com
  tipo_afastamento <> '001' e duracao_dias > 15, cobrindo aquela data
  (dt_inicio <= ref e dt_fim normalizado >= ref ou em aberto) — regra
  ja validada contra a planilha do RH (modulos/bi/gp_headcount.py).
  Ponto-no-tempo: fica pro consumidor aplicar o predicado com a data
  de referencia que quiser, este fato so conforma as colunas.
*/

select
    f.recno_origem,
    coalesce(df.sk_funcionario, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_funcionario,
    f.filial,
    f.matricula,
    f.tipo_afastamento,
    f.dt_inicio,
    f.dt_fim,
    f.duracao_dias,
    f._carregado_em
from {{ ref('stg_ausencias') }} f
left join {{ ref('dim_funcionario') }} df on df.chave_funcionario = f.filial || f.matricula
