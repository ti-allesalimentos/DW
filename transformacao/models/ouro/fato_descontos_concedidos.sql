/*
  Fato descontos concedidos a clientes — Protheus (SE1010).
  Grao: recno_origem.
*/

select
    f.recno_origem,
    coalesce(dc.sk_cliente, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_cliente,
    coalesce(dn.sk_natureza, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_natureza,
    f.dt_emissao as data_emissao,
    f.valor,
    f._carregado_em
from {{ ref('stg_descontos_concedidos') }} f
left join {{ ref('dim_cliente') }} dc on dc.chave_cliente = f.chave_cliente
left join {{ ref('dim_natureza_financeira') }} dn on dn.cod_natureza = f.cod_natureza
