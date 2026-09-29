/*
  Banco de horas (SPI010), agregado por funcionario. Grao: chave_funcionario
  (filial || matricula) — replica a extracao ja validada do Oryon Board
  (modulos/bi/gp_extract.py, SQL_BANCO_HORAS): so lancamentos em aberto
  (PI_DTBAIX vazio), credito = verba '010', debito = verba '014'.

  PI_QUANT chega em formato "hora.minuto" (base 60), nao decimal —
  FLOOR(x) + (x - FLOOR(x))/0.6 converte pra horas decimais. A mesma
  conta aparece em stg_apontamento_hora_extra e no legado (fGestaoPessoas.m);
  vira transformacao unica aqui.
*/

with lancamentos as (

    select
        {{ trim_protheus('pi_filial') }} || {{ trim_protheus('pi_mat') }} as chave_funcionario,
        {{ trim_protheus('pi_pd') }} as cod_verba,
        floor(pi_quant::numeric(12, 2))
            + (pi_quant::numeric(12, 2) - floor(pi_quant::numeric(12, 2))) / 0.6 as horas_decimais,
        {{ data_protheus('pi_data') }} as dt_lancamento
    from {{ source('bronze', 'spi010') }}
    where d_e_l_e_t_ <> '*'
      and btrim(coalesce(pi_dtbaix, '')) = ''
      and {{ trim_protheus('pi_pd') }} in ('010', '014')

)

select
    chave_funcionario,
    sum(case when cod_verba = '010' then horas_decimais else 0 end) as credito_horas,
    sum(case when cod_verba = '014' then horas_decimais else 0 end) as debito_horas,
    sum(case when cod_verba = '010' then horas_decimais
             when cod_verba = '014' then -horas_decimais
        end) as saldo_horas,
    max(dt_lancamento) as dt_referencia
from lancamentos
group by chave_funcionario
