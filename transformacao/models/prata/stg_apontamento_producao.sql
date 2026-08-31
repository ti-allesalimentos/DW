/*
  Apontamento de producao (SH6010) — operacao executada numa ordem de
  producao, com horario e quantidade produzida. Grao: recno_origem.
  Replica sqlProducao (APONTAMENTODEPRODUCAO.m).

  A descricao da operacao tem uma excecao de negocio real: os codigos
  '1' e 'AP' sempre viram "PRODUCAO HAMBURGUER"/"PRODUCAO ALMONDEGA",
  nao o que estiver cadastrado no SG2010 (roteiro) pra esses codigos —
  o legado faz exatamente isso, replicado aqui.

  SG2010 nao tem 3+ consumidores no legado (so essa query) — resolvido
  aqui, sem dimensao propria.

  G2_OPERAC nao e unico em SG2010 (ex.: operacao '1' aparece 33 vezes,
  com 4 descricoes diferentes) — o legado disfarca isso com um SELECT
  DISTINCT na saida, que so funciona porque as duplicatas problematicas
  ('1' e 'AP') tem a descricao sobrescrita pelo CASE acima de qualquer
  forma. Aqui deduplicamos o SG2010 antes do join, o que da o mesmo
  resultado sem depender dessa coincidencia.
*/

with sg2_dedup as (

    select distinct on (g2_operac)
        g2_operac, g2_descri, _carregado_em
    from {{ source('bronze', 'sg2010') }}
    where d_e_l_e_t_ <> '*'
    order by g2_operac, _carregado_em desc

)

select
    {{ trim_protheus('sh6.h6_filial') }}   as filial,
    {{ trim_protheus('sh6.h6_op') }}       as op,
    {{ trim_protheus('sh6.h6_produto') }}  as cod_produto,
    {{ trim_protheus('sh6.h6_operac') }}   as cod_operacao,
    case
        when {{ trim_protheus('sh6.h6_operac') }} = '1' then 'PRODUCAO HAMBURGUER'
        when {{ trim_protheus('sh6.h6_operac') }} = 'AP' then 'PRODUCAO ALMONDEGA'
        else coalesce({{ trim_protheus('sg2.g2_descri') }}, 'DESCONHECIDO')
    end as operacao,
    {{ trim_protheus('sh6.h6_recurso') }}  as recurso,
    {{ data_protheus('sh6.h6_dtprod') }}   as dt_producao,
    nullif(btrim(sh6.h6_horaini), '')::time as hora_inicio,
    nullif(btrim(sh6.h6_horafin), '')::time as hora_fim,
    sh6.h6_qtdprod                          as qtd_produzida,
    sh6.h6_qtdpro2                          as qtd_produzida_cx,
    {{ trim_protheus('sh6.h6_lotectl') }}  as lote,
    {{ trim_protheus('sh6.h6_ident') }}    as identificador,
    sh6.r_e_c_n_o_ as recno_origem,
    sh6._carregado_em
from {{ source('bronze', 'sh6010') }} sh6
inner join {{ source('bronze', 'sb1010') }} sb1
    on sb1.d_e_l_e_t_ <> '*'
   and sb1.b1_cod = sh6.h6_produto
left join sg2_dedup sg2
    on sg2.g2_operac = sh6.h6_operac
where sh6.d_e_l_e_t_ <> '*'
