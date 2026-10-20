/*
  Refaturamento (reemissao de NF), conformado e agregado.

  Grao: filial + produto + NF + serie + data de emissao (o legado agrega
  por GROUP BY nesse nivel, nao por item — um pedido de refaturamento
  pode ter varios itens do mesmo produto na mesma nota).

  So notas cujo pedido de venda (SC5010) tem C5_X_REFAT preenchido —
  indicador de que a nota e uma reemissao, apontando pra nota original.

  Sem filtro de CFOP, sem exclusao de cliente/NF: a query legada nao
  tinha nenhuma das duas pra este fato.
*/

with itens as (

    select
        {{ trim_protheus('d2_filial') }}  as filial,
        {{ trim_protheus('d2_doc') }}     as nfe,
        coalesce(nullif(ltrim({{ trim_protheus('d2_serie') }}, '0'), ''), '0') as serie,
        {{ trim_protheus('d2_item') }}    as item_nf,
        {{ trim_protheus('d2_cod') }}     as cod_protheus,
        {{ trim_protheus('d2_cf') }}      as cfop,
        {{ trim_protheus('d2_um') }}      as um_origem,
        {{ trim_protheus('d2_pedido') }}  as num_pedido,
        {{ data_protheus('d2_emissao') }} as dt_emissao,
        d2_quant                          as qtd_origem,
        d2_total                          as total,
        d2_prcven                         as prcven_origem,
        r_e_c_n_o_                        as recno_origem
    from {{ source('bronze', 'sd2010') }}
    where d_e_l_e_t_ <> '*'
      and {{ trim_protheus('d2_filial') }} in (select filial from {{ ref('filiais_ativas') }})

),

itens_dedup as (

    -- mesma sujeira de serie duplicada encontrada no faturamento.
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

sc5010_dedup as (

    select distinct on (filial, num_pedido)
        filial, num_pedido, nf_origem_refatura
    from (
        select
            {{ trim_protheus('c5_filial') }}  as filial,
            {{ trim_protheus('c5_num') }}     as num_pedido,
            {{ trim_protheus('c5_x_refat') }} as nf_origem_refatura,
            _carregado_em
        from {{ source('bronze', 'sc5010') }}
        where d_e_l_e_t_ <> '*'
    ) c5
    order by filial, num_pedido, _carregado_em desc

),

com_conversao as (

    select
        i.*,
        coalesce(m.produto_base, i.cod_protheus) as cod_produto,
        coalesce(m.fator, 1)                     as fator_conversao,
        m.produto_base is not null                as convertido,
        sc5.nf_origem_refatura
    from itens_dedup i
    join sc5010_dedup sc5
        on sc5.filial = i.filial
       and sc5.num_pedido = i.num_pedido
    left join {{ ref('map_produto_cx') }} m
           on m.produto_cx = i.cod_protheus
    where sc5.nf_origem_refatura <> ''

)

select
    filial,
    cod_produto,
    nfe,
    serie,
    dt_emissao,
    cfop,
    -- pedido do zero a esquerda: RIGHT(REPLICATE('0',9) + numero, 9) no legado.
    lpad(nf_origem_refatura, 9, '0') as nf_origem_refatura,
    sum(qtd_origem * fator_conversao)                      as qtd,
    case when bool_or(convertido) then 'KG' else max(um_origem) end as um,
    max(prcven_origem) / max(fator_conversao)              as preco_unit,
    sum(total)                                             as total,
    min(recno_origem)                                      as recno_origem
from com_conversao
group by filial, cod_produto, nfe, serie, dt_emissao, cfop, nf_origem_refatura
