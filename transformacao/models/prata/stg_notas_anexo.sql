/*
  NF de entrada (exceto SPED/CTE) com o anexo/documento digitalizado
  vinculado, quando existe (AC9010). Grao: recno_origem. Replica
  sqlfNotasSemAnexo (fFiscal.m) — apesar do nome legado, a query e um
  LEFT JOIN que traz TODAS as notas, com ou sem anexo; "sem anexo" e
  filtro aplicado na planilha (`WHERE tem_anexo = false` aqui).

  A chave de vinculo do AC9010 e a concatenacao NAO aparada dos campos
  de largura fixa (doc+serie+fornecedor+loja) — replicada bit a bit,
  sem trim_protheus, porque o legado tambem concatena o CHAR bruto.
*/

select
    {{ trim_protheus('f1.f1_filial') }}   as filial,
    {{ trim_protheus('f1.f1_especie') }}  as especie,
    {{ trim_protheus('f1.f1_doc') }}      as nfe,
    {{ trim_protheus('f1.f1_serie') }}    as serie,
    {{ trim_protheus('f1.f1_fornece') }}  as cod_fornecedor,
    {{ trim_protheus('f1.f1_loja') }}     as loja_fornecedor,
    {{ trim_protheus('f1.f1_fornece') }} || {{ trim_protheus('f1.f1_loja') }} as chave_fornecedor,
    {{ data_protheus('f1.f1_emissao') }}  as dt_emissao,
    ac9.ac9_codobj is not null as tem_anexo,
    {{ trim_protheus('ac9.ac9_codobj') }} as cod_objeto_anexo,
    f1.r_e_c_n_o_ as recno_origem,
    f1._carregado_em
from {{ source('bronze', 'sf1010') }} f1
left join {{ source('bronze', 'ac9010') }} ac9
    on ac9.d_e_l_e_t_ <> '*'
   and {{ trim_protheus('ac9.ac9_entida') }} = 'SF1'
   and f1.f1_filial = ac9.ac9_filent
   and f1.f1_doc || f1.f1_serie || f1.f1_fornece || f1.f1_loja = ac9.ac9_codent
where f1.d_e_l_e_t_ <> '*'
  and {{ trim_protheus('f1.f1_especie') }} not in ('SPED', 'CTE')
