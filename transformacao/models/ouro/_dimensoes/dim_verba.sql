/*
  Dimensao verba de folha (SRV010), conformada. Grao: cod_verba.
  Replica sqldVerbas (fGestaoPessoas.m) — so os campos de identificacao;
  o legado seleciona a tabela inteira (126 colunas de parametrizacao de
  calculo), sem uso analitico direto alem de codigo/descricao/tipo.
*/

with verbas as (

    select
        {{ trim_protheus('rv_cod') }}      as cod_verba,
        {{ trim_protheus('rv_desc') }}     as descricao,
        {{ trim_protheus('rv_tipo') }}     as tipo,
        _carregado_em
    from {{ source('bronze', 'srv010') }}
    where d_e_l_e_t_ <> '*'

),

dedup as (

    select distinct on (cod_verba)
        cod_verba, descricao, tipo
    from verbas
    order by cod_verba, _carregado_em desc

)

select
    {{ dbt_utils.generate_surrogate_key(['cod_verba']) }} as sk_verba,
    cod_verba,
    descricao,
    tipo
from dedup

union all

select
    {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }},
    'NAO_IDENTIFICADO', 'Verba não identificada', null
