/*
  Custo de comissao sobre compra (SF1010 tipo 'C', serie 'COM') —
  NAO tem nenhuma relacao com a comissao de vendas da Fase 4
  (fato_comissao, baseada em SE5010). Mesmo nome no legado
  (dComissao, em fComissao.m E em fCusto.m), consultas totalmente
  diferentes — coincidencia de nome, nao duplicacao de regra (ver
  docs/inventario_dw_legado.md, cap. 4, que lista as duas juntas por
  isso). Renomeado aqui pra evitar a mesma confusao.

  Grao: (filial, nf, serie, cod_fornecedor, loja, cod_produto, nf_
  origem, serie_origem) — replica sqlComissao/dComissao (fCusto.m),
  que agrupa e soma o valor por essa chave apos filtrar a serie.
*/

with base as (

    select
        {{ trim_protheus('sf1.f1_filial') }}   as filial,
        {{ trim_protheus('sf1.f1_doc') }}      as nfe,
        {{ trim_protheus('sf1.f1_serie') }}    as serie,
        {{ trim_protheus('sf1.f1_fornece') }}  as cod_fornecedor,
        {{ trim_protheus('sf1.f1_loja') }}     as loja_fornecedor,
        {{ trim_protheus('sd1.d1_cod') }}      as cod_produto,
        {{ trim_protheus('sd1.d1_nfori') }}    as nfe_origem,
        {{ trim_protheus('sd1.d1_seriori') }}  as serie_origem,
        sd1.d1_total                            as vr_total
    from {{ source('bronze', 'sf1010') }} sf1
    inner join {{ source('bronze', 'sd1010') }} sd1
        on sd1.d_e_l_e_t_ <> '*'
       and sd1.d1_filial = sf1.f1_filial
       and sd1.d1_doc = sf1.f1_doc
       and sd1.d1_serie = sf1.f1_serie
       and sd1.d1_fornece = sf1.f1_fornece
       and sd1.d1_loja = sf1.f1_loja
    where sf1.d_e_l_e_t_ <> '*'
      and {{ trim_protheus('sf1.f1_tipo') }} = 'C'
      and {{ trim_protheus('sf1.f1_serie') }} = 'COM'

)

select
    filial,
    nfe,
    serie,
    cod_fornecedor,
    loja_fornecedor,
    cod_fornecedor || loja_fornecedor as chave_fornecedor,
    cod_produto,
    nfe_origem,
    serie_origem,
    sum(vr_total) as vr_total
from base
group by
    filial, nfe, serie, cod_fornecedor, loja_fornecedor, cod_produto,
    nfe_origem, serie_origem
