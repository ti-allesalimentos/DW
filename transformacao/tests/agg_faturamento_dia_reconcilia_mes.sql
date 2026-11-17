-- O agregado diario somado por mes tem que fechar com o mensal (liquido, bruto,
-- devolucao, desconto e kg), com tolerancia de R$ 1 / 1 kg: cada linha do agregado
-- e arredondada a 2 casas e o diario tem mais linhas (diferenca de centavos).
-- Qualquer linha devolvida e uma divergencia real.
with dia as (
    select to_char(data_emissao, 'YYYY-MM') as ano_mes,
           sum(valor_liquido) as liq, sum(valor_bruto) as bru, sum(valor_devolucao) as dev,
           sum(valor_desconto_comercial) as desc_, sum(kg_liquido) as kg
    from {{ ref('agg_faturamento_dia') }} group by 1
), mes as (
    select ano_mes,
           sum(valor_liquido) as liq, sum(valor_bruto) as bru, sum(valor_devolucao) as dev,
           sum(valor_desconto_comercial) as desc_, sum(kg_liquido) as kg
    from {{ ref('agg_faturamento_mes') }} group by 1
)
select coalesce(d.ano_mes, m.ano_mes) as ano_mes
from dia d full outer join mes m on m.ano_mes = d.ano_mes
where abs(coalesce(d.liq, 0) - coalesce(m.liq, 0)) > 1.0
   or abs(coalesce(d.bru, 0) - coalesce(m.bru, 0)) > 1.0
   or abs(coalesce(d.dev, 0) - coalesce(m.dev, 0)) > 1.0
   or abs(coalesce(d.desc_, 0) - coalesce(m.desc_, 0)) > 1.0
   or abs(coalesce(d.kg, 0) - coalesce(m.kg, 0)) > 1.0
