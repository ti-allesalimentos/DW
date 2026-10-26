/*
  Titulos a receber (SE1010), conformados. Grao: recno_origem — SE1010
  ja e titulo/parcela, sem necessidade de dedup ou agregacao.

  Sem filtro de negocio no legado (sqlContasAReceber) alem do D_E_L_E_T_:
  e o universo inteiro de titulos, aberto ou baixado. Regra de negocio
  fica pra quem consome (ex.: "so em aberto" filtra saldo <> 0 depois).

  "Vl Dsc/Abto" do legado (base_receber) e um valor derivado real
  (percentual de desconto financeiro * valor do titulo), nao formatacao
  de exibicao — mantido aqui como valor_desconto_financeiro. A mascara
  de CNPJ do legado (STUFF de pontos/traco) e so formatacao de tela;
  quem precisar do CNPJ usa dim_cliente.cnpj.
*/

select
    {{ trim_protheus('e1_filial') }}   as filial,
    {{ trim_protheus('e1_prefixo') }}  as prefixo,
    {{ trim_protheus('e1_num') }}      as titulo,
    {{ trim_protheus('e1_parcela') }}  as parcela,
    {{ trim_protheus('e1_tipo') }}     as tipo,
    {{ trim_protheus('e1_naturez') }}  as cod_natureza,
    {{ trim_protheus('e1_situaca') }}  as cod_carteira,
    {{ trim_protheus('e1_cliente') }}  as cod_cliente,
    {{ trim_protheus('e1_loja') }}     as loja_cliente,
    {{ trim_protheus('e1_cliente') }} || {{ trim_protheus('e1_loja') }} as chave_cliente,
    {{ trim_protheus('e1_vend1') }}    as cod_vendedor,
    {{ data_protheus('e1_emissao') }}  as dt_emissao,
    {{ data_protheus('e1_vencto') }}   as dt_vencimento,
    {{ data_protheus('e1_vencrea') }}  as dt_vencimento_real,
    e1_valor                           as valor,
    {{ data_protheus('e1_baixa') }}    as dt_baixa,
    {{ trim_protheus('e1_numbor') }}   as bordero,
    {{ data_protheus('e1_databor') }}  as dt_bordero,
    e1_saldo                           as saldo,
    e1_vlcruz                          as valor_moeda,
    e1_descfin                         as perc_desconto_financeiro,
    e1_valor * e1_descfin / 100        as valor_desconto_financeiro,
    {{ trim_protheus('e1_hist') }}     as historico,
    {{ trim_protheus('e1_fluxo') }}    as fluxo_caixa,
    {{ trim_protheus('e1_formrec') }}  as forma_recebimento,
    {{ trim_protheus('e1_x_frec') }}   as forma_recebimento_x,
    r_e_c_n_o_                         as recno_origem,
    _carregado_em
from {{ source('bronze', 'se1010') }}
where d_e_l_e_t_ <> '*'
