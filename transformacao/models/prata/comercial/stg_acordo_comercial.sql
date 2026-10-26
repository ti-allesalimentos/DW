/*
  Acordo comercial (entrada de verba/bonificacao do fornecedor via TES
  050/052), conformado. Grao: item de NF de entrada (SD1010).

  Query mais simples dos fatos comerciais: uma tabela so, sem join.
  D1_SERIE e reaproveitado como "tipo" no legado (mesmo padrao de campo
  remapeado visto em devolucoes com D1_COR/D1_CHASSI).
*/

with itens as (

    select
        {{ trim_protheus('d1_filial') }}  as filial,
        {{ trim_protheus('d1_doc') }}     as doc,
        {{ trim_protheus('d1_item') }}    as item_nf,
        {{ trim_protheus('d1_cod') }}     as cod_protheus,
        {{ trim_protheus('d1_fornece') }} as cod_cliente,
        {{ trim_protheus('d1_loja') }}    as loja_cliente,
        {{ trim_protheus('d1_serie') }}   as tipo,
        {{ trim_protheus('d1_nfori') }}   as nf_origem,
        {{ trim_protheus('d1_itemori') }} as item_origem,
        {{ data_protheus('d1_emissao') }} as dt_emissao,
        d1_um                             as um_origem,
        d1_quant                          as qtd_origem,
        d1_vunit                          as vunit_origem,
        d1_total                          as total,
        r_e_c_n_o_                        as recno_origem,
        _carregado_em
    from {{ source('bronze', 'sd1010') }}
    where d_e_l_e_t_ <> '*'
      and {{ trim_protheus('d1_tes') }} in ('050', '052')

),

itens_dedup as (

    -- chave fisica real do SD1010, igual ao padrao de devolucoes (doc
    -- sozinho pode se repetir entre fornecedores/lojas diferentes).
    select *
    from (
        select i.*,
            row_number() over (
                partition by filial, doc, item_nf, cod_cliente, loja_cliente
                order by recno_origem
            ) as linha
        from itens i
    ) x
    where linha = 1

),

com_conversao as (

    select
        i.*,
        coalesce(m.produto_base, i.cod_protheus) as cod_produto,
        coalesce(m.fator, 1)                     as fator_conversao,
        m.produto_base is not null                as convertido
    from itens_dedup i
    left join {{ ref('map_produto_cx') }} m
           on m.produto_cx = i.cod_protheus

)

select
    filial,
    item_nf,
    cod_protheus,
    cod_produto,
    cod_cliente || loja_cliente as chave_cliente,
    cod_cliente,
    loja_cliente,
    tipo,
    nf_origem,
    item_origem,
    dt_emissao,
    qtd_origem * fator_conversao as qtd,
    case when convertido then 'KG' else um_origem end as um,
    vunit_origem as vr_unit,
    vunit_origem / fator_conversao as preco_unit,
    total,
    recno_origem,
    _carregado_em
from com_conversao
