/*
  Tributo por NF, calculado pelo Protheus (SFT010), conformado. Grao:
  recno_origem — SFT010 ja e por item/tributo, cada linha traz o
  detalhamento completo (ICMS/IPI/PIS/COFINS/IRRF/INSS/ISS) de uma vez,
  em vez do formato normalizado longo do F2B/F2D. Replica sqlSFT
  (fFiscal.m).

  FT_CLIEFOR pode ser cliente ou fornecedor dependendo do FT_TIPOMOV —
  o legado resolve nome via COALESCE(SA2,SA1); aqui o mesmo raw code e
  exposto como cod_cliefor e resolvido contra as duas dimensoes no
  fato, cada join caindo em NAO_IDENTIFICADO quando nao se aplica.

  ISS (D1_BASEISS/ALIQISS/VALISS) vem de SD1010, nao do proprio SFT010
  — so populado quando a nota tem item de entrada casado.
*/

with sft as (

select
    {{ trim_protheus('ft_filial') }}    as filial,
    {{ trim_protheus('ft_tipomov') }}   as tipo_mov,
    {{ trim_protheus('ft_tipo') }}      as tipo_lancamento,
    {{ data_protheus('ft_entrada') }}   as dt_entrada,
    {{ data_protheus('ft_emissao') }}   as dt_emissao,
    {{ trim_protheus('ft_especie') }}   as especie,
    {{ trim_protheus('ft_nfiscal') }}   as nfe,
    {{ trim_protheus('ft_serie') }}     as serie,
    {{ trim_protheus('ft_cliefor') }}   as cod_cliefor,
    {{ trim_protheus('ft_loja') }}      as loja,
    {{ trim_protheus('ft_cliefor') }} || {{ trim_protheus('ft_loja') }} as chave_cliefor,
    {{ trim_protheus('ft_cfop') }}      as cfop,
    {{ trim_protheus('ft_codiss') }}    as cod_servico_iss,
    {{ trim_protheus('ft_produto') }}   as cod_produto,
    {{ trim_protheus('ft_posipi') }}    as cod_ncm,
    ft_valcont                          as valor_contabil,
    ft_total                            as valor_total,
    {{ trim_protheus('ft_clasfis') }}   as sit_trib_icms,
    ft_aliqicm                          as aliq_icms,
    ft_baseicm                          as base_icms,
    ft_valicm                           as valor_icms,
    ft_isenicm                          as valor_isento_icms,
    ft_outricm                          as valor_outro_icms,
    {{ trim_protheus('ft_ctipi') }}     as sit_trib_ipi,
    ft_baseipi                          as base_ipi,
    ft_aliqipi                          as aliq_ipi,
    ft_valipi                           as valor_ipi,
    ft_isenipi                          as valor_isento_ipi,
    ft_outripi                          as valor_outro_ipi,
    ft_baseret                          as base_icms_st,
    ft_aliqsol                          as aliq_icms_st,
    ft_icmsret                          as valor_icms_st,
    ft_icmsdif                          as valor_icms_diferido,
    {{ trim_protheus('ft_cstpis') }}    as cst_pis,
    ft_basepis                          as base_pis,
    ft_aliqpis                          as aliq_pis,
    ft_valpis                           as valor_pis,
    {{ trim_protheus('ft_cstcof') }}    as cst_cofins,
    ft_basecof                          as base_cofins,
    ft_aliqcof                          as aliq_cofins,
    ft_valcof                           as valor_cofins,
    ft_baseirr                          as base_irrf,
    ft_aliqirr                          as aliq_irrf,
    ft_valirr                           as valor_irrf,
    ft_baseins                          as base_inss,
    ft_aliqins                          as aliq_inss,
    ft_valins                           as valor_inss,
    ft_bretpis                          as base_pis_retido,
    ft_aretpis                          as aliq_pis_retido,
    ft_vretpis                          as valor_pis_retido,
    ft_bretcof                          as base_cofins_retido,
    ft_aretcof                          as aliq_cofins_retido,
    ft_vretcof                          as valor_cofins_retido,
    ft_bretcsl                          as base_csll_retido,
    ft_aretcsl                          as aliq_csll_retido,
    ft_vretcsl                          as valor_csll_retido,
    r_e_c_n_o_ as recno_origem,
    _carregado_em
from {{ source('bronze', 'sft010') }}
where d_e_l_e_t_ <> '*'

),

-- ISS vem de SD1010 (item de entrada), nao do proprio SFT010 — so
-- populado quando a nota tem item de entrada casado. Dedup por
-- (nf, serie, fornecedor, loja): SD1010 e por item, mas o ISS da nota
-- inteira repete por linha, entao pega so a primeira.
iss as (

    select distinct on (
        {{ trim_protheus('d1_doc') }}, {{ trim_protheus('d1_serie') }},
        {{ trim_protheus('d1_fornece') }}, {{ trim_protheus('d1_loja') }}
    )
        {{ trim_protheus('d1_doc') }}      as nfe,
        {{ trim_protheus('d1_serie') }}    as serie,
        {{ trim_protheus('d1_fornece') }}  as cod_cliefor,
        {{ trim_protheus('d1_loja') }}     as loja,
        d1_baseiss                          as base_iss,
        d1_aliqiss                          as aliq_iss,
        d1_valiss                           as valor_iss,
        _carregado_em
    from {{ source('bronze', 'sd1010') }}
    where d_e_l_e_t_ <> '*'
    order by
        {{ trim_protheus('d1_doc') }}, {{ trim_protheus('d1_serie') }},
        {{ trim_protheus('d1_fornece') }}, {{ trim_protheus('d1_loja') }},
        _carregado_em desc

)

select
    sft.*,
    iss.base_iss,
    iss.aliq_iss,
    iss.valor_iss
from sft
left join iss
    on iss.nfe = sft.nfe
   and iss.serie = sft.serie
   and iss.cod_cliefor = sft.cod_cliefor
   and iss.loja = sft.loja
