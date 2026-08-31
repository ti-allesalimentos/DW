/*
  Tributo por item de NF de entrada, formato normalizado (uma linha por
  item x tipo de tributo), via as tabelas genericas de apuracao
  F2B010/F2D010. Grao: item de SD1010 x tributo de F2D010 — LEFT JOIN,
  entao um item sem apuracao de tributo aparece uma vez com os campos
  de tributo nulos. Replica sqlImpostosEntradas (fFiscal.m).

  E o complemento normalizado (long) do fato_tributo_nf (SFT010, wide):
  serve pra analise por tipo de tributo sem pivotar colunas.
*/

select
    {{ trim_protheus('sd1.d1_filial') }}   as filial,
    {{ trim_protheus('sd1.d1_tipo') }}     as tipo_mov,
    {{ data_protheus('sd1.d1_dtdigit') }}  as dt_entrada,
    {{ data_protheus('sd1.d1_emissao') }}  as dt_emissao,
    {{ trim_protheus('sd1.d1_doc') }}      as nfe,
    {{ trim_protheus('sd1.d1_serie') }}    as serie,
    {{ trim_protheus('sd1.d1_fornece') }}  as cod_fornecedor,
    {{ trim_protheus('sd1.d1_loja') }}     as loja_fornecedor,
    {{ trim_protheus('sd1.d1_fornece') }} || {{ trim_protheus('sd1.d1_loja') }} as chave_fornecedor,
    {{ trim_protheus('sd1.d1_cf') }}       as cfop,
    {{ trim_protheus('sd1.d1_tes') }}      as tes,
    {{ trim_protheus('sd1.d1_pedido') }}   as pedido,
    {{ trim_protheus('sd1.d1_cod') }}      as cod_produto,
    {{ trim_protheus('sd1.d1_idtrib') }}   as id_trib,
    {{ trim_protheus('f2b.f2b_trib') }}    as tributo,
    {{ trim_protheus('f2d.f2d_trib') }}    as cod_tributo,
    {{ trim_protheus('f2b.f2b_desc') }}    as descricao_tributo,
    f2d.f2d_base                           as base_tributo,
    f2d.f2d_aliq                           as aliq_tributo,
    f2d.f2d_valor                          as valor_tributo,
    sd1.r_e_c_n_o_                         as recno_sd1,
    f2d.r_e_c_n_o_                         as recno_f2d,
    {{ dbt_utils.generate_surrogate_key(['sd1.r_e_c_n_o_', 'f2d.r_e_c_n_o_']) }} as sk_linha,
    sd1._carregado_em
from {{ source('bronze', 'sd1010') }} sd1
left join {{ source('bronze', 'f2d010') }} f2d
    on f2d.d_e_l_e_t_ <> '*'
   and {{ trim_protheus('sd1.d1_idtrib') }} = {{ trim_protheus('f2d.f2d_idrel') }}
left join {{ source('bronze', 'f2b010') }} f2b
    on f2b.d_e_l_e_t_ <> '*'
   and {{ trim_protheus('f2b.f2b_id') }} = {{ trim_protheus('f2d.f2d_idcad') }}
where sd1.d_e_l_e_t_ <> '*'
