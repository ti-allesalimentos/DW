/*
  Segmentacao RFV (Recencia, Frequencia, Valor) por cliente. Grao:
  chave_cliente. Snapshot "hoje" = ultima data_emissao disponivel em
  fato_faturamento (nao refaz por filtro de periodo do dashboard).

  Replica a matriz de 11 segmentos do relatorio legado "Comercial"
  (docs/pbip_extraido/Comercial.md, medidas "$ 01. Clientes campeões" a
  "$ 11. Clientes perdidos") -- essa e a logica de negocio real, e e
  portavel porque trabalha em cima de NOTAS 1-5, nao de valor bruto.

  O que NAO e replicado: os cortes fixos de dias/qtd-notas/R$ das tabelas
  auxRecencia/auxFrequencia/auxValor do Power BI -- sao numeros digitados
  a mao, ilegiveis fora do Power BI Desktop, e decisao tomada com o
  usuario (2026-09-08) foi usar QUINTIS DINAMICOS: a cada rodada, os
  clientes sao divididos em 5 grupos iguais por recencia/frequencia/valor,
  em vez de faixas fixas que ficariam desatualizadas conforme o negocio
  cresce ou encolhe.

  "Valor" usa faturamento BRUTO dos ultimos 12 meses (mesma base que o
  nome da medida original, "$ Faturamento ultimos 12 meses", sem
  qualificar liquido/bruto).
*/

with referencia as (

    select max(data_emissao) as data_ref
    from {{ ref('fato_faturamento') }}

),

base_cliente as (

    select
        f.sk_cliente,
        max(f.data_emissao) as ultima_compra,
        count(distinct f.nfe) filter (
            where f.data_emissao > r.data_ref - interval '12 months'
        ) as notas_12m,
        sum(f.total) filter (
            where f.data_emissao > r.data_ref - interval '12 months'
        ) as valor_12m
    from {{ ref('fato_faturamento') }} f
    cross join referencia r
    group by f.sk_cliente

),

scores as (

    select
        b.*,
        r.data_ref,
        (r.data_ref - b.ultima_compra) as dias_desde_ultima_compra,
        -- ultima_compra ASC: quem comprou por ultimo (mais recente) cai no
        -- ultimo balde (5) -- sem inversao, e o resultado ja fica certo.
        ntile(5) over (order by b.ultima_compra asc)          as score_recencia,
        -- 5 = mais notas, 1 = menos notas
        ntile(5) over (order by coalesce(b.notas_12m, 0) asc) as score_frequencia,
        -- 5 = maior valor, 1 = menor valor
        ntile(5) over (order by coalesce(b.valor_12m, 0) asc)  as score_valor
    from base_cliente b
    cross join referencia r

),

classificado as (

    select
        s.*,
        (s.score_frequencia + s.score_valor) / 2.0 as score_fv,
        case
            when s.score_recencia > 4 and s.score_frequencia + s.score_valor > 8
                then 'Campeões'
            when s.score_recencia > 2 and (s.score_frequencia + s.score_valor) / 2.0 > 3
                then 'Fiéis'
            when s.score_recencia > 3 and (s.score_frequencia + s.score_valor) / 2.0 > 1
                 and (s.score_frequencia + s.score_valor) / 2.0 <= 3
                then 'Potenciais fiéis'
            when s.score_recencia > 4 and (s.score_frequencia + s.score_valor) / 2.0 <= 1
                then 'Recentes'
            when s.score_recencia = 2 and (s.score_frequencia + s.score_valor) / 2.0 = 2
                then 'Hibernando'
            when s.score_recencia > 3 and s.score_recencia <= 4
                 and (s.score_frequencia + s.score_valor) / 2.0 <= 1
                then 'Promissores'
            when s.score_recencia > 2 and s.score_recencia <= 3
                 and (s.score_frequencia + s.score_valor) / 2.0 > 2
                 and (s.score_frequencia + s.score_valor) / 2.0 <= 3
                then 'Precisam de atenção'
            when s.score_recencia > 2 and s.score_recencia <= 3
                 and (s.score_frequencia + s.score_valor) / 2.0 <= 2
                then 'Prestes a hibernar'
            when s.score_recencia <= 1 and (s.score_frequencia + s.score_valor) / 2.0 > 4
                then 'Não podemos perdê-los'
            when s.score_recencia <= 2 and (s.score_frequencia + s.score_valor) / 2.0 > 2
                then 'Em risco'
            when s.score_recencia <= 2 and (s.score_frequencia + s.score_valor) / 2.0 <= 2
                then 'Perdidos'
            else 'Sem classificação'
        end as segmento_rfv
    from scores s

)

select
    c.sk_cliente,
    c.data_ref,
    c.ultima_compra,
    c.dias_desde_ultima_compra,
    c.notas_12m,
    c.valor_12m,
    c.score_recencia,
    c.score_frequencia,
    c.score_valor,
    c.score_fv,
    c.segmento_rfv,
    case
        when c.dias_desde_ultima_compra <= 30 then 'Ativo'
        when c.dias_desde_ultima_compra <= 60 then 'Monitorado (31-60 dias)'
        when c.dias_desde_ultima_compra <= 90 then 'Alerta (61-90 dias)'
        else 'Inativo (mais de 90 dias)'
    end as status_atividade
from classificado c
