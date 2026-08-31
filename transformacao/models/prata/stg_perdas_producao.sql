/*
  Perdas de producao por OP (SD3010, TM='507'), agregada por
  filial/OP/produto/dia. Grao: (filial, op, cod_produto, dt_lancamento).
  Replica sqlPerdas (fCusto.m) — sem UM/grupo no output, o legado
  tambem nao traz.
*/

select
    {{ trim_protheus('sd3.d3_filial') }}   as filial,
    {{ trim_protheus('sc2.c2_produto') }}  as cod_produto_pai,
    btrim(sd3.d3_op)                        as op,
    {{ trim_protheus('sd3.d3_cod') }}      as cod_produto,
    sum(sd3.d3_quant)                       as qtd_total,
    {{ data_protheus('sd3.d3_emissao') }}  as dt_lancamento
from {{ source('bronze', 'sd3010') }} sd3
inner join {{ source('bronze', 'sc2010') }} sc2
    on sc2.d_e_l_e_t_ <> '*'
   and sc2.c2_filial = sd3.d3_filial
   and sc2.c2_num || sc2.c2_item || sc2.c2_sequen = btrim(sd3.d3_op)
inner join {{ source('bronze', 'sb1010') }} sb1_pai
    on sb1_pai.d_e_l_e_t_ <> '*'
   and sb1_pai.b1_cod = sc2.c2_produto
inner join {{ source('bronze', 'sb1010') }} sb1_filho
    on sb1_filho.d_e_l_e_t_ <> '*'
   and sb1_filho.b1_cod = sd3.d3_cod
where sd3.d_e_l_e_t_ <> '*'
  and btrim(sd3.d3_op) <> ''
  and sd3.d3_tm::int = 507
  -- D3_ESTORNO vem em branco (nao NULL) na maioria das linhas validas;
  -- trim_protheus() converteria '' em NULL e quebraria esse filtro de
  -- desigualdade (mesmo problema achado em stg_tarifas_bancarias,
  -- Fase 4/5) — btrim() puro preserva o comportamento correto.
  and btrim(sd3.d3_estorno) <> 'S'
group by
    sd3.d3_filial, sc2.c2_produto, sd3.d3_op, sd3.d3_cod, sd3.d3_emissao
