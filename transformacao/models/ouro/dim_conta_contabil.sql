/*
  Dimensao plano de contas (CT1010). Grao: codigo_conta.

  A query legada que gera essa lista ("PLANO DE CONTAS" em sqlConsulta,
  fFinanceiro.m) e codigo morto por dois motivos: (1) esta concatenada
  na mesma string SQL do saldo bancario sem separador, e o SQL Server
  so devolve o primeiro result set — o Power Query nunca chega a ler
  essa segunda consulta; (2) mesmo que lesse, o filtro
  `LEN(CT1_CONTA) = 8` nao bate com nenhuma conta hoje — o CT1010 atual
  so tem codigos de 1, 2, 4, 7, 10, 11, 12, 13, 14 ou 17 digitos
  (confirmado por contagem direta). Provavelmente a estrutura do plano
  de contas mudou depois que essa query foi escrita.

  Reconstruida aqui sem o filtro de tamanho, porque a intencao
  (decorar codigo_conta com descricao pro fato de saldo) e real e o
  filtro original so zerava o resultado.
*/

with contas as (

    select
        btrim(ct1_conta)                                          as codigo_conta,
        btrim(ct1_conta) || ' - ' || {{ trim_protheus('ct1_desc01') }} as descricao_conta,
        _carregado_em
    from {{ source('bronze', 'ct1010') }}
    where d_e_l_e_t_ <> '*'

),

dedup as (

    select distinct on (codigo_conta)
        codigo_conta, descricao_conta
    from contas
    order by codigo_conta, _carregado_em desc

)

select
    {{ dbt_utils.generate_surrogate_key(['codigo_conta']) }} as sk_conta_contabil,
    codigo_conta,
    descricao_conta
from dedup

union all

select
    {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }},
    'NAO_IDENTIFICADO', 'Conta não identificada'
