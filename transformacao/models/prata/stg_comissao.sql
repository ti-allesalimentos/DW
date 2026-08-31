/*
  Comissao sobre baixa de titulo (recebimento), Protheus SE5010. Grao:
  (filial, natureza, titulo, parcela, cliente, loja, tipo doc, seq) — nao
  e grao de NF nem de item; e o evento de baixa que libera a comissao,
  por isso o SUM(valor) agrupado (o legado ja agregava assim, ver
  docs/legado_m/fComissao.m).

  UNIAO de duas situacoes de baixa que geram comissao:
  - motivo 'NOR': baixa normal de titulo tipo NF;
  - motivo 'CMP' com "RA" no historico: compensacao/troca de titulo.

  Cascata de percentual (replica exata do legado, inclusive a assimetria
  entre vendedor e gerente):
  - vendedor: comissao do pedido (SC5.C5_COMIS1) se setada e != 0, senao
    comissao do cliente (SA1.A1_COMIS), senao comissao padrao do
    vendedor (SA3.A3_COMIS).
  - gerente: comissao padrao do supervisor (SA3.A3_COMIS) tem
    prioridade — so cai pra comissao do cliente (SA1.A1_COMIS3) se o
    supervisor nao tiver taxa propria. Sem override de pedido pro
    gerente (o legado nao tem essa cascata pro gerente).
  - "PF" (vendedor adicional do pedido, SC5.C5_VEND2): taxa fixa do
    pedido (SC5.C5_COMIS2), sem cascata; sem pedido casado vira 0 (nem
    toda baixa tem PF).

  O legado tambem faz LEFT JOIN de SA3010 via SA1.A1_VEND1, mas o
  resultado nunca aparece no SELECT nem no GROUP BY — omitido aqui de
  proposito, e nao por descuido.
*/

with baixa_normal as (

    select
        {{ trim_protheus('e5.e5_filorig') }} as filial,
        {{ trim_protheus('e5.e5_naturez') }} as cod_natureza,
        {{ trim_protheus('e5.e5_numero') }}  as titulo,
        {{ trim_protheus('e5.e5_parcela') }} as parcela,
        {{ trim_protheus('e5.e5_clifor') }}  as cod_cliente,
        {{ trim_protheus('e5.e5_loja') }}    as loja_cliente,
        {{ trim_protheus('e5.e5_tipodoc') }} as tipo_doc,
        e5.e5_seq                            as seq,
        max({{ data_protheus('se1.e1_emissao') }}) as dt_emissao,
        max({{ trim_protheus('e5.e5_tipo') }})      as tipo,
        sum(e5.e5_valor)                            as valor,
        max({{ trim_protheus('e5.e5_banco') }})     as banco,
        max({{ trim_protheus('e5.e5_agencia') }})   as agencia,
        max({{ trim_protheus('e5.e5_conta') }})     as conta,
        max({{ trim_protheus('e5.e5_histor') }})    as observacao,
        max({{ trim_protheus('e5.e5_benef') }})     as pagador,
        max({{ trim_protheus('sa1.a1_nome') }})     as cliente,
        max({{ trim_protheus('sa1.a1_mun') }})      as municipio,
        max({{ trim_protheus('sa1.a1_est') }})      as uf,
        max({{ data_protheus('e5.e5_data') }})      as dt_baixa,
        max({{ trim_protheus('e5.e5_motbx') }})     as motivo_baixa,
        max({{ trim_protheus('sa1.a1_vend') }})     as cod_vendedor,
        max({{ trim_protheus('sa3_ven.a3_nome') }}) as nome_vendedor,
        case
            when max(sc5.c5_comis1) is not null and max(sc5.c5_comis1) <> 0
                then max(sc5.c5_comis1) / 100
            when max(sa1.a1_comis) is not null and max(sa1.a1_comis) <> 0
                then max(sa1.a1_comis) / 100
            else max(sa3_ven.a3_comis) / 100
        end as perc_comiss_vendedor,
        max({{ trim_protheus('sa3_sup.a3_fornece') }}) as cod_gerente,
        max({{ trim_protheus('sa3_sup.a3_nome') }})     as nome_gerente,
        case
            when max(sa3_sup.a3_comis) = 0 or max(sa3_sup.a3_comis) is null
                then max(sa1.a1_comis3) / 100
            else max(sa3_sup.a3_comis) / 100
        end as perc_comiss_gerente,
        max({{ trim_protheus('sc5.c5_vend2') }})    as cod_pf,
        max({{ trim_protheus('sa3_pf1.a3_nome') }}) as nome_pf,
        max(sc5.c5_comis2) / 100                     as perc_comiss_pf,
        max({{ trim_protheus('e5.e5_documen') }})   as historico
    from {{ source('bronze', 'se5010') }} e5
    join {{ source('bronze', 'sa1010') }} sa1
        on {{ trim_protheus('sa1.a1_cod') }} = {{ trim_protheus('e5.e5_clifor') }}
       and {{ trim_protheus('sa1.a1_loja') }} = {{ trim_protheus('e5.e5_loja') }}
       and sa1.d_e_l_e_t_ <> '*'
    left join {{ source('bronze', 'se1010') }} se1
        on {{ trim_protheus('se1.e1_filial') }} = {{ trim_protheus('e5.e5_filorig') }}
       and {{ trim_protheus('se1.e1_num') }} = {{ trim_protheus('e5.e5_numero') }}
       and {{ trim_protheus('se1.e1_parcela') }} = {{ trim_protheus('e5.e5_parcela') }}
       and {{ trim_protheus('se1.e1_tipo') }} = {{ trim_protheus('e5.e5_tipo') }}
       and se1.d_e_l_e_t_ <> '*'
    left join {{ source('bronze', 'sa3010') }} sa3_ven
        on {{ trim_protheus('sa3_ven.a3_cod') }} = {{ trim_protheus('sa1.a1_vend') }}
       and sa3_ven.d_e_l_e_t_ <> '*'
    left join {{ source('bronze', 'sa3010') }} sa3_sup
        on {{ trim_protheus('sa3_sup.a3_cod') }} = {{ trim_protheus('sa1.a1_vend3') }}
       and sa3_sup.d_e_l_e_t_ <> '*'
    left join {{ source('bronze', 'sc5010') }} sc5
        on {{ trim_protheus('sc5.c5_filial') }} = {{ trim_protheus('e5.e5_filorig') }}
       and {{ trim_protheus('sc5.c5_nota') }} = {{ trim_protheus('e5.e5_numero') }}
       and sc5.d_e_l_e_t_ <> '*'
    left join {{ source('bronze', 'sa3010') }} sa3_pf1
        on {{ trim_protheus('sa3_pf1.a3_cod') }} = {{ trim_protheus('sc5.c5_vend2') }}
       and sa3_pf1.d_e_l_e_t_ <> '*'
    where e5.d_e_l_e_t_ <> '*'
      and {{ trim_protheus('e5.e5_motbx') }} = 'NOR'
      and {{ trim_protheus('e5.e5_tabori') }} = 'FK1'
      and {{ trim_protheus('e5.e5_tipo') }} = 'NF'
      and {{ trim_protheus('e5.e5_tipodoc') }} not in ('DC', 'ES', 'JR')
      and e5.e5_valor <> 0
      and {{ trim_protheus('e5.e5_dtcanbx') }} is null
    group by 1, 2, 3, 4, 5, 6, 7, 8

),

baixa_compensacao as (

    select
        {{ trim_protheus('e5.e5_filorig') }} as filial,
        {{ trim_protheus('e5.e5_naturez') }} as cod_natureza,
        {{ trim_protheus('e5.e5_numero') }}  as titulo,
        {{ trim_protheus('e5.e5_parcela') }} as parcela,
        {{ trim_protheus('e5.e5_clifor') }}  as cod_cliente,
        {{ trim_protheus('e5.e5_loja') }}    as loja_cliente,
        {{ trim_protheus('e5.e5_tipodoc') }} as tipo_doc,
        e5.e5_seq                            as seq,
        max({{ data_protheus('se1.e1_emissao') }}) as dt_emissao,
        max({{ trim_protheus('e5.e5_tipo') }})      as tipo,
        sum(e5.e5_valor)                            as valor,
        max({{ trim_protheus('e5.e5_banco') }})     as banco,
        max({{ trim_protheus('e5.e5_agencia') }})   as agencia,
        max({{ trim_protheus('e5.e5_conta') }})     as conta,
        max({{ trim_protheus('e5.e5_histor') }})    as observacao,
        max({{ trim_protheus('e5.e5_benef') }})     as pagador,
        max({{ trim_protheus('sa1.a1_nome') }})     as cliente,
        max({{ trim_protheus('sa1.a1_mun') }})      as municipio,
        max({{ trim_protheus('sa1.a1_est') }})      as uf,
        max({{ data_protheus('e5.e5_data') }})      as dt_baixa,
        max({{ trim_protheus('e5.e5_motbx') }})     as motivo_baixa,
        max({{ trim_protheus('sa1.a1_vend') }})     as cod_vendedor,
        max({{ trim_protheus('sa3_ven.a3_nome') }}) as nome_vendedor,
        case
            when max(sc5.c5_comis1) is not null and max(sc5.c5_comis1) <> 0
                then max(sc5.c5_comis1) / 100
            when max(sa1.a1_comis) is not null and max(sa1.a1_comis) <> 0
                then max(sa1.a1_comis) / 100
            else max(sa3_ven.a3_comis) / 100
        end as perc_comiss_vendedor,
        max({{ trim_protheus('sa3_sup.a3_fornece') }}) as cod_gerente,
        max({{ trim_protheus('sa3_sup.a3_nome') }})     as nome_gerente,
        case
            when max(sa3_sup.a3_comis) = 0 or max(sa3_sup.a3_comis) is null
                then max(sa1.a1_comis3) / 100
            else max(sa3_sup.a3_comis) / 100
        end as perc_comiss_gerente,
        max({{ trim_protheus('sc5.c5_vend2') }})    as cod_pf,
        max({{ trim_protheus('sa3_pf1.a3_nome') }}) as nome_pf,
        max(sc5.c5_comis2) / 100                     as perc_comiss_pf,
        max({{ trim_protheus('e5.e5_documen') }})   as historico
    from {{ source('bronze', 'se5010') }} e5
    join {{ source('bronze', 'sa1010') }} sa1
        on {{ trim_protheus('sa1.a1_cod') }} = {{ trim_protheus('e5.e5_clifor') }}
       and {{ trim_protheus('sa1.a1_loja') }} = {{ trim_protheus('e5.e5_loja') }}
       and sa1.d_e_l_e_t_ <> '*'
    left join {{ source('bronze', 'se1010') }} se1
        on {{ trim_protheus('se1.e1_filial') }} = {{ trim_protheus('e5.e5_filorig') }}
       and {{ trim_protheus('se1.e1_num') }} = {{ trim_protheus('e5.e5_numero') }}
       and {{ trim_protheus('se1.e1_parcela') }} = {{ trim_protheus('e5.e5_parcela') }}
       and {{ trim_protheus('se1.e1_tipo') }} = {{ trim_protheus('e5.e5_tipo') }}
       and se1.d_e_l_e_t_ <> '*'
    left join {{ source('bronze', 'sa3010') }} sa3_ven
        on {{ trim_protheus('sa3_ven.a3_cod') }} = {{ trim_protheus('sa1.a1_vend') }}
       and sa3_ven.d_e_l_e_t_ <> '*'
    left join {{ source('bronze', 'sa3010') }} sa3_sup
        on {{ trim_protheus('sa3_sup.a3_cod') }} = {{ trim_protheus('sa1.a1_vend3') }}
       and sa3_sup.d_e_l_e_t_ <> '*'
    left join {{ source('bronze', 'sc5010') }} sc5
        on {{ trim_protheus('sc5.c5_filial') }} = {{ trim_protheus('e5.e5_filorig') }}
       and {{ trim_protheus('sc5.c5_nota') }} = {{ trim_protheus('e5.e5_numero') }}
       and sc5.d_e_l_e_t_ <> '*'
    left join {{ source('bronze', 'sa3010') }} sa3_pf1
        on {{ trim_protheus('sa3_pf1.a3_cod') }} = {{ trim_protheus('sc5.c5_vend2') }}
       and sa3_pf1.d_e_l_e_t_ <> '*'
    where e5.d_e_l_e_t_ <> '*'
      and {{ trim_protheus('e5.e5_motbx') }} = 'CMP'
      and upper(coalesce({{ trim_protheus('e5.e5_documen') }}, '')) like '%RA%'
      and {{ trim_protheus('e5.e5_tabori') }} = 'FK1'
      and {{ trim_protheus('e5.e5_tipo') }} = 'NF'
      and {{ trim_protheus('e5.e5_tipodoc') }} not in ('DC', 'ES', 'JR')
      and e5.e5_valor <> 0
      and {{ trim_protheus('e5.e5_dtcanbx') }} is null
    group by 1, 2, 3, 4, 5, 6, 7, 8

),

uniao as (

    select *, 'normal' as origem_baixa from baixa_normal
    union all
    select *, 'compensacao' as origem_baixa from baixa_compensacao

)

select
    filial,
    cod_natureza,
    titulo,
    parcela,
    cod_cliente,
    loja_cliente,
    cod_cliente || loja_cliente as chave_cliente,
    tipo_doc,
    seq,
    origem_baixa,
    dt_emissao,
    dt_baixa,
    tipo,
    motivo_baixa,
    valor,
    banco,
    agencia,
    conta,
    observacao,
    pagador,
    cliente,
    municipio,
    uf,
    cod_vendedor,
    nome_vendedor,
    perc_comiss_vendedor,
    valor * perc_comiss_vendedor as vr_comissao_vendedor,
    cod_gerente,
    nome_gerente,
    perc_comiss_gerente,
    valor * perc_comiss_gerente as vr_comissao_gerente,
    cod_pf,
    nome_pf,
    coalesce(perc_comiss_pf, 0) as perc_comiss_pf,
    valor * coalesce(perc_comiss_pf, 0) as vr_comissao_pf,
    historico
from uniao
