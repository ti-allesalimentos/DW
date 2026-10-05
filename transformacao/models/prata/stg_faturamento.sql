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

  Duas decisoes encontradas na reconciliacao contra o `dw.fato_faturamento`
  do piloto anterior (28/08/2026):

  1. `d2_serie` tem duas linhas fisicas identicas no Protheus para a mesma
     nota/item, diferindo so no padding ('1' e '01' — RECNOs 2218 e 2998
     do filial 01004/doc 000013482). Normaliza-se removendo zero a esquerda
     e deduplica-se pela chave completa, senao a mesma venda conta em dobro.
  2. Nota tipo "B" no cabecalho (SF2010.F2_TIPO) e bonificacao, nao venda —
     a query legada ja excluia isso (`F2_TIPO <> 'B'`), inclusive quando o
     item nao tem cabecalho correspondente no SF2010 (join sem match).
     Bonificacao tem fato proprio (fato_bonificacao, ainda por construir).
*/

with itens as (

    select
        {{ trim_protheus('d2_filial') }}   as filial,
        {{ trim_protheus('d2_doc') }}      as nfe,
        -- zero a esquerda inconsistente na origem (ver nota acima) — '01' e '1'
        -- sao a mesma serie.
        coalesce(nullif(ltrim({{ trim_protheus('d2_serie') }}, '0'), ''), '0') as serie,
        {{ trim_protheus('d2_item') }}     as item_nf,
        {{ trim_protheus('d2_cod') }}      as cod_protheus,
        {{ trim_protheus('d2_cliente') }}  as cod_cliente,
        {{ trim_protheus('d2_loja') }}     as loja_cliente,
        {{ trim_protheus('d2_pedido') }}   as num_pedido,
        {{ trim_protheus('d2_itempv') }}   as item_pedido,
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

itens_dedup as (

    select *
    from (
        select
            i.*,
            row_number() over (
                partition by filial, nfe, serie, item_nf
                order by recno_origem
            ) as linha
        from itens i
    ) x
    where linha = 1

),

sf2010_dedup as (

    -- Cabecalho da nota: usado pra identificar o tipo (bonificacao exclui,
    -- ver nota no topo) e como fallback da condicao de pagamento quando o
    -- cliente nao tem uma fixa (ver cod_condpgto mais abaixo).
    select distinct on (filial, nfe)
        filial, nfe, tipo_nf, cond_pgto_nf
    from (
        select
            {{ trim_protheus('f2_filial') }} as filial,
            {{ trim_protheus('f2_doc') }}    as nfe,
            {{ trim_protheus('f2_tipo') }}   as tipo_nf,
            {{ trim_protheus('f2_cond') }}   as cond_pgto_nf,
            _carregado_em
        from {{ source('bronze', 'sf2010') }}
        where d_e_l_e_t_ <> '*'
    ) f2
    order by filial, nfe, _carregado_em desc

),

se4010_dedup as (

    -- Desconto financeiro da condicao de pagamento (E4_DESCFIN) -- e o
    -- "%DESCFIN" do Power BI: percentual aplicado sobre o valor da linha
    -- conforme a condicao de pagamento do cliente (ou da nota, se o
    -- cliente nao tiver uma condicao fixa -- ver cod_condpgto abaixo).
    select distinct on (cod_condpgto)
        cod_condpgto, perc_descfin
    from (
        select
            {{ trim_protheus('e4_codigo') }}      as cod_condpgto,
            coalesce(e4_descfin, 0) / 100.0        as perc_descfin,
            _carregado_em
        from {{ source('bronze', 'se4010') }}
        where d_e_l_e_t_ <> '*'
    ) e4
    order by cod_condpgto, _carregado_em desc

),

sa3010_condespecial as (

    -- A1_VEND1 do cadastro do cliente referencia um segundo SA3010 --
    -- o "PF"/"BOLA" do negocio: um desconto/acordo especial por fora da
    -- comissao normal de venda, hoje preenchido em pouquissimos clientes.
    -- O codigo vem as vezes cru ("000008") e as vezes prefixado ("PF0018"
    -- para o codigo 000018) -- normaliza-se pelo valor numerico antes de
    -- casar com o cadastro, igual ao dedup de dim_vendedor.
    select distinct on (cod_pf)
        cod_pf, perc_condespecial
    from (
        select
            btrim(a3_cod)::int             as cod_pf,
            coalesce(a3_comis, 0) / 100.0  as perc_condespecial,
            _carregado_em
        from {{ source('bronze', 'sa3010') }}
        where d_e_l_e_t_ <> '*'
          and a3_cod ~ '^\d+$'
    ) sa3
    order by cod_pf, _carregado_em desc

),

com_conversao as (

    -- A conversao caixa -> quilo acontece UMA vez, aqui, pelo de-para.
    -- Produto fora do de-para mantem codigo, quantidade e unidade originais.
    select
        i.*,
        coalesce(m.produto_base, i.cod_protheus)      as cod_produto,
        coalesce(m.fator, 1)                          as fator_conversao,
        m.produto_base is not null                    as convertido
    from itens_dedup i
    left join {{ ref('map_produto_cx') }} m
           on m.produto_cx = i.cod_protheus

),

sc5010_dedup as (

    -- Gerente (C5_VEND3) vem do pedido, nao do cliente -- diferente do
    -- Supervisor (A1_VEND3, no cadastro do cliente, ver sa1010_dedup).
    -- Campos de comissao do pedido (C5_COMIS1/2/3 e flags C5_X_COMI1/3) --
    -- a cascata completa (item > pedido > cliente > cadastro) esta no
    -- select final, ver nota la.
    select distinct on (filial, num_pedido)
        filial, num_pedido, cod_gerente, cod_vendedor_pedido, cod_pf,
        comis1, comis2, comis3, x_comi1, x_comi3
    from (
        select
            {{ trim_protheus('c5_filial') }} as filial,
            {{ trim_protheus('c5_num') }}    as num_pedido,
            {{ trim_protheus('c5_vend3') }}  as cod_gerente,
            {{ trim_protheus('c5_vend1') }}  as cod_vendedor_pedido,
            {{ trim_protheus('c5_vend2') }}  as cod_pf,
            coalesce(c5_comis1, 0)           as comis1,
            coalesce(c5_comis2, 0)           as comis2,
            coalesce(c5_comis3, 0)           as comis3,
            {{ trim_protheus('c5_x_comi1') }} as x_comi1,
            {{ trim_protheus('c5_x_comi3') }} as x_comi3,
            _carregado_em
        from {{ source('bronze', 'sc5010') }}
        where d_e_l_e_t_ <> '*'
    ) c5
    order by filial, num_pedido, _carregado_em desc

),

sc6010_dedup as (

    -- Comissao no item do pedido de venda (C6_COMIS1/2/3) e flags "zera
    -- comissao?" (C6_X_COMI1/3: 1 = nao, 2 = sim) -- primeiro nivel da
    -- cascata de comissao.
    select distinct on (filial, num_pedido, item_pedido)
        filial, num_pedido, item_pedido, comis1, comis2, comis3, x_comi1, x_comi3
    from (
        select
            {{ trim_protheus('c6_filial') }}  as filial,
            {{ trim_protheus('c6_num') }}     as num_pedido,
            {{ trim_protheus('c6_item') }}    as item_pedido,
            coalesce(c6_comis1, 0)            as comis1,
            coalesce(c6_comis2, 0)            as comis2,
            coalesce(c6_comis3, 0)            as comis3,
            {{ trim_protheus('c6_x_comi1') }} as x_comi1,
            {{ trim_protheus('c6_x_comi3') }} as x_comi3,
            _carregado_em
        from {{ source('bronze', 'sc6010') }}
        where d_e_l_e_t_ <> '*'
    ) c6
    order by filial, num_pedido, item_pedido, _carregado_em desc

),

sa3010_comis as (

    -- Comissao padrao do cadastro de vendedores (A3_COMIS) -- ultimo nivel
    -- da cascata, vale pra vendedor, gerente e PF.
    select distinct on (cod_vendedor) cod_vendedor, perc_a3
    from (
        select
            {{ trim_protheus('a3_cod') }} as cod_vendedor,
            coalesce(a3_comis, 0)         as perc_a3,
            _carregado_em
        from {{ source('bronze', 'sa3010') }}
        where d_e_l_e_t_ <> '*'
    ) a3
    order by cod_vendedor, _carregado_em desc

),

sa1010_dedup as (

    -- O vendedor da nota nao vem do item (SD2 nao tem campo de vendedor);
    -- vem do cadastro do cliente (A1_VEND), igual a query legada. Um
    -- cliente+loja e unico no SA1010, mas o bronze traz o historico bruto
    -- (pode ter mais de um registro por chave se o cadastro foi alterado).
    select distinct on (cod_cliente, loja_cliente)
        {{ trim_protheus('a1_cod') }}  as cod_cliente,
        {{ trim_protheus('a1_loja') }} as loja_cliente,
        {{ trim_protheus('a1_vend') }} as cod_vendedor,
        {{ trim_protheus('a1_vend3') }} as cod_supervisor,
        {{ trim_protheus('a1_cond') }} as cond_pgto_cliente,
        coalesce(a1_comis, 0)          as comis_cliente,
        coalesce(a1_comis3, 0)         as comis3_cliente,
        nullif(regexp_replace(btrim(a1_vend1), '\D', '', 'g'), '')::int as cod_pf
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
    -- Vendedor: C5_VEND1 do pedido, com A1_VEND do cliente de fallback
    -- (Lucas, 05/10) -- antes era so A1_VEND, igual a query legada.
    coalesce(sc5.cod_vendedor_pedido, sa1.cod_vendedor) as cod_vendedor,
    -- Supervisor e Gerente sao o mesmo papel (decisao do Lucas, 05/10):
    -- C5_VEND3 do pedido, com A1_VEND3 do cliente como fallback.
    coalesce(sc5.cod_gerente, sa1.cod_supervisor)       as cod_supervisor,
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
    coalesce(nullif(sa1.cond_pgto_cliente, ''), sf2.cond_pgto_nf) as cod_condpgto,
    coalesce(se4.perc_descfin, 0)                                as perc_desconto_condpgto,
    coalesce(sa3pf.perc_condespecial, 0)                         as perc_desconto_condespecial,
    -- Desconto comercial por linha: (%DESCFIN + %CONDESPECIAL) * TOTAL,
    -- igual a "%DESCTOT" do Power BI. Aplicado sobre o bruto da linha, nao
    -- sobre o liquido de devolucao (o Power BI aplica sobre "Total - Dev";
    -- aqui a devolucao e tratada a parte, num join entre fatos -- ver
    -- fato_faturamento_liquido). Diferenca esperada: imaterial, so afeta
    -- linhas que foram vendidas E devolvidas dentro do mesmo recorte.
    c.total * (coalesce(se4.perc_descfin, 0) + coalesce(sa3pf.perc_condespecial, 0))
                                                                  as valor_desconto_comercial,
    coalesce(sc5.cod_gerente, sa1.cod_supervisor)       as cod_gerente,
    -- Comissao PREVISTA (nao a efetivada, que vem da baixa do titulo em
    -- fato_comissao), pela hierarquia do Protheus (Lucas, 05/10):
    --   1. item do pedido (SC6): C6_X_COMI = 2 zera o item; senao C6_COMIS > 0
    --   2. pedido (SC5): C5_X_COMI = 2 zera o pedido; senao C5_COMIS > 0
    --   3. cliente (SA1): A1_COMIS (vendedor) / A1_COMIS3 (gerente)
    --   4. cadastro do vendedor (SA3): A3_COMIS; 0 zera.
    -- Flag em branco conta como "1" (nao zera). Vendedor = C5_VEND1 com
    -- A1_VEND de fallback; gerente = C5_VEND3 com A1_VEND3; PF = C5_VEND2
    -- (percentual em COMIS2; nao ha flag X_COMI nem campo no cliente).
    coalesce(sc5.cod_vendedor_pedido, sa1.cod_vendedor) as cod_vendedor_comissao,
    sc5.cod_pf,
    cm.perc_vendedor                                    as perc_comissao_vendedor,
    cm.origem_vendedor                                  as origem_comissao_vendedor,
    cm.perc_gerente                                     as perc_comissao_gerente,
    cm.origem_gerente                                   as origem_comissao_gerente,
    cm.perc_pf                                          as perc_comissao_pf,
    c.recno_origem,
    c._carregado_em
from com_conversao c
left join sa1010_dedup sa1
    on sa1.cod_cliente = c.cod_cliente
   and sa1.loja_cliente = c.loja_cliente
join sf2010_dedup sf2
    on sf2.filial = c.filial
   and sf2.nfe = c.nfe
left join se4010_dedup se4
    on se4.cod_condpgto = coalesce(nullif(sa1.cond_pgto_cliente, ''), sf2.cond_pgto_nf)
left join sa3010_condespecial sa3pf
    on sa3pf.cod_pf = sa1.cod_pf
left join sc5010_dedup sc5
    on sc5.filial = c.filial
   and sc5.num_pedido = c.num_pedido
left join sc6010_dedup sc6
    on sc6.filial = c.filial
   and sc6.num_pedido = c.num_pedido
   and sc6.item_pedido = c.item_pedido
left join sa3010_comis sa3_v
    on sa3_v.cod_vendedor = coalesce(sc5.cod_vendedor_pedido, sa1.cod_vendedor)
left join sa3010_comis sa3_g
    on sa3_g.cod_vendedor = coalesce(sc5.cod_gerente, sa1.cod_supervisor)
left join sa3010_comis sa3_p
    on sa3_p.cod_vendedor = sc5.cod_pf
cross join lateral (
    select
        case
            when sc6.x_comi1 = '2' then 0
            when sc6.comis1 > 0 then sc6.comis1
            when sc5.x_comi1 = '2' then 0
            when sc5.comis1 > 0 then sc5.comis1
            when sa1.comis_cliente > 0 then sa1.comis_cliente
            else coalesce(sa3_v.perc_a3, 0)
        end / 100.0 as perc_vendedor,
        case
            when sc6.x_comi1 = '2' then 'item zerado'
            when sc6.comis1 > 0 then 'item'
            when sc5.x_comi1 = '2' then 'pedido zerado'
            when sc5.comis1 > 0 then 'pedido'
            when sa1.comis_cliente > 0 then 'cliente'
            when coalesce(sa3_v.perc_a3, 0) > 0 then 'cadastro'
            else 'sem comissao'
        end as origem_vendedor,
        case
            when sc6.x_comi3 = '2' then 0
            when sc6.comis3 > 0 then sc6.comis3
            when sc5.x_comi3 = '2' then 0
            when sc5.comis3 > 0 then sc5.comis3
            when sa1.comis3_cliente > 0 then sa1.comis3_cliente
            else coalesce(sa3_g.perc_a3, 0)
        end / 100.0 as perc_gerente,
        case
            when sc6.x_comi3 = '2' then 'item zerado'
            when sc6.comis3 > 0 then 'item'
            when sc5.x_comi3 = '2' then 'pedido zerado'
            when sc5.comis3 > 0 then 'pedido'
            when sa1.comis3_cliente > 0 then 'cliente'
            when coalesce(sa3_g.perc_a3, 0) > 0 then 'cadastro'
            else 'sem comissao'
        end as origem_gerente,
        case
            when sc5.cod_pf is null then 0
            when sc6.comis2 > 0 then sc6.comis2
            when sc5.comis2 > 0 then sc5.comis2
            else coalesce(sa3_p.perc_a3, 0)
        end / 100.0 as perc_pf
) cm
where c.cfop in (select cfop from {{ ref('cfops_venda') }})
  and c.filial in (select filial from {{ ref('filiais_ativas') }})
  and c.cod_cliente not in (
        select cod_cliente from {{ ref('excecoes_cliente') }}
        where dominio in ('todos', 'faturamento')
  )
  and sf2.tipo_nf <> 'B'
  and not exists (
        select 1
        from {{ ref('excecoes_nf') }} e
        where e.filial = c.filial
          and e.nfe    = c.nfe
          and e.dominio = 'faturamento'
  )
