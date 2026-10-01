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
        {{ trim_protheus('a1_grpven') }} as cod_rede,
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
        d.cod_rede,
        r.regiao
    from dedup d
    left join {{ ref('regiao') }} r on r.uf = d.uf

    union all

    select
        'NAO_IDENTIFICADO', '', 'NAO_IDENTIFICADO',
        'Cliente não identificado', null, null, null, null, null, null, null

)

select
    {{ dbt_utils.generate_surrogate_key(['com_regiao.chave_cliente']) }} as sk_cliente,
    com_regiao.chave_cliente,
    com_regiao.cod_cliente,
    com_regiao.loja_cliente,
    com_regiao.nome,
    com_regiao.nome_reduzido,
    com_regiao.uf,
    com_regiao.municipio,
    com_regiao.cnpj,
    com_regiao.cod_vendedor,
    com_regiao.regiao,
    coalesce(rede.sk_rede, rede_ni.sk_rede)     as sk_rede,
    coalesce(rede.cod_rede, 'NAO_IDENTIFICADO') as cod_rede,
    coalesce(rede.nome_rede, rede_ni.nome_rede) as nome_rede
from com_regiao
left join {{ ref('dim_rede') }} rede on rede.cod_rede = com_regiao.cod_rede
left join {{ ref('dim_rede') }} rede_ni on rede_ni.cod_rede = 'NAO_IDENTIFICADO'
