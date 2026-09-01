/*
  CT-e, lado financeiro — titulo a pagar de frete (SE2010+SA2010,
  naturezas especificas de frete). Grao: recno_origem. Replica
  sqlCteFinanceiro (fFretes.m).
*/

select
    {{ trim_protheus('e2_num') }}      as numero_cte,
    {{ trim_protheus('e2_fornece') }}  as cod_fornecedor,
    {{ trim_protheus('e2_loja') }}     as loja_fornecedor,
    {{ trim_protheus('e2_fornece') }} || {{ trim_protheus('e2_loja') }} as chave_fornecedor,
    e2_valor                            as valor,
    {{ data_protheus('e2_emissao') }}  as dt_emissao,
    {{ data_protheus('e2_baixa') }}    as dt_baixa,
    case when btrim(e2_baixa) <> '' then 'BAIXADO' else 'PENDENTE' end as status_baixa,
    r_e_c_n_o_ as recno_origem,
    _carregado_em
from {{ source('bronze', 'se2010') }}
where d_e_l_e_t_ <> '*'
  -- btrim() puro: a maioria das linhas tem e2_fatura em branco (nao
  -- NULL), e trim_protheus() quebraria esse filtro de desigualdade
  -- (mesmo padrao ja visto varias vezes neste projeto).
  and btrim(e2_fatura) <> 'NOTFAT'
  and {{ trim_protheus('e2_naturez') }} in (
        '0202001', '0202002', '0202003', '0202004', '0202005', '0202006',
        '0202007', '0202008', '0202009', '0202010', '0202011', '0403009', '0202'
      )
