/*
  Pedido de compra (SC7010), com o status calculado pelo legado — uma
  cascata de 9 regras prioritarias (rejeitado > em aprovacao > recebido
  > pedido de contrato > eliminado por residuo > em recebimento >
  recebido parcial > autorizacao de entrega > aprovado > indefinido).
  Grao: recno_origem. Replica sqlPedCompra (fCompras.m).
*/

select
    {{ trim_protheus('sc7.c7_filial') }}   as filial,
    {{ trim_protheus('sc7.c7_fornece') }}  as cod_fornecedor,
    {{ trim_protheus('sc7.c7_loja') }}     as loja_fornecedor,
    {{ trim_protheus('sc7.c7_fornece') }} || {{ trim_protheus('sc7.c7_loja') }} as chave_fornecedor,
    {{ trim_protheus('sc7.c7_cond') }}     as cod_cond_pgto,
    {{ trim_protheus('sc7.c7_num') }}      as pedido,
    {{ trim_protheus('sc7.c7_item') }}     as item,
    {{ trim_protheus('sc7.c7_produto') }}  as cod_produto,
    {{ trim_protheus('sc7.c7_um') }}       as unidade,
    sc7.c7_quant                            as quantidade,
    sc7.c7_quje                             as qtd_entregue,
    sc7.c7_preco                            as valor_unitario,
    sc7.c7_total                            as valor_total,
    {{ trim_protheus('sc7.c7_encer') }}    as status_encerramento,
    {{ trim_protheus('usr7.usr_nome') }}   as comprador,
    {{ trim_protheus('sc1.c1_num') }}      as solicitacao,
    {{ trim_protheus('usr1.usr_nome') }}   as solicitante,
    {{ data_protheus('sc7.c7_emissao') }}  as dt_emissao,
    {{ data_protheus('sc7.c7_dinicom') }}  as dt_inicio_compra,
    {{ data_protheus('sc7.c7_dinitra') }}  as dt_inicio_transito,
    {{ data_protheus('sc7.c7_datprf') }}   as dt_entregue,
    btrim(sc7.c7_residuo)                   as residuo,
    {{ trim_protheus('sc7.c7_conapro') }}  as cod_aprovacao,
    {{ trim_protheus('sc7.c7_clvl') }}     as centro_resultado,
    case
        when {{ trim_protheus('sc7.c7_conapro') }} = 'R' then 'Rejeitado'
        when {{ trim_protheus('sc7.c7_conapro') }} = 'B'
             and sc7.c7_quje < sc7.c7_quant then 'Em aprovacao'
        when sc7.c7_quje >= sc7.c7_quant then 'Recebido'
        when btrim(coalesce(sc7.c7_contra, '')) <> ''
             and btrim(coalesce(sc7.c7_residuo, '')) <> '' then 'Pedido de Contrato'
        when btrim(coalesce(sc7.c7_residuo, '')) <> '' then 'PC Eliminado por Residuo'
        when sc7.c7_qtdacla > 0 then 'Em recebimento'
        when sc7.c7_quje <> 0 and sc7.c7_quje < sc7.c7_quant then 'Recebido parcial'
        when sc7.c7_tipo <> 1 then 'Autorizacao de Entrega'
        when sc7.c7_quje = 0
             and sc7.c7_qtdacla = 0
             and {{ trim_protheus('sc7.c7_conapro') }} <> 'B'
             and sc7.c7_tipo = 1
             and btrim(coalesce(sc7.c7_residuo, '')) = '' then 'Aprovado'
        else 'Status Indefinido'
    end as status_pedido,
    sc7.r_e_c_n_o_ as recno_origem,
    sc7._carregado_em
from {{ source('bronze', 'sc7010') }} sc7
left join {{ source('bronze', 'sc1010') }} sc1
    on sc1.d_e_l_e_t_ <> '*'
   and sc7.c7_filial = sc1.c1_filial
   and sc7.c7_numsc = sc1.c1_num
   and sc7.c7_itemsc = sc1.c1_item
left join {{ source('bronze', 'sys_usr') }} usr7
    on usr7.d_e_l_e_t_ <> '*'
   and sc7.c7_user = usr7.usr_id
left join {{ source('bronze', 'sys_usr') }} usr1
    on usr1.d_e_l_e_t_ <> '*'
   and sc1.c1_user = usr1.usr_id
where sc7.d_e_l_e_t_ <> '*'
