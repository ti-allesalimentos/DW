/*
  Historico de faturamento do DATAVALE (ERP anterior ao Protheus),
  conformado. Grao: linha de venda (nao ha serie/item de NF como no
  Protheus — o DATAVALE so guarda um sequencial interno da nota).

  O que este modelo FAZ:
    - TRIM e cast dos campos numericos (formato pt-BR, "-" -> NULL) e da
      data (DD/MM/YYYY)
    - resolve o cliente atual via CNPJ: chave_cliente do DATAVALE e a
      raiz+filial do CNPJ (12 digitos, sem digito verificador); casa
      contra bronze.sa1010.a1_cgc (CNPJ completo, 14 digitos)
    - resolve o vendedor comparando o codigo numericamente, porque o
      SA3010 tem o mesmo codigo gravado com padding inconsistente
      ("000004" e "4" no mesmo cadastro)

  O que este modelo NAO faz:
    - nao junta com o faturamento do Protheus (stg_faturamento). Unificar
      as duas fontes num fato so e decisao de modelagem da Fase 2 que
      ainda depende de definir o grao comum (o DATAVALE nao tem CFOP,
      serie nem os impostos linha a linha que o Protheus tem).

  Taxa de casamento do cliente por CNPJ (medida em 28/08/2026): 99,3% das
  linhas. O restante (~0,7%) sao clientes que saíram de operação antes da
  entrada do Protheus e nunca foram cadastrados no SA1010 — fica como
  "nao identificado", nao e erro de join.
*/

with base as (

    select
        btrim(filial_venda)          as filial,
        btrim(seq_nota_fiscal)       as seq_nota_fiscal,
        btrim(cod_produto_venda)     as cod_produto,
        {{ numero_br('qtd_venda') }}        as qtd,
        btrim(um_venda)               as um,
        {{ numero_br('preco_unit_venda') }} as preco_unit,
        {{ numero_br('total_venda') }}      as total,
        btrim(cod_vendedor)           as cod_vendedor_datavale,
        btrim(estado)                 as uf,
        {{ data_br('dt_emissao') }}          as dt_emissao,
        btrim(nome_cliente)           as nome_cliente,
        btrim(chave_cliente)          as chave_cliente_datavale
    from {{ ref('f_faturamento_datavale') }}

),

sa1010_dedup as (

    -- Uma raiz+filial de CNPJ pode aparecer em mais de uma linha do SA1010
    -- (cadastro duplicado no Protheus). Fica a primeira por cod+loja,
    -- so para o join dar 1:1 -- nao e uma escolha de negocio.
    select distinct on (left(btrim(a1_cgc), 12))
        left(btrim(a1_cgc), 12) as cnpj_raiz_filial,
        a1_cod,
        a1_loja
    from {{ source('bronze', 'sa1010') }}
    where btrim(a1_cgc) <> ''
    order by left(btrim(a1_cgc), 12), a1_cod, a1_loja

),

sa3010_dedup as (

    select distinct on (a3_cod::int)
        a3_cod::int as cod_vendedor_num,
        btrim(a3_cod) as cod_vendedor
    from {{ source('bronze', 'sa3010') }}
    where a3_cod ~ '^\d+$'
    order by a3_cod::int, a3_cod

)

select
    b.filial,
    b.seq_nota_fiscal,
    b.cod_produto,
    b.qtd,
    b.um,
    b.preco_unit,
    b.total,
    coalesce(v.cod_vendedor, b.cod_vendedor_datavale) as cod_vendedor,
    b.uf,
    b.dt_emissao,
    b.nome_cliente,
    b.chave_cliente_datavale,
    c.a1_cod as cod_cliente,
    c.a1_loja as loja_cliente,
    coalesce(c.a1_cod || c.a1_loja, 'NAO_IDENTIFICADO') as chave_cliente
from base b
left join sa1010_dedup c on c.cnpj_raiz_filial = b.chave_cliente_datavale
left join sa3010_dedup v
    on b.cod_vendedor_datavale ~ '^\d+$'
    and v.cod_vendedor_num = b.cod_vendedor_datavale::int
