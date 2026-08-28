/*
  Itens de nota fiscal de saida, conformados.

  O que este modelo FAZ:
    - TRIM nos campos CHAR de largura fixa do Protheus
    - cast de datas (texto YYYYMMDD -> date), com a sentinela vazia -> NULL
    - monta a chave de cliente (codigo || loja)
    - aplica a delecao logica do Protheus, uma vez so e documentadamente
    - aplica as regras de negocio que estao nos seeds versionados:
      CFOPs de venda, filiais ativas, clientes e notas excluidos
    - aplica a conversao caixa -> quilo pelo de-para unico

  O que este modelo NAO faz:
    - nao agrega, nao calcula metrica, nao junta dimensao. Isso e ouro.

  Sobre a delecao logica: o legado divergia entre `D_E_L_E_T_ = ''` (relatorios
  da diretoria) e `<> '*'` (piloto anterior). O bronze traz a coluna crua; aqui
  a decisao acontece em UM lugar. Adotado `<> '*'`, que e a semantica do
  Protheus (marca de exclusao), e cobre tanto vazio quanto espaco.
*/

with itens as (

    select
        {{ trim_protheus('d2_filial') }}   as filial,
        {{ trim_protheus('d2_doc') }}      as nfe,
        {{ trim_protheus('d2_serie') }}    as serie,
        {{ trim_protheus('d2_item') }}     as item_nf,
        {{ trim_protheus('d2_cod') }}      as cod_protheus,
        {{ trim_protheus('d2_cliente') }}  as cod_cliente,
        {{ trim_protheus('d2_loja') }}     as loja_cliente,
        {{ trim_protheus('d2_pedido') }}   as num_pedido,
        {{ trim_protheus('d2_cf') }}       as cfop,
        {{ trim_protheus('d2_um') }}       as um_origem,
        {{ data_protheus('d2_emissao') }}  as dt_emissao,
        d2_quant                           as qtd_origem,
        d2_total                           as total,
        d2_desczfr                         as desconto_zfr,
        d2_picm                            as aliq_icms,
        d2_alqpis                          as aliq_pis,
        d2_alqcof                          as aliq_cofins,
        d2_icmsret                         as aliq_icmsst,
        r_e_c_n_o_                         as recno_origem,
        _carregado_em
    from {{ source('bronze', 'sd2010') }}
    where d_e_l_e_t_ <> '*'

),

com_conversao as (

    -- A conversao caixa -> quilo acontece UMA vez, aqui, pelo de-para.
    -- Produto fora do de-para mantem codigo, quantidade e unidade originais.
    select
        i.*,
        coalesce(m.produto_base, i.cod_protheus)      as cod_produto,
        coalesce(m.fator, 1)                          as fator_conversao,
        m.produto_base is not null                    as convertido
    from itens i
    left join {{ ref('map_produto_cx') }} m
           on m.produto_cx = i.cod_protheus

),

sa1010_dedup as (

    -- O vendedor da nota nao vem do item (SD2 nao tem campo de vendedor);
    -- vem do cadastro do cliente (A1_VEND), igual a query legada. Um
    -- cliente+loja e unico no SA1010, mas o bronze traz o historico bruto
    -- (pode ter mais de um registro por chave se o cadastro foi alterado).
    select distinct on (cod_cliente, loja_cliente)
        {{ trim_protheus('a1_cod') }}  as cod_cliente,
        {{ trim_protheus('a1_loja') }} as loja_cliente,
        {{ trim_protheus('a1_vend') }} as cod_vendedor
    from {{ source('bronze', 'sa1010') }}
    where d_e_l_e_t_ <> '*'
    order by cod_cliente, loja_cliente, _carregado_em desc

)

select
    c.filial,
    c.nfe,
    c.serie,
    c.item_nf,
    c.cod_protheus,
    c.cod_produto,
    c.cod_cliente || c.loja_cliente                     as chave_cliente,
    c.cod_cliente,
    c.loja_cliente,
    sa1.cod_vendedor,
    c.num_pedido,
    c.cfop,
    c.dt_emissao,
    c.qtd_origem * c.fator_conversao                    as qtd,
    case when c.convertido then 'KG' else c.um_origem end as um,
    c.fator_conversao,
    c.convertido,
    c.total,
    c.desconto_zfr,
    -- Preco unitario bruto: o desconto ZFR ja vem embutido no total,
    -- entao volta para o calculo. Regra herdada do modelo atual.
    (c.total + coalesce(c.desconto_zfr, 0))
        / nullif(c.qtd_origem * c.fator_conversao, 0)   as preco_unit,
    c.aliq_icms,
    c.aliq_pis,
    c.aliq_cofins,
    c.aliq_icmsst,
    c.recno_origem,
    c._carregado_em
from com_conversao c
left join sa1010_dedup sa1
    on sa1.cod_cliente = c.cod_cliente
   and sa1.loja_cliente = c.loja_cliente
where c.cfop in (select cfop from {{ ref('cfops_venda') }})
  and c.filial in (select filial from {{ ref('filiais_ativas') }})
  and c.cod_cliente not in (select cod_cliente from {{ ref('excecoes_cliente') }})
  and not exists (
        select 1
        from {{ ref('excecoes_nf') }} e
        where e.filial = c.filial
          and e.nfe    = c.nfe
  )
