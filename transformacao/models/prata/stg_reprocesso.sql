/*
  Reprocesso de producao (SD3010, TM=200). Grao: recno_origem. Replica
  sqlReprocessos (APONTAMENTODEPRODUCAO.m), incluindo o produto-pai
  (produto da ordem de producao original, via join direto em
  stg_ordem_producao pela chave OP — o legado faz esse mesmo lookup
  via a query separada dOP, aqui resolvido inline).
*/

select
    {{ trim_protheus('sd3.d3_filial') }}   as filial,
    {{ data_protheus('sd3.d3_emissao') }}  as dt_emissao,
    sd3.d3_tm::int                          as tipo_movimento,
    {{ trim_protheus('sd3.d3_cod') }}      as cod_produto,
    op.cod_produto                          as cod_produto_pai,
    {{ trim_protheus('sd3.d3_local') }}    as armazem,
    {{ trim_protheus('sd3.d3_localiz') }}  as endereco,
    nullif(btrim(sd3.d3_hora), '')::time as horario,
    {{ trim_protheus('sd3.d3_um') }}       as um,
    sd3.d3_quant                            as qtd,
    {{ trim_protheus('sd3.d3_lotectl') }}  as lote,
    btrim(sd3.d3_op)                        as op,
    {{ trim_protheus('sd3.d3_numseq') }}   as id_sequencia,
    {{ trim_protheus('sd3.d3_tipo') }}     as tipo,
    {{ trim_protheus('sd3.d3_usuario') }}  as usuario,
    sd3.r_e_c_n_o_ as recno_origem,
    sd3._carregado_em
from {{ source('bronze', 'sd3010') }} sd3
inner join {{ source('bronze', 'sb1010') }} sb1
    on sb1.d_e_l_e_t_ <> '*'
   and sb1.b1_cod = sd3.d3_cod
left join {{ ref('stg_ordem_producao') }} op
    on op.op = btrim(sd3.d3_op)
where sd3.d_e_l_e_t_ <> '*'
  and sd3.d3_tm::int = 200
  and btrim(sd3.d3_op) <> ''
