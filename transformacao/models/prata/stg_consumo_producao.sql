/*
  Consumo de materia-prima/insumo por OP (SD3010, CFOP contendo 'RE'),
  agregado por filial/OP/produto/dia. Grao: (filial, op, cod_produto,
  dt_entrada) — grao mais fino que stg_produto_acabado.sql (que agrega
  por OP+produto sem data), porque o legado agrupa por D3_EMISSAO aqui
  e nao la. Replica sqlConsumo (fCusto.m).
*/

select
    {{ trim_protheus('sd3.d3_filial') }}   as filial,
    {{ trim_protheus('sc2.c2_produto') }}  as cod_produto_pai,
    btrim(sd3.d3_op)                        as op,
    {{ trim_protheus('sd3.d3_cod') }}      as cod_produto,
    {{ trim_protheus('sd3.d3_um') }}       as um,
    sum(sd3.d3_quant)                       as qtd_total,
    sd3.d3_tm::int                          as tipo_movimento,
    {{ trim_protheus('sd3.d3_grupo') }}    as grupo_produto,
    {{ data_protheus('sd3.d3_emissao') }}  as dt_entrada
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
  and {{ trim_protheus('sd3.d3_cod') }} not like '%MOD%'
  and btrim(sd3.d3_op) not like '%OS%'
  and btrim(sd3.d3_cf) like '%RE%'
  -- D3_ESTORNO vem em branco (nao NULL) na maioria das linhas validas;
  -- trim_protheus() converteria '' em NULL e quebraria esse filtro de
  -- desigualdade (mesmo problema achado em stg_tarifas_bancarias,
  -- Fase 4/5) — btrim() puro preserva o comportamento correto.
  and btrim(sd3.d3_estorno) <> 'S'
group by
    sd3.d3_filial, sc2.c2_produto, sd3.d3_op, sd3.d3_cod,
    sd3.d3_um, sd3.d3_tm, sd3.d3_grupo, sd3.d3_emissao
