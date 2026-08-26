/*
  Dimensao calendario, gerada por codigo — substitui o dCalendario.xlsx.

  Fonte da verdade da logica: docs/legado_m/dCalendario.m (Power Query).
  Reproduz fielmente o que a planilha legada calcula hoje, mesmo onde a
  regra e estranha (ver nota sobre ano fiscal abaixo) — corrigir fica para
  quando isso for validado com o time de negocio, nao para esta migracao.

  Ano fiscal (Abr-Mar): a formula do legado usa
  `Date.AddMonths([Data], 12 - 3)` para achar o ano de inicio do FY, o que
  produz um resultado que nao bate com a intuicao: uma data de JANEIRO de
  2024 cai no "FY 2024-2025" (Abr/2024 a Mar/2025), um ano fiscal que
  comeca DEPOIS da propria data — o correto seria subtrair 3 meses, nao
  somar 9. Replicado aqui de proposito, identico ao original, porque o
  criterio desta fase e fidelidade ao que ja roda, nao correcao.

  Feriados: a mesma lista fixa (nacionais + os de Sao Paulo capital/estado:
  Aniversario da Cidade, Revolucao Constitucionalista) e aplicada a todas
  as datas, sem distincao por filial — e assim que a planilha atual
  funciona, nao ha feriado municipal por filial hoje. Um calendario por
  filial fica para quando isso for pedido explicitamente.
*/

{% set data_inicio = '2015-01-01' %}
{% set data_fim = '2035-12-31' %}

with datas as (

    select generate_series(
        '{{ data_inicio }}'::date,
        '{{ data_fim }}'::date,
        interval '1 day'
    )::date as data

),

anos as (

    select distinct extract(year from data)::int as ano
    from datas

),

-- Algoritmo de Meeus/Jones/Butcher para a Pascoa gregoriana, em etapas.
-- Validado contra o dCalendario.xlsx: 2024-03-31, 2025-04-20, 2026-04-05.
pascoa_1 as (
    select
        ano,
        mod(ano, 19)::int  as a,
        (ano / 100)::int   as b,
        mod(ano, 100)::int as c
    from anos
),
pascoa_2 as (
    select *,
        (b / 4)::int         as d,
        mod(b, 4)::int       as e,
        ((b + 8) / 25)::int  as f
    from pascoa_1
),
pascoa_3 as (
    select *,
        ((b - f + 1) / 3)::int as g
    from pascoa_2
),
pascoa_4 as (
    select *,
        mod(19*a + b - d - g + 15, 30)::int as h,
        (c / 4)::int   as i,
        mod(c, 4)::int as k
    from pascoa_3
),
pascoa_5 as (
    select *,
        mod(32 + 2*e + 2*i - h - k, 7)::int as l
    from pascoa_4
),
pascoa_6 as (
    select *,
        ((a + 11*h + 22*l) / 451)::int as m
    from pascoa_5
),
pascoa as (
    select
        ano,
        make_date(
            ano,
            ((h + l - 7*m + 114) / 31)::int,
            (mod(h + l - 7*m + 114, 31) + 1)::int
        ) as data_pascoa
    from pascoa_6
),

feriados_moveis as (
    select data_pascoa - 2 as data, 'Sexta-Feira Santa' as feriado from pascoa
    union all
    select data_pascoa,      'Páscoa'                   from pascoa
    union all
    select data_pascoa + 60, 'Corpus Christi'            from pascoa
),

feriados_fixos as (
    select
        make_date(ano, fx.mes, fx.dia) as data,
        fx.feriado
    from anos
    cross join (values
        (1,   1, 'Confraternização Universal'),
        (1,  25, 'Aniversário da Cidade'),
        (4,  21, 'Tiradentes'),
        (5,   1, 'Dia do Trabalhador'),
        (7,   9, 'Revolução Constitucionalista'),
        (9,   7, 'Independência do Brasil'),
        (10, 12, 'N. Srª Aparecida'),
        (11,  2, 'Finados'),
        (11, 15, 'Proclamação da República'),
        (11, 20, 'Consciência Negra'),
        (12, 24, 'Véspera de Natal'),
        (12, 25, 'Natal'),
        (12, 31, 'Véspera de Ano Novo')
    ) as fx(mes, dia, feriado)
),

feriados as (
    select data, string_agg(feriado, '/' order by feriado) as feriado
    from (
        select * from feriados_fixos
        union all
        select * from feriados_moveis
    ) tudo
    group by data
),

base as (

    select
        d.data,
        extract(year from d.data)::int    as ano,
        extract(month from d.data)::int   as mes,
        extract(day from d.data)::int     as dia,
        extract(quarter from d.data)::int as trimestre,
        extract(isodow from d.data)::int  as dia_semana_numero,  -- 1=segunda ... 7=domingo
        f.feriado
    from datas d
    left join feriados f on f.data = d.data

)

select
    data,
    ano,
    mes,
    case mes
        when 1 then 'Janeiro' when 2 then 'Fevereiro' when 3 then 'Março'
        when 4 then 'Abril'   when 5 then 'Maio'      when 6 then 'Junho'
        when 7 then 'Julho'   when 8 then 'Agosto'    when 9 then 'Setembro'
        when 10 then 'Outubro' when 11 then 'Novembro' when 12 then 'Dezembro'
    end as mes_nome,
    trimestre,
    dia,
    case dia_semana_numero
        when 1 then 'Segunda-Feira' when 2 then 'Terça-Feira'
        when 3 then 'Quarta-Feira'  when 4 then 'Quinta-Feira'
        when 5 then 'Sexta-Feira'   when 6 then 'Sábado'
        when 7 then 'Domingo'
    end as dia_semana_nome,
    feriado,
    case when feriado is null and dia_semana_numero < 6 then 1 else 0 end as dia_util,
    -- Ano fiscal Abr-Mar. Ver nota no topo do arquivo sobre a regra herdada.
    case when mes <= 3 then ano else ano + 1 end as ano_fiscal_inicio,
    'FY ' || (case when mes <= 3 then ano else ano + 1 end)::text
        || '-' || (case when mes <= 3 then ano else ano + 1 end + 1)::text as ano_fiscal,
    case when mes > 3 then mes - 3 else mes + 9 end as mes_fiscal_numero,
    case mes
        when 1 then 'Janeiro' when 2 then 'Fevereiro' when 3 then 'Março'
        when 4 then 'Abril'   when 5 then 'Maio'      when 6 then 'Junho'
        when 7 then 'Julho'   when 8 then 'Agosto'    when 9 then 'Setembro'
        when 10 then 'Outubro' when 11 then 'Novembro' when 12 then 'Dezembro'
    end as mes_fiscal_nome
from base
order by data
