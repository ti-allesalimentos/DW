/*
  Ordem de producao (SC2010), cabecalho com quantidades e datas
  planejadas/realizadas. Grao: recno_origem. Replica sqlStatusOP
  (APONTAMENTODEPRODUCAO.m) — a versao mais completa; sqlOP
  (mesmo arquivo) e um subconjunto restrito a filial 01004 com menos
  colunas, usado so pra achar o produto-pai de um reprocesso
  (replicado via join direto nesta mesma tabela em stg_reprocesso.sql,
  sem duplicar o dOP).

  A chave "OP" usada pelo legado pra cruzar com SD3010.D3_OP e a
  concatenacao NAO aparada de num+item+sequencia (largura fixa) —
  replicada bit a bit.
*/

select
    {{ trim_protheus('sc2.c2_filial') }}   as filial,
    sc2.c2_num || sc2.c2_item || sc2.c2_sequen as op,
    {{ trim_protheus('sc2.c2_num') }}      as numero,
    {{ trim_protheus('sc2.c2_item') }}     as item,
    {{ trim_protheus('sc2.c2_sequen') }}   as sequencia,
    {{ trim_protheus('sc2.c2_produto') }}  as cod_produto,
    sc2.c2_quant                            as qtd_prevista,
    {{ trim_protheus('sc2.c2_um') }}       as um,
    {{ data_protheus('sc2.c2_datpri') }}   as dt_prevista_inicio,
    {{ data_protheus('sc2.c2_datprf') }}   as dt_prevista_fim,
    {{ data_protheus('sc2.c2_emissao') }}  as dt_emissao,
    sc2.c2_quje                             as qtd_produzida,
    {{ data_protheus('sc2.c2_datrf') }}    as dt_fechamento,
    sc2.r_e_c_n_o_ as recno_origem,
    sc2._carregado_em
from {{ source('bronze', 'sc2010') }} sc2
inner join {{ source('bronze', 'sb1010') }} sb1
    on sb1.d_e_l_e_t_ <> '*'
   and sb1.b1_cod = sc2.c2_produto
where sc2.d_e_l_e_t_ <> '*'
  and {{ trim_protheus('sc2.c2_item') }} <> 'OS'
