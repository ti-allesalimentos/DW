/*
  Tributo por item de NF de saida, formato normalizado — espelha
  stg_impostos_entrada, trocando SD1010 por SD2010. Replica
  sqlImpostosSaidas (fFiscal.m).
*/

select
    {{ trim_protheus('sd2.d2_filial') }}   as filial,
    {{ trim_protheus('sd2.d2_tipo') }}     as tipo_mov,
    {{ data_protheus('sd2.d2_emissao') }}  as dt_emissao,
    {{ trim_protheus('sd2.d2_doc') }}      as nfe,
    {{ trim_protheus('sd2.d2_serie') }}    as serie,
    {{ trim_protheus('sd2.d2_cliente') }}  as cod_cliente,
    {{ trim_protheus('sd2.d2_loja') }}     as loja_cliente,
    {{ trim_protheus('sd2.d2_cliente') }} || {{ trim_protheus('sd2.d2_loja') }} as chave_cliente,
    {{ trim_protheus('sd2.d2_cf') }}       as cfop,
    {{ trim_protheus('sd2.d2_cod') }}      as cod_produto,
    {{ trim_protheus('sd2.d2_idtrib') }}   as id_trib,
    {{ trim_protheus('f2b.f2b_trib') }}    as tributo,
    {{ trim_protheus('f2d.f2d_trib') }}    as cod_tributo,
    {{ trim_protheus('f2b.f2b_desc') }}    as descricao_tributo,
    f2d.f2d_base                           as base_tributo,
    f2d.f2d_aliq                           as aliq_tributo,
    f2d.f2d_valor                          as valor_tributo,
    sd2.r_e_c_n_o_                         as recno_sd2,
    f2d.r_e_c_n_o_                         as recno_f2d,
    {{ dbt_utils.generate_surrogate_key(['sd2.r_e_c_n_o_', 'f2d.r_e_c_n_o_']) }} as sk_linha,
    sd2._carregado_em
from {{ source('bronze', 'sd2010') }} sd2
left join {{ source('bronze', 'f2d010') }} f2d
    on f2d.d_e_l_e_t_ <> '*'
   and {{ trim_protheus('sd2.d2_idtrib') }} = {{ trim_protheus('f2d.f2d_idrel') }}
left join {{ source('bronze', 'f2b010') }} f2b
    on f2b.d_e_l_e_t_ <> '*'
   and {{ trim_protheus('f2b.f2b_id') }} = {{ trim_protheus('f2d.f2d_idcad') }}
where sd2.d_e_l_e_t_ <> '*'
