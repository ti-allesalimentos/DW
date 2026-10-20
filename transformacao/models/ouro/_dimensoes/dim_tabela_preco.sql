/*
  Tabela de preco de referencia — DA0010+DA1010. Grao: filial + tabela +
  produto + UF. Nao e uma dimensao classica de FK unica (nao ha
  "NAO_IDENTIFICADO"): e um rate card que outros modelos consultam pela
  combinacao (filial, cod_tabela, sk_produto, uf) — normalmente a mesma
  tabela atribuida ao pedido (SC5010.C5_TABELA).
*/

select
    {{ dbt_utils.generate_surrogate_key(['f.filial', 'f.cod_tabela', 'f.cod_produto', 'f.uf']) }} as sk_tabela_preco,
    f.filial,
    f.cod_tabela,
    f.descricao_tabela,
    coalesce(dp.sk_produto, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_produto,
    f.uf,
    f.preco_unit
from {{ ref('stg_tabela_preco') }} f
left join {{ ref('dim_produto') }} dp on dp.cod_produto = f.cod_produto
