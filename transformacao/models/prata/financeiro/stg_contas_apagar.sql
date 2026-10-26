/*
  Titulos a pagar (SE2010), conformados. Grao: recno_origem — SE2010 ja
  e titulo/parcela, sem necessidade de dedup ou agregacao.

  Exclui E2_TIPO IN ('FT','NDF','PA','PRE') — regra do legado
  (sqlContasApagar/fContasApagar). O mesmo workbook tem uma segunda
  versao da query (sqlbase_pagar/base_pagar) SEM essa exclusao, so
  acrescentando CNPJ do fornecedor. As duas nao podem ser "a" contas a
  pagar ao mesmo tempo — adotamos a com exclusao porque e a que o
  inventario do legado (docs/inventario_dw_legado.md) associa ao fato
  canonico `fato_contas_pagar`; a versao sem filtro parece existir so
  para alimentar o de-para de classificacao (Fazer_dePara, no mesmo
  arquivo), nao como fato de consumo. Documentado tambem em
  docs/reconciliacao_financeiro.md.
*/

select
    {{ trim_protheus('e2_filial') }}   as filial,
    {{ trim_protheus('e2_prefixo') }}  as prefixo,
    {{ trim_protheus('e2_num') }}      as titulo,
    {{ trim_protheus('e2_parcela') }}  as parcela,
    {{ trim_protheus('e2_tipo') }}     as tipo,
    {{ trim_protheus('e2_naturez') }}  as cod_natureza,
    {{ trim_protheus('e2_fornece') }}  as cod_fornecedor,
    {{ trim_protheus('e2_loja') }}     as loja_fornecedor,
    {{ trim_protheus('e2_fornece') }} || {{ trim_protheus('e2_loja') }} as chave_fornecedor,
    {{ data_protheus('e2_emissao') }}  as dt_emissao,
    {{ data_protheus('e2_vencrea') }}  as dt_vencimento_real,
    {{ trim_protheus('e2_x_reneg') }}  as renegociado,
    e2_juros                           as juros,
    e2_valliq                          as valor_liquido,
    {{ data_protheus('e2_baixa') }}    as dt_baixa,
    {{ trim_protheus('e2_formpag') }}  as forma_pagamento,
    e2_valor                           as valor,
    e2_saldo                           as saldo,
    {{ trim_protheus('e2_x_prior') }}  as prioridade,
    {{ trim_protheus('e2_x_sit') }}    as situacao,
    e2_decresc                         as decrescimo,
    {{ trim_protheus('e2_fatura') }}   as fatura,
    {{ trim_protheus('e2_numliq') }}   as liquidacao,
    r_e_c_n_o_                         as recno_origem,
    _carregado_em
from {{ source('bronze', 'se2010') }}
where d_e_l_e_t_ <> '*'
  and {{ trim_protheus('e2_tipo') }} not in ('FT', 'NDF', 'PA', 'PRE')
