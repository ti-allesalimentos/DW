/*
  Dimensao produto, conformada. Grao: cod_produto ja resolvido pelo
  de-para caixa->quilo (o mesmo codigo usado em stg_faturamento).

  Membro "nao identificado" explicito: cobre produtos que aparecem num
  fato mas nao tem cadastro ativo no SB1010 (cap. 6 da arquitetura —
  orfao silencioso vira orfao visivel).
*/

with produtos as (

    select
        {{ trim_protheus('b1_cod') }}   as cod_produto,
        {{ trim_protheus('b1_desc') }}  as descricao,
        {{ trim_protheus('b1_tipo') }}  as tipo,
        {{ trim_protheus('b1_um') }}    as um_cadastro,
        {{ trim_protheus('b1_grupo') }} as grupo_estoque,
        _carregado_em
    from {{ source('bronze', 'sb1010') }}
    where d_e_l_e_t_ <> '*'

),

dedup as (

    select distinct on (cod_produto) *
    from produtos
    order by cod_produto, _carregado_em desc

),

com_familia as (

    select
        d.cod_produto,
        d.descricao,
        d.tipo,
        d.um_cadastro,
        d.grupo_estoque,
        f.familia,
        f.marca,
        f.sub_recorte,
        f.descricao_lousinha
    from dedup d
    left join {{ ref('familia') }} f on f.cod_produto = d.cod_produto

    union all

    select 'NAO_IDENTIFICADO', 'Produto não identificado', null, null, null, null, null, null, null

)

select
    {{ dbt_utils.generate_surrogate_key(['cod_produto']) }} as sk_produto,
    cod_produto,
    descricao,
    tipo,
    um_cadastro,
    grupo_estoque,
    familia,
    marca,
    sub_recorte,
    descricao_lousinha
from com_familia
