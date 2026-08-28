/*
  Itens de nota fiscal de entrada por devolucao de venda (SD1010),
  conformados. Grao: item de NF de devolucao.

  Regras herdadas de legado/ingestion/queries/devolucoes.sql:
    - CFOP de devolucao (seed cfops_devolucao) OU tipo "D" sem CFOP
    - so codigo de produto contendo "PA" (produto acabado)
    - cliente excluido (seed excecoes_cliente, dominio devolucao)
    - serie nao pode conter "AC"
    - precisa ter cabecalho correspondente no SF1010 com status preenchido
      (join com SF1010 e INNER no legado -- sem cabecalho, sem devolucao)
    - motivo e destino vem de campos do Protheus reaproveitados
      (D1_COR e D1_CHASSI, respectivamente) -- resolvidos aqui contra os
      seeds motivo_dev e destino, mas mantidos como sigla crua tambem,
      porque ha codigos no bronze sem entrada nos seeds (ex.: "SFT",
      "RPP") -- nao documentados no legado, ficam visiveis como NULL
      na descricao em vez de escondidos.

  Diferenca deliberada do legado: a exclusao logica usa `D_E_L_E_T_ <> '*'`
  em vez de `= ''`, pela mesma decisao unica de stg_faturamento.
*/

with itens as (

    select
        {{ trim_protheus('d1_filial') }}  as filial,
        {{ trim_protheus('d1_doc') }}     as nf,
        coalesce(nullif(ltrim({{ trim_protheus('d1_serie') }}, '0'), ''), '0') as serie,
        {{ trim_protheus('d1_item') }}    as item_nf,
        {{ trim_protheus('d1_cod') }}     as cod_protheus,
        {{ trim_protheus('d1_fornece') }} as cod_cliente,
        {{ trim_protheus('d1_loja') }}    as loja_cliente,
        {{ trim_protheus('d1_cf') }}      as cfop,
        {{ trim_protheus('d1_tipo') }}    as tipo,
        {{ trim_protheus('d1_um') }}      as um_origem,
        {{ data_protheus('d1_emissao') }}  as dt_emissao,
        {{ data_protheus('d1_dtdigit') }}  as dt_lancamento,
        d1_quant                          as qtd_origem,
        d1_vunit                          as vunit_origem,
        d1_total - coalesce(d1_valdesc, 0) as total,
        {{ trim_protheus('d1_itemori') }} as item_origem,
        {{ trim_protheus('d1_nfori') }}   as nf_origem,
        {{ trim_protheus('d1_cor') }}     as motivo_dev_sigla,
        {{ trim_protheus('d1_chassi') }}  as destino_sigla,
        r_e_c_n_o_                        as recno_origem,
        _carregado_em
    from {{ source('bronze', 'sd1010') }}
    where d_e_l_e_t_ <> '*'
      and d1_cod like '%PA%'
      and {{ trim_protheus('d1_serie') }} not like '%AC%'

),

itens_dedup as (

    -- filial+nf+serie+item_nf NAO e unico no SD1010: o Protheus reaproveita
    -- numero de documento de entrada entre fornecedores diferentes (achado
    -- na reconciliacao: doc 000014021 na filial 01004 e duas notas de
    -- fornecedores distintos, meses e valores completamente diferentes).
    -- A chave real inclui cliente+loja, igual ao join com SF1010 abaixo.
    select *
    from (
        select i.*,
            row_number() over (
                partition by filial, nf, serie, cod_cliente, loja_cliente, item_nf
                order by recno_origem
            ) as linha
        from itens i
    ) x
    where linha = 1

),

sf1010_dedup as (

    -- Cabecalho da entrada: precisa existir e ter status preenchido,
    -- igual ao INNER JOIN + F1_STATUS <> '' do legado.
    select distinct on (filial, doc, serie, fornece, loja)
        filial, doc, serie, fornece, loja, status
    from (
        select
            {{ trim_protheus('f1_filial') }}  as filial,
            {{ trim_protheus('f1_doc') }}     as doc,
            coalesce(nullif(ltrim({{ trim_protheus('f1_serie') }}, '0'), ''), '0') as serie,
            {{ trim_protheus('f1_fornece') }} as fornece,
            {{ trim_protheus('f1_loja') }}    as loja,
            {{ trim_protheus('f1_status') }}  as status,
            _carregado_em
        from {{ source('bronze', 'sf1010') }}
        where d_e_l_e_t_ <> '*'
    ) f1
    order by filial, doc, serie, fornece, loja, _carregado_em desc

),

sf2010_dedup as (

    -- So pra saber a data de emissao da NF de venda original (D1_NFORI),
    -- referenciada pela mesma filial.
    select distinct on (filial, nfe)
        filial, nfe, dt_emissao_original
    from (
        select
            {{ trim_protheus('f2_filial') }}  as filial,
            {{ trim_protheus('f2_doc') }}     as nfe,
            {{ data_protheus('f2_emissao') }} as dt_emissao_original,
            _carregado_em
        from {{ source('bronze', 'sf2010') }}
        where d_e_l_e_t_ <> '*'
    ) f2
    order by filial, nfe, _carregado_em desc

),

com_conversao as (

    select
        i.*,
        coalesce(m.produto_base, i.cod_protheus) as cod_produto,
        coalesce(m.fator, 1)                     as fator_conversao,
        m.produto_base is not null                as convertido
    from itens_dedup i
    left join {{ ref('map_produto_cx') }} m
           on m.produto_cx = i.cod_protheus

)

select
    c.filial,
    c.nf,
    c.serie,
    c.item_nf,
    c.cod_protheus,
    c.cod_produto,
    c.cod_cliente || c.loja_cliente as chave_cliente,
    c.cod_cliente,
    c.loja_cliente,
    c.cfop,
    c.dt_emissao,
    c.dt_lancamento,
    c.qtd_origem * c.fator_conversao as qtd,
    case when c.convertido then 'KG' else c.um_origem end as um,
    c.fator_conversao,
    c.vunit_origem / c.fator_conversao as preco_unit,
    c.total,
    c.item_origem,
    c.nf_origem,
    sf2.dt_emissao_original,
    c.motivo_dev_sigla,
    md.motivo as motivo_dev_descricao,
    c.destino_sigla,
    d.descricao as destino_descricao,
    c.recno_origem,
    c._carregado_em
from com_conversao c
join sf1010_dedup sf1
    on sf1.filial = c.filial
   and sf1.doc = c.nf
   and sf1.serie = c.serie
   and sf1.fornece = c.cod_cliente
   and sf1.loja = c.loja_cliente
   and sf1.status <> ''
left join sf2010_dedup sf2
    on sf2.filial = c.filial
   and sf2.nfe = c.nf_origem
left join {{ ref('motivo_dev') }} md on md.sigla = c.motivo_dev_sigla
left join {{ ref('destino') }} d on d.sigla = c.destino_sigla
where (
        c.cfop in (select cfop from {{ ref('cfops_devolucao') }})
        or (c.tipo = 'D' and c.cfop = '')
      )
  and c.cod_cliente not in (
        select cod_cliente from {{ ref('excecoes_cliente') }}
        where dominio in ('todos', 'devolucao')
  )
  and not exists (
        select 1
        from {{ ref('excecoes_nf') }} e
        where e.filial = c.filial
          and e.nfe    = c.nf
          and e.dominio = 'devolucao'
  )
