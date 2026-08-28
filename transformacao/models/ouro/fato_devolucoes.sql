/*
  Fato devolucoes — Protheus (SD1010). Grao: item de nota fiscal de
  entrada por devolucao de venda.

  Sem sk_vendedor: a devolucao nao carrega vendedor no legado (o cliente
  que devolve e quem importa aqui).
*/

select
    f.recno_origem,
    coalesce(dc.sk_cliente, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_cliente,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    f.dt_emissao as data_emissao,
    f.dt_lancamento as data_lancamento,
    f.dt_emissao_original as data_emissao_nf_origem,
    f.filial,
    f.nf,
    f.serie,
    f.item_nf,
    f.nf_origem,
    f.item_origem,
    f.cfop,
    f.qtd,
    f.um,
    f.total,
    f.preco_unit,
    f.motivo_dev_sigla,
    f.motivo_dev_descricao,
    f.destino_sigla,
    f.destino_descricao,
    f._carregado_em
from {{ ref('stg_devolucoes') }} f
left join {{ ref('dim_cliente') }} dc on dc.chave_cliente = f.chave_cliente
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
