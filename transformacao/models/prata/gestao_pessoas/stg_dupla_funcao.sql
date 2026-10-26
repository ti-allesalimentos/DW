/*
  Funcionarios com evento de dupla funcao ativo (RG1010, verba '174'
  sem data fim de pagamento). Grao: recno_origem. Replica
  sqdDuplaFuncao (fGestaoPessoas.m).
*/

select
    {{ trim_protheus('rg1_filial') }} as filial,
    {{ trim_protheus('rg1_mat') }}    as matricula,
    r_e_c_n_o_ as recno_origem,
    _carregado_em
from {{ source('bronze', 'rg1010') }}
where d_e_l_e_t_ <> '*'
  and {{ trim_protheus('rg1_pd') }} = '174'
  -- btrim() puro: igualdade com string vazia tem o mesmo risco do <>
  -- ja visto varias vezes — trim_protheus() viraria NULL, e
  -- NULL = '' tambem nunca e verdadeiro.
  and btrim(rg1_dfimpg) = ''
