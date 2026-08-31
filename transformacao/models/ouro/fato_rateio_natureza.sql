/*
  Fato rateio de titulo por multiplas naturezas — Protheus (SEV010).
  Grao: recno_origem. cod_clifor nao e resolvido contra dim_cliente/
  dim_fornecedor porque o EV_TIPO do titulo decide qual das duas
  cadastros o codigo referencia, e o legado nao faz essa distincao.
*/

select
    f.recno_origem,
    coalesce(dn.sk_natureza, {{ dbt_utils.generate_surrogate_key(["'NAO_IDENTIFICADO'"]) }}) as sk_natureza,
    f.filial,
    f.prefixo,
    f.titulo,
    f.parcela,
    f.cod_clifor,
    f.loja,
    f.tipo,
    f.valor,
    f.perc_rateio,
    f.valor * f.perc_rateio / 100 as valor_rateado,
    f._carregado_em
from {{ ref('stg_rateio_natureza') }} f
left join {{ ref('dim_natureza_financeira') }} dn on dn.cod_natureza = f.cod_natureza
