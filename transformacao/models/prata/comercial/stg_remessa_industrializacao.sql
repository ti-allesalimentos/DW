/*
  Remessa para industrializacao (CFOP 5901/5903/6901/6903), conformada.
  Grao: item de nota fiscal.

  ATENCAO: a aba fRemTriangular do fFaturamento.xlsx tinha a query
  IDENTICA a fRemIndustrializacao (mesmos CFOPs, mesmos filtros) — sem
  nada que as diferencie. O piloto anterior (dw.fato_remessa) resolveu
  isso populando so o tipo "INDUSTRIALIZACAO"; mantido aqui pela mesma
  razao ate alguem do negocio confirmar se as duas deveriam ser
  distintas. Ver legado/ingestion/queries/rem_triangular.sql.

  Vendedor vem do cabecalho da nota (SF2.F2_VEND1), diferente do
  faturamento/bonificacao (que pegam do cadastro do cliente) -- assim
  que a query legada fazia aqui, sem SA1010 no join.
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
      and {{ trim_protheus('d2_cliente') }} not in (
            select cod_cliente from {{ ref('excecoes_cliente') }}
            where dominio in ('todos', 'remessa')
      )

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
        filial, nfe, cod_vendedor, estado
    from (
        select
            {{ trim_protheus('f2_filial') }} as filial,
            {{ trim_protheus('f2_doc') }}    as nfe,
            {{ trim_protheus('f2_vend1') }}  as cod_vendedor,
            {{ trim_protheus('f2_est') }}    as estado,
            _carregado_em
        from {{ source('bronze', 'sf2010') }}
        where d_e_l_e_t_ <> '*'
    ) f2
    order by filial, nfe, _carregado_em desc

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
    sf2.cod_vendedor,
    sf2.estado,
    c.cfop,
    c.dt_emissao,
    c.qtd_origem * c.fator_conversao as qtd,
    case when c.convertido then 'KG' else c.um_origem end as um,
    c.prcven_origem / c.fator_conversao as preco_unit,
    c.total,
    c.recno_origem,
    c._carregado_em
from com_conversao c
left join sf2010_dedup sf2
    on sf2.filial = c.filial
   and sf2.nfe = c.nfe
where c.cfop in (select cfop from {{ ref('cfops_remessa_industrializacao') }})
