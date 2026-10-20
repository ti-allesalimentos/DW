/*
  Tabela de preco de referencia (DA0010 cabecalho + DA1010 item por
  produto x UF), replicando sqlTabelaPreco de docs/legado_m/dClientes.m.

  Achado que muda o desenho original: nao existe uma unica "tabela base"
  universal -- ha 40+ tabelas nomeadas (uma por rede/cliente negociado:
  SAVEGNAGO, ZAFFARI, ATACADAO...), e o mesmo DA0_CODTAB significa coisas
  diferentes em filiais diferentes (ex.: codigo '001' e "TABELA DE CUSTOS"
  numa filial e "TABELA DE PRECO BASE" noutra). A chave real e
  filial + codigo da tabela, nao so o codigo. Por isso este modelo mantem
  todas as tabelas, sem filtrar por descricao -- quem consome decide qual
  tabela usar (ex.: a mesma atribuida ao pedido via SC5010.C5_TABELA).
*/

with da0 as (

    select
        {{ trim_protheus('da0_filial') }}  as filial,
        {{ trim_protheus('da0_codtab') }}  as cod_tabela,
        {{ trim_protheus('da0_descri') }}  as descricao_tabela,
        _carregado_em
    from {{ source('bronze', 'da0010') }}
    where d_e_l_e_t_ <> '*'

),

da0_dedup as (

    select distinct on (filial, cod_tabela)
        filial, cod_tabela, descricao_tabela
    from da0
    order by filial, cod_tabela, _carregado_em desc

),

da1 as (

    select
        {{ trim_protheus('da1_filial') }}  as filial,
        {{ trim_protheus('da1_codtab') }}  as cod_tabela,
        {{ trim_protheus('da1_codpro') }}  as cod_produto,
        {{ trim_protheus('da1_estado') }}  as uf,
        da1_prcven                          as preco_unit,
        _carregado_em
    from {{ source('bronze', 'da1010') }}
    where d_e_l_e_t_ <> '*'

),

da1_dedup as (

    select distinct on (filial, cod_tabela, cod_produto, uf)
        filial, cod_tabela, cod_produto, uf, preco_unit
    from da1
    order by filial, cod_tabela, cod_produto, uf, _carregado_em desc

)

select
    d1.filial,
    d1.cod_tabela,
    d0.descricao_tabela,
    d1.cod_produto,
    d1.uf,
    d1.preco_unit
from da1_dedup d1
join da0_dedup d0
    on d0.filial = d1.filial
   and d0.cod_tabela = d1.cod_tabela
