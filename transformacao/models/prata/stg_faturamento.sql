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
    -- C5_COMIS1/C5_COMIS3 sao o % de comissao PREVISTO no pedido pro
    -- vendedor (C5_VEND1) e pro gerente (C5_VEND3) -- previsibilidade,
    -- nao a comissao efetivada (que so existe na baixa do titulo, em
    -- fato_comissao, sem vinculo com NF/item -- decisao do Lucas, 01/10).
    select distinct on (filial, num_pedido)
        filial, num_pedido, cod_gerente,
        perc_comissao_vendedor, perc_comissao_gerente
    from (
        select
            {{ trim_protheus('c5_filial') }} as filial,
            {{ trim_protheus('c5_num') }}    as num_pedido,
            {{ trim_protheus('c5_vend3') }}  as cod_gerente,
            coalesce(c5_comis1, 0) / 100.0   as perc_comissao_vendedor,
            coalesce(c5_comis3, 0) / 100.0   as perc_comissao_gerente,
            _carregado_em
        from {{ source('bronze', 'sc5010') }}
        where d_e_l_e_t_ <> '*'
    ) c5
    order by filial, num_pedido, _carregado_em desc

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
    sa1.cod_vendedor,
    sa1.cod_supervisor,
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
    sc5.cod_gerente,
    sc5.perc_comissao_vendedor,
    sc5.perc_comissao_gerente,
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
