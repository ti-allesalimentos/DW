/*
  Fato contas a receber — Protheus (SE1010). Grao: titulo/parcela.
  Universo inteiro (aberto + baixado); quem consumir e que filtra saldo.
*/

select
    f.recno_origem,
    coalesce(dc.sk_cliente, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_cliente,
    coalesce(dv.sk_vendedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_vendedor,
    coalesce(dn.sk_natureza, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_natureza,
    f.filial,
    f.prefixo,
    f.titulo,
    f.parcela,
    f.tipo,
    f.cod_carteira,
    f.dt_emissao as data_emissao,
    f.dt_vencimento as data_vencimento,
    f.dt_vencimento_real as data_vencimento_real,
    f.valor,
    f.dt_baixa as data_baixa,
    f.bordero,
    f.dt_bordero as data_bordero,
    f.saldo,
    f.valor_moeda,
    f.perc_desconto_financeiro,
    f.valor_desconto_financeiro,
    f.historico,
    f.fluxo_caixa,
    f.forma_recebimento,
    f.forma_recebimento_x,
    f._carregado_em
from {{ ref('stg_contas_areceber') }} f
left join {{ ref('dim_cliente') }} dc on dc.chave_cliente = f.chave_cliente
left join {{ ref('dim_vendedor') }} dv on dv.cod_vendedor = f.cod_vendedor
left join {{ ref('dim_natureza_financeira') }} dn on dn.cod_natureza = f.cod_natureza
