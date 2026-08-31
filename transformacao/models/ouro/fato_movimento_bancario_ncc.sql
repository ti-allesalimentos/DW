/*
  Fato movimento bancario de NCC — Protheus (SE5010, tipo 'NCC').
  Grao: recno_origem.
*/

select
    f.recno_origem,
    coalesce(dn.sk_natureza, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_natureza,
    f.filial,
    f.dt_movimento as data_movimento,
    f.tipo,
    f.tipo_doc,
    f.prefixo,
    f.parcela,
    f.cod_clifor,
    f.loja,
    f.beneficiario,
    f.titulo,
    f.motivo_baixa,
    f.valor_titulo,
    f.valor_quitado,
    f._carregado_em
from {{ ref('stg_movimento_bancario_ncc') }} f
left join {{ ref('dim_natureza_financeira') }} dn on dn.cod_natureza = f.cod_natureza
