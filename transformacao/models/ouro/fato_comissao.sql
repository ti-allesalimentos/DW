/*
  Fato comissao — Protheus (SE5010, baixa de titulo). Grao: evento de
  baixa (filial, natureza, titulo, parcela, cliente, loja, tipo doc,
  seq, origem da baixa) — nao e grao de NF nem de item, ver stg_comissao.

  Carrega tres papeis de comissao na mesma linha (vendedor, gerente e
  "PF"), cada um com seu proprio percentual e valor, porque e assim que
  o legado libera o pagamento — nao ha uma linha por papel.
*/

with base as (

    select
        *,
        {{ dbt_utils.generate_surrogate_key([
            'filial', 'cod_natureza', 'titulo', 'parcela',
            'cod_cliente', 'loja_cliente', 'tipo_doc', 'seq', 'origem_baixa'
        ]) }} as sk_comissao
    from {{ ref('stg_comissao') }}

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
    coalesce(dv.sk_vendedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_vendedor,
    f.perc_comiss_vendedor,
    f.vr_comissao_vendedor,
    coalesce(dg.sk_vendedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_gerente,
    f.perc_comiss_gerente,
    f.vr_comissao_gerente,
    coalesce(dp.sk_vendedor, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_pf,
    f.perc_comiss_pf,
    f.vr_comissao_pf,
    f.historico
from base f
left join {{ ref('dim_cliente') }} dc on dc.chave_cliente = f.chave_cliente
left join {{ ref('dim_vendedor') }} dv on dv.cod_vendedor = f.cod_vendedor
left join {{ ref('dim_vendedor') }} dg on dg.cod_vendedor = f.cod_gerente
left join {{ ref('dim_vendedor') }} dp on dp.cod_vendedor = f.cod_pf
