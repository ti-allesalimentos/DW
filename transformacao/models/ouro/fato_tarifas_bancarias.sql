/*
  Fato tarifas bancarias — Protheus (SE5010, naturezas de
  tarifa/IOF/juros de aplicacao). Grao: recno_origem.
*/

select
    f.recno_origem,
    coalesce(dn.sk_natureza, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_natureza,
    f.filial,
    f.dt_movimento as data_movimento,
    f.valor_titulo,
    f.historico,
    f.chave_banco,
    f._carregado_em
from {{ ref('stg_tarifas_bancarias') }} f
left join {{ ref('dim_natureza_financeira') }} dn on dn.cod_natureza = f.cod_natureza
