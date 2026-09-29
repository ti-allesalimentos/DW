/*
  Apontamento de hora extra (SPC010 uniao SPH010), agregado por
  funcionario x mes x tipo. Grao: chave_funcionario + ano_mes + tipo_he.
  Replica a extracao ja validada do Oryon Board (modulos/bi/gp_extract.py,
  SQL_HE_APONTAMENTOS).

  PD relevantes: 003/009 = HE 50%; 001/007 = HE DSR 100%; 008 = HE DIA NT
  100% (conta hora, mas nao gera valor — o multiplicador fica a cargo de
  quem consome). Conversao base-60 -> decimal, igual ao banco de horas.

  Sem corte de janela aqui — o Oryon Board olha so os ultimos ~15 meses,
  mas isso e decisao do mart/endpoint que consome, nao do fato (o ouro
  guarda o historico inteiro que existir no bronze).
*/

with apontamentos as (

    select
        {{ trim_protheus('pc_filial') }} || {{ trim_protheus('pc_mat') }} as chave_funcionario,
        {{ data_protheus('pc_data') }} as dt_apontamento,
        {{ trim_protheus('pc_pd') }} as cod_verba,
        floor(pc_quantc::numeric(12, 2))
            + (pc_quantc::numeric(12, 2) - floor(pc_quantc::numeric(12, 2))) / 0.6 as horas_decimais
    from {{ source('bronze', 'spc010') }}
    where d_e_l_e_t_ <> '*'
      and {{ trim_protheus('pc_pd') }} in ('001', '003', '007', '008', '009')

    union all

    select
        {{ trim_protheus('ph_filial') }} || {{ trim_protheus('ph_mat') }} as chave_funcionario,
        {{ data_protheus('ph_data') }} as dt_apontamento,
        {{ trim_protheus('ph_pd') }} as cod_verba,
        floor(ph_quantc::numeric(12, 2))
            + (ph_quantc::numeric(12, 2) - floor(ph_quantc::numeric(12, 2))) / 0.6 as horas_decimais
    from {{ source('bronze', 'sph010') }}
    where d_e_l_e_t_ <> '*'
      and {{ trim_protheus('ph_pd') }} in ('001', '003', '007', '008', '009')

),

classificado as (

    select
        chave_funcionario,
        to_char(dt_apontamento, 'YYYYMM')::int as ano_mes,
        case cod_verba
            when '003' then 'HE 50%'
            when '009' then 'HE 50%'
            when '001' then 'HE DSR 100%'
            when '007' then 'HE DSR 100%'
            when '008' then 'HE DIA NT 100%'
        end as tipo_he,
        horas_decimais
    from apontamentos
    where dt_apontamento is not null

)

select
    chave_funcionario,
    ano_mes,
    tipo_he,
    sum(horas_decimais) as horas
from classificado
where tipo_he is not null
group by chave_funcionario, ano_mes, tipo_he
