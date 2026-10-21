/*
  Lancamento de estoque ligado a ordem de producao — consumo de massa/
  insumo (SD3010). Grao: recno_origem. Replica sqlLancamentos
  (APONTAMENTODEPRODUCAO.m).

  O legado filtra D3_FILIAL = '01004' — mas D3_TM > 500 aparece em 9
  filiais diferentes (confirmado direto no Protheus), entao esse nao e
  um filtro de negocio, e o escopo estreito de uma planilha feita pra
  acompanhar so a fabrica principal. Nao replicado aqui — o bronze
  mirrora, a prata nao restringe filial por conta de uma planilha.
*/

select
    {{ trim_protheus('sd3.d3_filial') }}   as filial,
    {{ data_protheus('sd3.d3_emissao') }}  as dt_emissao,
    sd3.d3_tm::int                          as tipo_movimento,
    {{ trim_protheus('sd3.d3_cod') }}      as cod_produto,
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
    case
        when {{ trim_protheus('sd3.d3_tipo') }} in ('MP', 'SP', 'II') then 'MASSA'
        else 'INSUMOS'
    end as classificacao,
    sd3.r_e_c_n_o_ as recno_origem,
    sd3._carregado_em
from {{ source('bronze', 'sd3010') }} sd3
inner join {{ source('bronze', 'sb1010') }} sb1
    on sb1.d_e_l_e_t_ <> '*'
   and sb1.b1_cod = sd3.d3_cod
where sd3.d_e_l_e_t_ <> '*'
  and btrim(sd3.d3_op) <> ''
  and btrim(sd3.d3_op) not like '%OS%'
  and {{ trim_protheus('sd3.d3_tipo') }} not in ('MO', 'PA')
  and {{ trim_protheus('sd3.d3_cod') }} <> 'MANUTENCAO'
  and sd3.d3_tm::int > 500
