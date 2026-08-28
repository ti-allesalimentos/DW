/*
  Itens de nota fiscal de saida classificados como bonificacao/amostra
  gratis (CFOP 5910/5911/6910/6911), conformados.

  Mesma origem e mesmos joins do stg_faturamento (SD2010 + SF2010 + SA1010)
  — a unica diferenca de regra e o CFOP. Nao reaproveita o CTE de
  stg_faturamento porque dbt nao permite referenciar CTE de outro modelo;
  a duplicacao aqui e da consulta, nao da regra (a regra de conversao
  -CX e a mesma, no mesmo seed map_produto_cx).

  Nao tem excecoes_nf nem excecoes_cliente na query legada — so o cliente
  97316293 (mesmo excluido do faturamento) e o filtro de tipo "B".
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
        d2_desczfr                         as desconto_zfr,
        r_e_c_n_o_                         as recno_origem,
        _carregado_em
    from {{ source('bronze', 'sd2010') }}
    where d_e_l_e_t_ <> '*'

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

sf2010_dedup as (

    select distinct on (filial, nfe)
        filial, nfe, tipo_nf
    from (
        select
            {{ trim_protheus('f2_filial') }} as filial,
            {{ trim_protheus('f2_doc') }}    as nfe,
            {{ trim_protheus('f2_tipo') }}   as tipo_nf,
            _carregado_em
        from {{ source('bronze', 'sf2010') }}
        where d_e_l_e_t_ <> '*'
    ) f2
    order by filial, nfe, _carregado_em desc

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
    c.fator_conversao,
    c.total,
    (c.total + coalesce(c.desconto_zfr, 0))
        / nullif(c.qtd_origem * c.fator_conversao, 0) as preco_unit,
    c.recno_origem,
    c._carregado_em
from com_conversao c
join sf2010_dedup sf2
    on sf2.filial = c.filial
   and sf2.nfe = c.nfe
left join sa1010_dedup sa1
    on sa1.cod_cliente = c.cod_cliente
   and sa1.loja_cliente = c.loja_cliente
where c.cfop in (select cfop from {{ ref('cfops_bonificacao') }})
  and c.filial in (select filial from {{ ref('filiais_ativas') }})
  and c.cod_cliente not in (select cod_cliente from {{ ref('excecoes_cliente') }})
  and sf2.tipo_nf <> 'B'
