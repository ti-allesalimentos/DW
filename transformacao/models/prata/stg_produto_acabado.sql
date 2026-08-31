/*
  Producao de produto acabado por OP (SD3010, TM='010'), agregada por
  filial/OP/produto. Grao: (filial, op, cod_produto) — sem chave
  natural de linha, o legado ja agrega assim. Replica sqlProdutoAcabado
  (fCusto.m).

  O legado filtra filial='01004' depois da consulta (Power Query), mas
  TM='010' tambem ocorre na filial 01006 (confirmado no bronze) — mesmo
  padrao ja visto no Industrial (Fase 6): escopo de planilha, nao regra
  de negocio. Nao replicado aqui.
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
    min({{ data_protheus('sd3.d3_emissao') }}) as dt_producao
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
  and sd3.d3_tm::int = 10
group by
    sd3.d3_filial, sc2.c2_produto, sd3.d3_op, sd3.d3_cod,
    sd3.d3_um, sd3.d3_tm, sd3.d3_grupo
