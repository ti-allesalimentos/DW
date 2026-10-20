/*
  Estoque de produto acabado por local (SB2010, codigo contendo 'PA'),
  excluindo locais de transito/reserva (DV, BO, AR, DP, CO — siglas nao
  documentadas no legado, replicadas fielmente). Grao: recno_origem.
  Replica sqlSB2 (fLogistica.m) — a variante canonica; #"sqlSB2 (2)"
  no mesmo arquivo e identica sem o filtro de local, sedimento nao
  reconstruido aqui (ver docs/reconciliacao_logistica.md).
*/

select
    {{ trim_protheus('b2_filial') }}  as filial,
    {{ trim_protheus('b2_cod') }}     as cod_produto,
    {{ trim_protheus('b2_local') }}   as local_estoque,
    b2_qatu                            as qtd_atual,
    b2_qtsegum                          as qtd_segunda_um,
    r_e_c_n_o_ as recno_origem,
    _carregado_em
from {{ source('bronze', 'sb2010') }}
where d_e_l_e_t_ <> '*'
  and {{ trim_protheus('b2_cod') }} like '%PA%'
  -- btrim() puro, nao trim_protheus(): 6 linhas tem b2_local em branco
  -- (nao NULL), e NOT IN com NULL excluiria essas linhas por engano
  -- (mesmo padrao ja visto em D3_ESTORNO/E5_SITUACA).
  and btrim(b2_local) not in ('DV', 'BO', 'AR', 'DP', 'CO')
