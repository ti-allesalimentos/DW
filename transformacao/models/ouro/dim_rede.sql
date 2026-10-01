/*
  Dimensao rede (grupo de cliente) — Protheus ACY010. Grao: cod_rede
  (ACY_GRPVEN). Resolvida no cadastro do cliente via SA1010.A1_GRPVEN —
  ver dim_cliente.sql.

  Membro "nao identificado" explicito: cobre o cliente cujo A1_GRPVEN nao
  bate com nenhum registro ativo do ACY010 (cadastro incompleto ou em
  branco — maioria dos clientes nao pertence a nenhuma rede).
*/

with redes as (

    select
        {{ trim_protheus('acy_grpven') }} as cod_rede,
        {{ trim_protheus('acy_descri') }} as nome_rede,
        _carregado_em
    from {{ source('bronze', 'acy010') }}
    where d_e_l_e_t_ <> '*'
      and acy_grpven !~ '^\s*$'

),

dedup as (

    select distinct on (cod_rede) cod_rede, nome_rede
    from redes
    order by cod_rede, _carregado_em desc

)

select
    {{ dbt_utils.generate_surrogate_key(['cod_rede']) }} as sk_rede,
    cod_rede,
    nome_rede
from dedup

union all

select
    {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }},
    'NAO_IDENTIFICADO',
    'Sem rede'
