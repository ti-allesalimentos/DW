/*
  Descontos concedidos a clientes (SE1010, E1_DESCONT <> 0), conformado.
  Grao: recno_origem. Replica sqlfDescConcedidos (fFinanceiro.m).
*/

select
    {{ data_protheus('e1_emissao') }}  as dt_emissao,
    e1_descont                         as valor,
    {{ trim_protheus('e1_naturez') }}  as cod_natureza,
    {{ trim_protheus('e1_cliente') }}  as cod_cliente,
    {{ trim_protheus('e1_loja') }}     as loja_cliente,
    {{ trim_protheus('e1_cliente') }} || {{ trim_protheus('e1_loja') }} as chave_cliente,
    r_e_c_n_o_ as recno_origem,
    _carregado_em
from {{ source('bronze', 'se1010') }}
where d_e_l_e_t_ <> '*'
  and e1_descont <> 0
