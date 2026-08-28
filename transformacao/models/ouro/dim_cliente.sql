/*
  Dimensao cliente, conformada. Grao: chave_cliente (cod_cliente || loja).

  Membro "nao identificado" explicito: cobre o cliente que o de-para do
  DATAVALE nao conseguiu casar por CNPJ contra o SA1010 (~0,7% das linhas
  do historico DATAVALE — ver stg_faturamento_datavale.sql).
*/

with clientes as (

    select
        {{ trim_protheus('a1_cod') }}    as cod_cliente,
        {{ trim_protheus('a1_loja') }}   as loja_cliente,
        {{ trim_protheus('a1_nome') }}   as nome,
        {{ trim_protheus('a1_nreduz') }} as nome_reduzido,
        {{ trim_protheus('a1_est') }}    as uf,
        {{ trim_protheus('a1_mun') }}    as municipio,
        {{ trim_protheus('a1_cgc') }}    as cnpj,
        {{ trim_protheus('a1_vend') }}   as cod_vendedor,
        _carregado_em
    from {{ source('bronze', 'sa1010') }}
    where d_e_l_e_t_ <> '*'

),

dedup as (

    select distinct on (cod_cliente, loja_cliente) *
    from clientes
    order by cod_cliente, loja_cliente, _carregado_em desc

),

com_regiao as (

    select
        d.cod_cliente,
        d.loja_cliente,
        d.cod_cliente || d.loja_cliente as chave_cliente,
        d.nome,
        d.nome_reduzido,
        d.uf,
        d.municipio,
        d.cnpj,
        d.cod_vendedor,
        r.regiao
    from dedup d
    left join {{ ref('regiao') }} r on r.uf = d.uf

    union all

    select
        'NAO_IDENTIFICADO', '', 'NAO_IDENTIFICADO',
        'Cliente não identificado', null, null, null, null, null, null

)

select
    {{ dbt_utils.generate_surrogate_key(['chave_cliente']) }} as sk_cliente,
    chave_cliente,
    cod_cliente,
    loja_cliente,
    nome,
    nome_reduzido,
    uf,
    municipio,
    cnpj,
    cod_vendedor,
    regiao
from com_regiao
