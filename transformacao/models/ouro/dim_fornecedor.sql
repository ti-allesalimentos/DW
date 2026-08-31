/*
  Dimensao fornecedor, conformada. Grao: chave_fornecedor (cod_fornecedor
  || loja). Espelha dim_cliente — mesmo SA2010, mesma logica de
  de-para de regiao por UF.

  Endereco/bairro/cep/email/grupo_tributario adicionados na Fase 8
  (Compras) — dCompras.m (sqlFornecedor) usa esses campos e nao fazia
  sentido criar uma segunda dimensao de fornecedor so por isso.
*/

with fornecedores as (

    select
        {{ trim_protheus('a2_cod') }}     as cod_fornecedor,
        {{ trim_protheus('a2_loja') }}    as loja_fornecedor,
        {{ trim_protheus('a2_nome') }}    as nome,
        {{ trim_protheus('a2_nreduz') }}  as nome_reduzido,
        {{ trim_protheus('a2_end') }}     as endereco,
        {{ trim_protheus('a2_bairro') }}  as bairro,
        {{ trim_protheus('a2_est') }}     as uf,
        {{ trim_protheus('a2_mun') }}     as municipio,
        {{ trim_protheus('a2_cep') }}     as cep,
        {{ trim_protheus('a2_email') }}   as email,
        {{ trim_protheus('a2_cgc') }}     as cnpj,
        {{ trim_protheus('a2_grptrib') }} as cod_grupo_tributario,
        _carregado_em
    from {{ source('bronze', 'sa2010') }}
    where d_e_l_e_t_ <> '*'

),

dedup as (

    select distinct on (cod_fornecedor, loja_fornecedor) *
    from fornecedores
    order by cod_fornecedor, loja_fornecedor, _carregado_em desc

),

com_regiao as (

    select
        d.cod_fornecedor,
        d.loja_fornecedor,
        d.cod_fornecedor || d.loja_fornecedor as chave_fornecedor,
        d.nome,
        d.nome_reduzido,
        d.endereco,
        d.bairro,
        d.uf,
        d.municipio,
        d.cep,
        d.email,
        d.cnpj,
        d.cod_grupo_tributario,
        r.regiao
    from dedup d
    left join {{ ref('regiao') }} r on r.uf = d.uf

    union all

    select
        'NAO_IDENTIFICADO', '', 'NAO_IDENTIFICADO',
        'Fornecedor não identificado', null, null, null, null, null, null,
        null, null, null, null

)

select
    {{ dbt_utils.generate_surrogate_key(['chave_fornecedor']) }} as sk_fornecedor,
    chave_fornecedor,
    cod_fornecedor,
    loja_fornecedor,
    nome,
    nome_reduzido,
    endereco,
    bairro,
    uf,
    municipio,
    cep,
    email,
    cnpj,
    cod_grupo_tributario,
    regiao
from com_regiao
