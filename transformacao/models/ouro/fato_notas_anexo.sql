/*
  Fato NF de entrada x anexo digitalizado — Protheus (SF1010 x AC9010).
  Grao: recno_origem. `tem_anexo = false` da a lista de "sem anexo"
  que o nome legado prometia.
*/

select
    f.recno_origem,
    coalesce(df.sk_fornecedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_fornecedor,
    f.filial,
    f.especie,
    f.nfe,
    f.serie,
    f.dt_emissao as data_emissao,
    f.tem_anexo,
    f.cod_objeto_anexo,
    f._carregado_em
from {{ ref('stg_notas_anexo') }} f
left join {{ ref('dim_fornecedor') }} df on df.chave_fornecedor = f.chave_fornecedor
