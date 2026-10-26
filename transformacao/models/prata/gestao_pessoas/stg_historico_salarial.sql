/*
  Historico de alteracao de salario base (SR3010). Grao: recno_origem.
  Replica sqlHistoricoSalarial (fGestaoPessoas.m) — sem o corte
  R3_DATA > '20231201' do legado, que nao e regra de negocio (parece
  "desde quando comecei a olhar isso"); mirra o historico completo.
*/

select
    {{ trim_protheus('r3_filial') }}  as filial,
    {{ trim_protheus('r3_mat') }}     as matricula,
    {{ data_protheus('r3_data') }}    as dt_alteracao,
    r3_valor                            as valor,
    r_e_c_n_o_ as recno_origem,
    _carregado_em
from {{ source('bronze', 'sr3010') }}
where d_e_l_e_t_ <> '*'
  and {{ trim_protheus('r3_descpd') }} = 'SALARIO BASE'
