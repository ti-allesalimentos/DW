/*
  Notas fiscais de servico (SF1010, especie 'NFS'), com as retencoes
  (IR/INSS/PIS/COFINS/CSLL/ISS). Grao: recno_origem. Replica
  sqlNotasServico (fFiscal.m).
*/

select
    {{ trim_protheus('f1_filial') }}   as filial,
    {{ data_protheus('f1_emissao') }}  as dt_emissao,
    {{ trim_protheus('f1_especie') }}  as especie,
    {{ trim_protheus('f1_doc') }}      as nfe,
    {{ trim_protheus('f1_serie') }}    as serie,
    {{ trim_protheus('f1_fornece') }}  as cod_fornecedor,
    {{ trim_protheus('f1_loja') }}     as loja_fornecedor,
    {{ trim_protheus('f1_fornece') }} || {{ trim_protheus('f1_loja') }} as chave_fornecedor,
    f1_valbrut                          as valor_bruto,
    f1_irrf                             as valor_irrf,
    f1_inss                             as valor_inss,
    f1_valpis                           as valor_pis,
    f1_valcofi                          as valor_cofins,
    f1_valcsll                          as valor_csll,
    f1_iss                              as valor_iss,
    r_e_c_n_o_ as recno_origem,
    _carregado_em
from {{ source('bronze', 'sf1010') }}
where d_e_l_e_t_ <> '*'
  and {{ trim_protheus('f1_especie') }} = 'NFS'
