/*
  Fato custo de comissao sobre compra — Protheus (SF1010 tipo 'C',
  serie 'COM'). Grao: filial + nf + serie + fornecedor + produto +
  nf de origem. Nao confundir com fato_comissao (Fase 4, vendas).
*/

with base as (

    select
        *,
        {{ dbt_utils.generate_surrogate_key([
            'filial', 'nfe', 'serie', 'cod_fornecedor', 'loja_fornecedor',
            'cod_produto', 'nfe_origem', 'serie_origem'
        ]) }} as sk_custo_comissao
    from {{ ref('stg_custo_comissao_compra') }}

)

select
    f.sk_custo_comissao,
    f.filial,
    coalesce(df.sk_fornecedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_fornecedor,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    f.nfe,
    f.serie,
    f.nfe_origem,
    f.serie_origem,
    f.vr_total
from base f
left join {{ ref('dim_fornecedor') }} df on df.chave_fornecedor = f.chave_fornecedor
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
