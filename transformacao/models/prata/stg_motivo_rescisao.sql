/*
  Motivo de rescisao com valor pago (SRG010+SRA010+RCC010+SRR010).
  Grao: filial+matricula+cod_motivo+data_demissao. Replica
  MOTIVORESCISAO.m — a versao completa (com o valor somado); o
  fMotivoRescisão de fGestaoPessoas.m e a mesma consulta sem o SRR010
  e sem o valor, um subconjunto estrito, nao reconstruido a parte.

  RCC010 e a tabela generica de parametrizacao de RH (como o SX5010 do
  Protheus comercial): RCC_CODIGO='S043' e a tabela de motivos de
  rescisao, e o codigo do motivo mora nas posicoes 2-3 de RCC_SEQUEN.
  A extracao por posicao (SUBSTRING) e sobre o campo bruto, sem trim —
  a posicao so faz sentido no CHAR de largura fixa original.
*/

select
    {{ trim_protheus('srg.rg_filial') }}  as filial,
    {{ trim_protheus('srg.rg_mat') }}     as matricula,
    {{ trim_protheus('sra.ra_nome') }}    as nome,
    {{ trim_protheus('srg.rg_tipores') }} as cod_motivo,
    btrim(substring(rcc.rcc_conteu from 3 for 30)) as motivo,
    {{ data_protheus('srg.rg_datadem') }} as dt_demissao,
    sum(srr.rr_valor)                       as valor
from {{ source('bronze', 'srg010') }} srg
join {{ source('bronze', 'sra010') }} sra
    on sra.d_e_l_e_t_ <> '*'
   and sra.ra_filial = srg.rg_filial
   and sra.ra_mat = srg.rg_mat
join {{ source('bronze', 'rcc010') }} rcc
    on rcc.d_e_l_e_t_ <> '*'
   and btrim(rcc.rcc_codigo) = 'S043'
   and substring(rcc.rcc_sequen from 2 for 2) = srg.rg_tipores
join {{ source('bronze', 'srr010') }} srr
    on srr.d_e_l_e_t_ <> '*'
   and srr.rr_filial = srg.rg_filial
   and srr.rr_mat = srg.rg_mat
where srg.d_e_l_e_t_ <> '*'
  and btrim(srr.rr_roteir) = 'RES'
  and {{ trim_protheus('srr.rr_pd') }} in ('528', 'A26', 'A28', 'A29', 'A77')
group by
    srg.rg_filial, srg.rg_mat, sra.ra_nome, srg.rg_tipores,
    rcc.rcc_conteu, srg.rg_datadem
