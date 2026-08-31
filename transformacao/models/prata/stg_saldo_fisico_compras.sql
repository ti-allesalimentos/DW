/*
  Saldo fisico de estoque relevante pra compras (SB2010), agregado por
  filial+produto, somando so os locais de armazem usados pelo
  workbook original (EP, ES, MP, TE, 03, MN, ST — nao documentado o
  que cada sigla significa, replicado fielmente). Grao: filial +
  cod_produto. Replica sqlSaldoFisico (fCompras.m).
*/

select
    {{ trim_protheus('b2_filial') }}  as filial,
    {{ trim_protheus('b2_cod') }}     as cod_produto,
    sum(b2_qatu)                       as qtd_atual
from {{ source('bronze', 'sb2010') }}
where d_e_l_e_t_ <> '*'
  and {{ trim_protheus('b2_local') }} in ('EP', 'ES', 'MP', 'TE', '03', 'MN', 'ST')
group by b2_filial, b2_cod
having sum(b2_qatu) <> 0
