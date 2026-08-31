/*
  Saldo inicial de estoque por produto/local (SB9010, B9_DATA em
  branco — o registro de posicao inicial, sem competencia mensal).
  Grao: recno_origem. Replica sqlSaldoInicial (fCusto.m).
*/

select
    {{ trim_protheus('b9_filial') }}  as filial,
    {{ trim_protheus('b9_cod') }}     as cod_produto,
    {{ trim_protheus('b9_local') }}   as local_estoque,
    b9_qini                            as qtd_inicial,
    b9_vini1                           as valor_inicial,
    b9_cm1                             as custo_medio,
    r_e_c_n_o_ as recno_origem,
    _carregado_em
from {{ source('bronze', 'sb9010') }}
where d_e_l_e_t_ <> '*'
  and btrim(b9_data) = ''
