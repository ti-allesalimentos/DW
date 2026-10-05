/*
  Fato comissao — Protheus (SE5010, baixa de titulo). Grao: evento de
  baixa (filial, natureza, titulo, parcela, cliente, loja, tipo doc,
  seq, origem da baixa) — nao e grao de NF nem de item, ver stg_comissao.

  Carrega tres papeis de comissao na mesma linha (vendedor, gerente e
  "PF"), cada um com seu proprio percentual e valor, porque e assim que
  o legado libera o pagamento — nao ha uma linha por papel.

  Percentuais e responsaveis seguem a HIERARQUIA DO PROTHEUS (Lucas,
  05/10/2026: item SC6 > pedido SC5 > cliente SA1 > cadastro SA3, com os
  flags "zera comissao" X_COMI), aplicada na NF que originou o titulo: o
  percentual da baixa e a media ponderada pelo bruto dos itens da NF
  (fato_faturamento, por filial + numero da NF) e vendedor/gerente/PF sao
  os de maior valor na NF. Baixa de NF que nao esta no fato_faturamento
  (anterior ao historico ou fora das regras de venda) mantem a cascata do
  legado (stg_comissao) — regra_comissao diz qual valeu. Os percentuais
  do legado ficam em *_legado pra auditoria.
*/

with base as (

    select
        *,
        {{ dbt_utils.generate_surrogate_key([
            'filial', 'cod_natureza', 'titulo', 'parcela',
            'cod_cliente', 'loja_cliente', 'tipo_doc', 'seq', 'origem_baixa'
        ]) }} as sk_comissao
    from {{ ref('stg_comissao') }}

),

nf as (

    select
        filial,
        nfe,
        sum(vr_comissao_vendedor) / nullif(sum(total), 0) as perc_vendedor,
        sum(vr_comissao_gerente)  / nullif(sum(total), 0) as perc_gerente,
        sum(vr_comissao_pf)       / nullif(sum(total), 0) as perc_pf,
        (array_agg(sk_vendedor_comissao order by total desc))[1] as sk_vendedor,
        (array_agg(sk_gerente order by total desc))[1]           as sk_gerente,
        (array_agg(sk_pf order by total desc))[1]                as sk_pf
    from {{ ref('fato_faturamento') }}
    group by 1, 2

)

select
    f.sk_comissao,
    f.filial,
    f.cod_natureza,
    f.titulo,
    f.parcela,
    f.tipo_doc,
    f.seq,
    f.origem_baixa,
    f.dt_emissao as data_emissao,
    f.dt_baixa as data_baixa,
    f.tipo,
    f.motivo_baixa,
    coalesce(dc.sk_cliente, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_cliente,
    f.valor,
    f.banco,
    f.agencia,
    f.conta,
    f.observacao,
    f.pagador,
    coalesce(nf.sk_vendedor, dv.sk_vendedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_vendedor,
    coalesce(nf.perc_vendedor, f.perc_comiss_vendedor) as perc_comiss_vendedor,
    f.valor * coalesce(nf.perc_vendedor, f.perc_comiss_vendedor) as vr_comissao_vendedor,
    coalesce(nf.sk_gerente, dg.sk_vendedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_gerente,
    coalesce(nf.perc_gerente, f.perc_comiss_gerente) as perc_comiss_gerente,
    f.valor * coalesce(nf.perc_gerente, f.perc_comiss_gerente) as vr_comissao_gerente,
    coalesce(nf.sk_pf, dp.sk_vendedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_pf,
    coalesce(nf.perc_pf, f.perc_comiss_pf) as perc_comiss_pf,
    f.valor * coalesce(nf.perc_pf, f.perc_comiss_pf) as vr_comissao_pf,
    case when nf.nfe is not null then 'hierarquia protheus' else 'legado (NF fora do faturamento)' end as regra_comissao,
    f.perc_comiss_vendedor as perc_comiss_vendedor_legado,
    f.perc_comiss_gerente as perc_comiss_gerente_legado,
    f.perc_comiss_pf as perc_comiss_pf_legado,
    f.historico
from base f
left join {{ ref('dim_cliente') }} dc on dc.chave_cliente = f.chave_cliente
left join {{ ref('dim_vendedor') }} dv on dv.cod_vendedor = f.cod_vendedor
left join {{ ref('dim_vendedor') }} dg on dg.cod_vendedor = f.cod_gerente
left join {{ ref('dim_vendedor') }} dp on dp.cod_vendedor = f.cod_pf
left join nf on nf.filial = f.filial and nf.nfe = f.titulo
