/*
  Historico de preco de compra por produto (SC7010), com preco da
  compra anterior, media historica e desvio percentual — replica
  sqlHistCompra (fCompras.m), o fato mais valioso do dominio Compras
  ("historico de preco" citado explicitamente em arquitetura.md).
  Grao: recno_origem.

  Exclui produtos "SV%" (servico, nao produto fisico — mesmo criterio
  do legado). O recebimento agregado (OUTER APPLY no legado, aqui uma
  CTE agrupada + LEFT JOIN, mesmo resultado sem correlacao row-a-row)
  casa por (filial, pedido, item), nao por chave de fornecedor —
  entao soma o recebido mesmo que a NF de entrada seja de um
  fornecedor diferente do pedido (raro, mas replica fielmente o
  legado).
*/

with pedidos as (

    select
        {{ trim_protheus('c7_filial') }}   as filial,
        {{ trim_protheus('c7_num') }}      as pedido,
        {{ trim_protheus('c7_item') }}     as item,
        {{ data_protheus('c7_emissao') }}  as dt_emissao,
        {{ trim_protheus('c7_produto') }}  as cod_produto,
        c7_quant                            as qtd_pedida,
        c7_quje                             as qtd_entregue,
        c7_qtdacla                          as qtd_a_classificar,
        c7_preco                            as preco_unit,
        c7_total                            as valor_total,
        c7_moeda                             as cod_moeda,
        {{ trim_protheus('c7_fornece') }}  as cod_fornecedor,
        {{ trim_protheus('c7_loja') }}     as loja_fornecedor,
        {{ trim_protheus('c7_cond') }}     as cod_cond_pgto,
        {{ trim_protheus('c7_user') }}     as cod_comprador,
        {{ trim_protheus('c7_numsc') }}    as solicitacao,
        {{ trim_protheus('c7_itemsc') }}   as item_solicitacao,
        {{ trim_protheus('c7_conapro') }}  as cod_aprovacao,
        btrim(coalesce(c7_residuo, ''))     as residuo,
        {{ trim_protheus('c7_encer') }}    as status_encerramento,
        {{ data_protheus('c7_datprf') }}   as dt_prevista,
        {{ data_protheus('c7_dinicom') }}  as dt_inicio_compra,
        {{ data_protheus('c7_dinitra') }}  as dt_inicio_transito,
        r_e_c_n_o_ as recno_origem,
        _carregado_em
    from {{ source('bronze', 'sc7010') }}
    where d_e_l_e_t_ <> '*'
      and {{ trim_protheus('c7_produto') }} not like 'SV%'

),

calc as (

    select
        *,
        lag(preco_unit) over (
            partition by cod_produto order by dt_emissao, pedido, item
        ) as preco_anterior,
        avg(preco_unit) over (partition by cod_produto) as preco_medio_hist,
        count(*) over (partition by cod_produto) as qtd_compras_produto
    from pedidos

),

nomes as (

    select
        c.recno_origem,
        {{ trim_protheus('usr7.usr_nome') }} as comprador,
        {{ trim_protheus('sc1.c1_num') }}    as solicitacao_sc1,
        {{ trim_protheus('usr1.usr_nome') }} as solicitante
    from calc c
    left join {{ source('bronze', 'sys_usr') }} usr7
        on usr7.d_e_l_e_t_ <> '*' and usr7.usr_id = c.cod_comprador
    left join {{ source('bronze', 'sc1010') }} sc1
        on sc1.d_e_l_e_t_ <> '*'
       and sc1.c1_filial = c.filial
       and sc1.c1_num = c.solicitacao
       and sc1.c1_item = c.item_solicitacao
    left join {{ source('bronze', 'sys_usr') }} usr1
        on usr1.d_e_l_e_t_ <> '*' and usr1.usr_id = sc1.c1_user

),

recebido as (

    select
        {{ trim_protheus('d1_filial') }}  as filial,
        {{ trim_protheus('d1_pedido') }}  as pedido,
        {{ trim_protheus('d1_itempc') }}  as item,
        sum(d1_quant)                      as qtd_recebida_nf,
        sum(d1_total)                      as valor_recebido_nf,
        count(distinct btrim(d1_doc))      as qtde_notas,
        max({{ data_protheus('d1_dtdigit') }}) as ultima_entrada
    from {{ source('bronze', 'sd1010') }}
    where d_e_l_e_t_ <> '*'
    group by 1, 2, 3

)

select
    c.filial,
    c.pedido,
    c.item,
    c.dt_emissao,
    case
        when c.cod_aprovacao = 'R' then 'Rejeitado'
        when c.cod_aprovacao = 'B' then 'Em aprovacao'
        when c.residuo <> '' then 'Eliminado por residuo'
        when c.status_encerramento = 'E' then 'Encerrado'
        when c.qtd_pedida > 0 and c.qtd_entregue >= c.qtd_pedida then 'Recebido'
        when c.qtd_entregue > 0 then 'Recebido parcial'
        when c.qtd_a_classificar > 0 then 'Em recebimento'
        else 'Aprovado / em aberto'
    end as status_pedido,
    c.cod_fornecedor,
    c.loja_fornecedor,
    c.cod_fornecedor || c.loja_fornecedor as chave_fornecedor,
    c.cod_produto,
    c.qtd_pedida,
    c.qtd_entregue,
    c.qtd_compras_produto,
    c.cod_moeda,
    c.preco_unit,
    c.valor_total,
    case when c.qtd_pedida <> 0 then c.valor_total / c.qtd_pedida end as preco_unit_calc,
    c.preco_anterior,
    case when coalesce(c.preco_anterior, 0) <> 0
         then (c.preco_unit - c.preco_anterior) * 100.0 / c.preco_anterior end as var_pct_vs_anterior,
    c.preco_medio_hist,
    case when coalesce(c.preco_medio_hist, 0) <> 0
         then (c.preco_unit - c.preco_medio_hist) * 100.0 / c.preco_medio_hist end as desvio_pct_vs_media,
    n.comprador,
    c.solicitacao,
    c.item_solicitacao,
    n.solicitante,
    c.cod_cond_pgto,
    c.dt_inicio_compra,
    c.dt_inicio_transito,
    c.dt_prevista,
    r.qtd_recebida_nf,
    r.valor_recebido_nf,
    case when coalesce(r.qtd_recebida_nf, 0) <> 0
         then r.valor_recebido_nf / r.qtd_recebida_nf end as preco_unit_nf,
    r.qtde_notas,
    r.ultima_entrada,
    c.recno_origem,
    c._carregado_em
from calc c
left join nomes n on n.recno_origem = c.recno_origem
left join recebido r
    on r.filial = c.filial and r.pedido = c.pedido and r.item = c.item
