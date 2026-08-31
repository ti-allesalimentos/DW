/*
  Lancamento de estoque indireto (SD3010, TM=505) — nao ligado a uma
  ordem de producao especifica, associado direto a centro de custo.
  Grao: recno_origem. Replica sqlIndiretosLanc
  (APONTAMENTODEPRODUCAO.m).
*/

select
    {{ trim_protheus('d3_filial') }}   as filial,
    d3_tm::int                          as tipo_movimento,
    {{ trim_protheus('d3_cod') }}      as cod_produto,
    {{ trim_protheus('d3_um') }}       as um,
    d3_quant                            as qtd,
    {{ trim_protheus('d3_cc') }}       as cod_centro_custo,
    {{ data_protheus('d3_emissao') }}  as dt_emissao,
    r_e_c_n_o_ as recno_origem,
    _carregado_em
from {{ source('bronze', 'sd3010') }}
where d_e_l_e_t_ <> '*'
  and btrim(d3_op) = ''
  and d3_tm::int = 505
