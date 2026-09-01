/*
  Frete rateado em NF de entrada (GWM010, tipo doc '1'), com o valor
  recebido casado via SD1010. Grao: filial+nf+item+serie+fornecedor.
  Replica sqlFrenteEntradas (fCusto.m, adiado da Fase 7 por precisar
  de tabelas so carregadas aqui na Fase 9).

  Duas omissoes deliberadas em relacao ao legado:
  - O corte `GWM_DTEMIS > 20260416` nao e regra de negocio, e "desde
    quando comecei a olhar isso" — sedimento de quem escreveu a query
    havia pouco tempo. Nao replicado; mirra o historico inteiro.
  - O CTE_VLDF (STRING_AGG concatenando "numero_cte:valor" separados
    por " - ") e formatacao de exibicao pra planilha, nao uma medida.
    Quem precisar do detalhe por CT-e usa fato_cte_logistica.

  O de-para SA2010<->GU3010 (fornecedor x transportador) e por CNPJ
  normalizado (sem pontuacao) porque GU3010 nao tem FK direta pra
  SA2010 — replicado fielmente.
*/

select
    {{ trim_protheus('gwm.gwm_filial') }} as filial,
    {{ trim_protheus('gwm.gwm_nrdc') }}   as nfe,
    {{ trim_protheus('gwm.gwm_seqgw8') }} as item,
    {{ trim_protheus('gwm.gwm_serdc') }}  as serie,
    {{ trim_protheus('sa2.a2_cod') }}     as cod_fornecedor,
    {{ trim_protheus('sa2.a2_loja') }}    as loja_fornecedor,
    {{ trim_protheus('sa2.a2_cod') }} || {{ trim_protheus('sa2.a2_loja') }} as chave_fornecedor,
    max({{ data_protheus('gwm.gwm_dtemdc') }}) as dt_emissao,
    max({{ trim_protheus('gwm.gwm_item') }})   as cod_produto,
    max({{ trim_protheus('sd1.d1_um') }})      as um,
    sum(sd1.d1_quant)                            as qtd,
    max(sd1.d1_vunit)                            as vr_unitario,
    sum(sd1.d1_total)                            as vr_total,
    sum(gwm.gwm_vlfre1)                          as vr_frete,
    max(gwm.gwm_pcrat) / 100                     as percentual
from {{ source('bronze', 'gwm010') }} gwm
left join {{ source('bronze', 'gw1010') }} gw1
    on gw1.d_e_l_e_t_ <> '*'
   and gw1.gw1_cdtpdc = gwm.gwm_cdtpdc
   and gw1.gw1_emisdc = gwm.gwm_emisdc
   and gw1.gw1_serdc = gwm.gwm_serdc
   and gw1.gw1_nrdc = gwm.gwm_nrdc
left join {{ source('bronze', 'gu3010') }} gu3
    on gu3.d_e_l_e_t_ <> '*'
   and gwm.gwm_emisdc = gu3.gu3_cdemit
left join {{ source('bronze', 'sa2010') }} sa2
    on sa2.d_e_l_e_t_ <> '*'
   and regexp_replace(sa2.a2_cgc, '[./-]', '', 'g') = regexp_replace(gu3.gu3_idfed, '[./-]', '', 'g')
left join {{ source('bronze', 'sd1010') }} sd1
    on sd1.d_e_l_e_t_ <> '*'
   and sd1.d1_filial = gwm.gwm_filial
   and sd1.d1_doc = gwm.gwm_nrdc
   and sd1.d1_item = gwm.gwm_seqgw8
   and sd1.d1_serie = gwm.gwm_serdc
   and sd1.d1_fornece = sa2.a2_cod
   and sd1.d1_loja = sa2.a2_loja
where gwm.d_e_l_e_t_ <> '*'
  and {{ trim_protheus('gwm.gwm_tpdoc') }} = '1'
  and {{ trim_protheus('gwm.gwm_item') }} not like 'PA%'
  and {{ trim_protheus('gwm.gwm_item') }} not like 'AM%'
group by
    gwm.gwm_filial, gwm.gwm_nrdc, gwm.gwm_seqgw8, gwm.gwm_serdc,
    sa2.a2_cod, sa2.a2_loja
