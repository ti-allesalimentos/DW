/*
  Devolucao em nota de entrada (SF1010+SD1010, tipo 'D'). Grao:
  recno_origem (SD1010, item). Replica sqlDevolucoes — consulta
  byte-identica em fCompras.m e fFinanceiro.m (mesmo achado do
  inventario do legado, cap. 4); resolvida aqui uma unica vez, no
  dominio onde faz mais sentido (devolucao de compra). Cobre tambem o
  item que tinha ficado de fora da Fase 4 (docs/
  reconciliacao_financeiro.md nao construiu essa consulta).

  O legado junta SD1010 so por (doc, serie), sem fornecedor/loja — o
  mesmo tipo de reuso de numero de documento ja achado em fato_
  devolucoes (Comercial, Fase 2: "SD1010 document-number reuse across
  unrelated suppliers"). Testado direto no bronze: da 33 linhas sem
  fornecedor/loja no join contra 31 com — a diferenca e pequena aqui,
  mas a causa e a mesma, entao a chave completa (doc+serie+fornece+
  loja) e usada por precaucao.
*/

select
    {{ trim_protheus('sf1.f1_filial') }}   as filial,
    {{ trim_protheus('sf1.f1_doc') }}      as nfe,
    {{ trim_protheus('sf1.f1_serie') }}    as serie,
    {{ trim_protheus('sd1.d1_item') }}     as item,
    {{ trim_protheus('sd1.d1_cod') }}      as cod_produto,
    sd1.d1_total                            as valor_total,
    {{ trim_protheus('sf1.f1_fornece') }}  as cod_fornecedor,
    {{ trim_protheus('sf1.f1_loja') }}     as loja_fornecedor,
    {{ trim_protheus('sf1.f1_fornece') }} || {{ trim_protheus('sf1.f1_loja') }} as chave_fornecedor,
    {{ data_protheus('sf1.f1_emissao') }}  as dt_emissao,
    sd1.r_e_c_n_o_ as recno_origem,
    sd1._carregado_em
from {{ source('bronze', 'sf1010') }} sf1
inner join {{ source('bronze', 'sd1010') }} sd1
    on sd1.d_e_l_e_t_ <> '*'
   and sf1.f1_doc = sd1.d1_doc
   and sf1.f1_serie = sd1.d1_serie
   and sf1.f1_fornece = sd1.d1_fornece
   and sf1.f1_loja = sd1.d1_loja
where sf1.d_e_l_e_t_ <> '*'
  and btrim(sf1.f1_status) = ''
  and {{ trim_protheus('sf1.f1_tipo') }} = 'D'
