/*
  Pedidos de venda liberados/embarcados (SC9010), conformados e
  agregados. Grao: filial + pedido + cliente + loja + produto + item +
  sequencia (mesmo agrupamento do legado, docs/legado_m/
  PEDIDOSDEVENDACONSOLIDADO.m).

  Fato novo, sem equivalente reconciliavel no piloto anterior (nao
  estava no raw/dw). Fontes SC9010, SF4010 e DAK010 carregadas pela
  primeira vez para este fato.

  Diferenca deliberada do legado: os joins com SE4010 (condicao de
  pagamento) e SF4010 (descricao do TES) viraram LEFT — eram INNER no
  Power Query, e um INNER aqui descartaria silenciosamente pedidos cuja
  condicao de pagamento ou TES nao tem cadastro correspondente. SC6010,
  SC5010 e SB1010 continuam INNER: sem pedido, item ou produto
  cadastrado a linha nao faz sentido.
*/

with itens as (

    select
        {{ trim_protheus('c9_filial') }}   as filial,
        {{ trim_protheus('c9_pedido') }}   as pedido,
        {{ trim_protheus('c9_cliente') }}  as cod_cliente,
        {{ trim_protheus('c9_loja') }}     as loja_cliente,
        {{ trim_protheus('c9_produto') }}  as cod_protheus,
        {{ trim_protheus('c9_item') }}     as item,
        {{ trim_protheus('c9_sequen') }}   as sequen,
        {{ trim_protheus('c9_nfiscal') }}  as nfe,
        coalesce(nullif(ltrim({{ trim_protheus('c9_serienf') }}, '0'), ''), '0') as serie,
        {{ trim_protheus('c9_carga') }}    as carga,
        c9_qtdlib                          as qtd_origem,
        c9_prcven                          as prcven_origem,
        r_e_c_n_o_                         as recno_origem,
        _carregado_em
    from {{ source('bronze', 'sc9010') }}
    where d_e_l_e_t_ <> '*'
      and {{ trim_protheus('c9_produto') }} like '%PA%'

),

itens_dedup as (

    select *
    from (
        select i.*,
            row_number() over (
                partition by filial, pedido, cod_cliente, loja_cliente, cod_protheus, item, sequen
                order by recno_origem
            ) as linha
        from itens i
    ) x
    where linha = 1

),

sb1010_dedup as (

    select distinct on (cod_protheus)
        {{ trim_protheus('b1_cod') }} as cod_protheus,
        b1_pesbru                     as peso_bruto_unit
    from {{ source('bronze', 'sb1010') }}
    where d_e_l_e_t_ <> '*'
    order by cod_protheus, _carregado_em desc

),

sc6010_dedup as (

    select distinct on (filial, num_pedido, item)
        filial, num_pedido, item, tes, local_armazem
    from (
        select
            {{ trim_protheus('c6_filial') }} as filial,
            {{ trim_protheus('c6_num') }}    as num_pedido,
            {{ trim_protheus('c6_item') }}   as item,
            {{ trim_protheus('c6_tes') }}    as tes,
            {{ trim_protheus('c6_local') }}  as local_armazem,
            _carregado_em
        from {{ source('bronze', 'sc6010') }}
        where d_e_l_e_t_ <> '*'
    ) c6
    order by filial, num_pedido, item, _carregado_em desc

),

sc5010_dedup as (

    select distinct on (filial, num_pedido)
        filial, num_pedido, dt_emissao_pedido, tipo_entrega, cod_vendedor, cod_gerente, cod_condpag
    from (
        select
            {{ trim_protheus('c5_filial') }}  as filial,
            {{ trim_protheus('c5_num') }}     as num_pedido,
            {{ data_protheus('c5_emissao') }} as dt_emissao_pedido,
            {{ trim_protheus('c5_x_tpent') }} as tipo_entrega,
            {{ trim_protheus('c5_vend1') }}   as cod_vendedor,
            {{ trim_protheus('c5_vend3') }}   as cod_gerente,
            {{ trim_protheus('c5_condpag') }} as cod_condpag,
            _carregado_em
        from {{ source('bronze', 'sc5010') }}
        where d_e_l_e_t_ <> '*'
    ) c5
    order by filial, num_pedido, _carregado_em desc

),

sf2010_dedup as (

    -- Data de emissao da NF, quando o pedido ja foi faturado.
    select distinct on (filial, nfe, serie)
        filial, nfe, serie, dt_emissao_nf
    from (
        select
            {{ trim_protheus('f2_filial') }} as filial,
            {{ trim_protheus('f2_doc') }}    as nfe,
            coalesce(nullif(ltrim({{ trim_protheus('f2_serie') }}, '0'), ''), '0') as serie,
            {{ data_protheus('f2_emissao') }} as dt_emissao_nf,
            _carregado_em
        from {{ source('bronze', 'sf2010') }}
        where d_e_l_e_t_ <> '*'
    ) f2
    order by filial, nfe, serie, _carregado_em desc

),

dak010_dedup as (

    select distinct on (carga)
        {{ trim_protheus('dak_cod') }}   as carga,
        {{ data_protheus('dak_data') }}  as dt_embarque
    from {{ source('bronze', 'dak010') }}
    where d_e_l_e_t_ <> '*'
    order by carga, _carregado_em desc

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
    c.filial,
    c.pedido,
    c.cod_cliente || c.loja_cliente as chave_cliente,
    c.cod_cliente,
    c.loja_cliente,
    c.cod_produto,
    c.item,
    c.sequen,
    c5.dt_emissao_pedido,
    c5.tipo_entrega,
    c5.cod_vendedor,
    c5.cod_gerente,
    c6.tes,
    c6.local_armazem,
    c.nfe,
    c.serie,
    sf2.dt_emissao_nf,
    c.carga,
    dak.dt_embarque,
    c.qtd_origem * c.fator_conversao as qtd,
    c.prcven_origem / c.fator_conversao as preco_unit,
    (c.qtd_origem * c.fator_conversao) * (c.prcven_origem / c.fator_conversao) as total,
    (c.qtd_origem * c.fator_conversao) * (sb1.peso_bruto_unit / c.fator_conversao) as peso_bruto,
    c.recno_origem,
    c._carregado_em
from com_conversao c
join sc6010_dedup c6
    on c6.filial = c.filial and c6.num_pedido = c.pedido and c6.item = c.item
join sc5010_dedup c5
    on c5.filial = c.filial and c5.num_pedido = c.pedido
join sb1010_dedup sb1
    on sb1.cod_protheus = c.cod_protheus
left join sf2010_dedup sf2
    on sf2.filial = c.filial and sf2.nfe = c.nfe and sf2.serie = c.serie
left join dak010_dedup dak
    on dak.carga = c.carga
