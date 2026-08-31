/*
  Fato notas fiscais de servico — Protheus (SF1010, especie 'NFS').
  Grao: recno_origem.
*/

select
    f.recno_origem,
    coalesce(df.sk_fornecedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_fornecedor,
    f.filial,
    f.dt_emissao as data_emissao,
    f.nfe,
    f.serie,
    f.valor_bruto,
    f.valor_irrf,
    f.valor_inss,
    f.valor_pis,
    f.valor_cofins,
    f.valor_csll,
    f.valor_iss,
    f._carregado_em
from {{ ref('stg_notas_servico') }} f
left join {{ ref('dim_fornecedor') }} df on df.chave_fornecedor = f.chave_fornecedor
