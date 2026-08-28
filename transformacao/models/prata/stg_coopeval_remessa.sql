/*
  Remessas do cliente Coopeval (07390806), conformadas. Grao: item de
  nota fiscal. Sem filtro de CFOP no legado -- so o cliente.

  A query legada tinha `D2_EMISSAO > '20250430'`, um recorte de data que
  nao e regra de negocio (mesma categoria do corte de 20250131 removido
  no T5) -- nao reproduzido aqui de proposito. Se a reconciliacao
  mostrar linhas extras entre fev/2025 e abr/2025, e esperado: e
  historico que a planilha nao cobria, nao erro.
*/

with itens as (

    select
        {{ trim_protheus('d2_filial') }}   as filial,
        {{ trim_protheus('d2_doc') }}      as nfe,
        coalesce(nullif(ltrim({{ trim_protheus('d2_serie') }}, '0'), ''), '0') as serie,
        {{ trim_protheus('d2_item') }}     as item_nf,
        {{ trim_protheus('d2_cod') }}      as cod_protheus,
        {{ trim_protheus('d2_cliente') }}  as cod_cliente,
        {{ trim_protheus('d2_loja') }}     as loja_cliente,
        {{ trim_protheus('d2_cf') }}       as cfop,
        {{ trim_protheus('d2_um') }}       as um_origem,
        {{ data_protheus('d2_emissao') }}  as dt_emissao,
        d2_quant                           as qtd_origem,
        d2_total                           as total,
        d2_prcven                          as prcven_origem,
        r_e_c_n_o_                         as recno_origem,
        _carregado_em
    from {{ source('bronze', 'sd2010') }}
    where d_e_l_e_t_ <> '*'
      and {{ trim_protheus('d2_cliente') }} = '07390806'

),

itens_dedup as (

    select *
    from (
        select i.*,
            row_number() over (
                partition by filial, nfe, serie, item_nf
                order by recno_origem
            ) as linha
        from itens i
    ) x
    where linha = 1

),

sa1010_dedup as (

    select distinct on (cod_cliente, loja_cliente)
        {{ trim_protheus('a1_cod') }}  as cod_cliente,
        {{ trim_protheus('a1_loja') }} as loja_cliente,
        {{ trim_protheus('a1_vend') }} as cod_vendedor
    from {{ source('bronze', 'sa1010') }}
    where d_e_l_e_t_ <> '*'
    order by cod_cliente, loja_cliente, _carregado_em desc

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
    c.nfe,
    c.serie,
    c.item_nf,
    c.cod_protheus,
    c.cod_produto,
    c.cod_cliente || c.loja_cliente as chave_cliente,
    c.cod_cliente,
    c.loja_cliente,
    sa1.cod_vendedor,
    c.cfop,
    c.dt_emissao,
    c.qtd_origem * c.fator_conversao as qtd,
    case when c.convertido then 'KG' else c.um_origem end as um,
    c.prcven_origem / c.fator_conversao as preco_unit,
    c.total,
    c.recno_origem,
    c._carregado_em
from com_conversao c
left join sa1010_dedup sa1
    on sa1.cod_cliente = c.cod_cliente
   and sa1.loja_cliente = c.loja_cliente
