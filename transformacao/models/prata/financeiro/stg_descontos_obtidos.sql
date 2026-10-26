/*
  Descontos obtidos de fornecedores (SE2010, E2_DESCONT <> 0),
  conformado. Grao: recno_origem. Replica sqlfDescObtidos
  (fFinanceiro.m) — sem a exclusao de tipo que fato_contas_apagar tem,
  porque o legado tambem nao tem aqui.
*/

select
    {{ data_protheus('e2_emissao') }}  as dt_emissao,
    e2_descont                         as valor,
    {{ trim_protheus('e2_naturez') }}  as cod_natureza,
    {{ trim_protheus('e2_fornece') }}  as cod_fornecedor,
    {{ trim_protheus('e2_loja') }}     as loja_fornecedor,
    {{ trim_protheus('e2_fornece') }} || {{ trim_protheus('e2_loja') }} as chave_fornecedor,
    r_e_c_n_o_ as recno_origem,
    _carregado_em
from {{ source('bronze', 'se2010') }}
where d_e_l_e_t_ <> '*'
  and e2_descont <> 0
