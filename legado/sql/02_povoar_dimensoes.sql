/* =====================================================================
   ALLES — Data Warehouse  |  Piloto: FATURAMENTO
   Povoamento das dimensoes (raw -> dw) e do fato.
   ---------------------------------------------------------------------
   Rode DEPOIS de:
     1) sql/01_modelo_faturamento.sql   (cria schemas/tabelas + map_produto_cx)
     2) ingestion/extract_protheus.py    (popula raw.faturamento)
     3) ingestion/extract_dimensoes_excel.py (popula raw.produtos/familia/
        clientes/vendedores/calendario)
   Idempotente: pode ser rodado de novo (limpa o dw antes de repovoar).
   ===================================================================== */

-- Limpa fato e dimensoes numa unica instrucao: o fato tem FK para as
-- dimensoes, entao o TRUNCATE precisa citar todas as tabelas juntas.
TRUNCATE dw.fato_faturamento,
         dw.dim_produto, dw.dim_familia, dw.dim_cliente,
         dw.dim_vendedor, dw.dim_calendario;


/* ---------------------------------------------------------------------
   DIMENSOES
   Os campos ja chegam tratados das planilhas; so alinhamos os nomes.
   --------------------------------------------------------------------- */
INSERT INTO dw.dim_produto (cod_produto, descricao, tipo, um, grupo_estoque,
                            conta_contabil, agrupamento, ult_preco_compra, dt_ult_compra)
SELECT cod_produto, descricao, tipo, um, grupo_estoque,
       conta_contabil, agrupamento, ult_preco_compra, dt_ult_compra::date
FROM raw.produtos;

INSERT INTO dw.dim_familia (cod, descricao, familia, descricao_comercial, marca, sub_recorte)
SELECT cod, descricao, familia, descricao_comercial, marca, sub_recorte
FROM raw.familia;

-- raw.clientes pode trazer a mesma chave_cliente repetida (ex.: cliente
-- 97316293, que inclusive e excluido do faturamento). DISTINCT ON mantem
-- so a linha mais recente por chave, evitando violar a PK de dim_cliente.
INSERT INTO dw.dim_cliente (chave_cliente, pfj, nome, nome_reduzido, cgc,
                            endereco, bairro, municipio, estado, estado_desc, regiao,
                            cond_pgto, conta_contabil, gerente, cod_vendedor,
                            pct_comissao, pct_desconto, situacao, cep,
                            dt_cadastro, dt_ult_compra)
SELECT DISTINCT ON (chave_cliente)
       chave_cliente, pfj, nome, nome_reduzido, cgc,
       endereco, bairro, municipio, estado, estado_desc, regiao,
       cond_pgto, conta_contabil, gerente, cod_vendedor,
       pct_comissao, pct_desconto, situacao::text, cep,
       dt_cadastro::date, dt_ult_compra::date
FROM raw.clientes
ORDER BY chave_cliente, dt_ult_compra DESC NULLS LAST;

INSERT INTO dw.dim_vendedor (cod_vendedor, nome, cod_gerente, nome_gerente,
                             pct_comissao, pct_comissao_gerente, alias)
SELECT cod_vendedor, nome, cod_gerente, nome_gerente,
       pct_comissao, pct_comissao_gerente, alias
FROM raw.vendedores;

INSERT INTO dw.dim_calendario (data, ano, mes, mes_nome, trimestre, dia,
                               dia_semana_nome, dia_util, feriado, ano_fiscal, mes_fiscal)
SELECT data::date, ano, mes, mes_nome, trimestre, dia,
       dia_semana_nome, dia_util, feriado, ano_fiscal, mes_fiscal
FROM raw.calendario;


/* ---------------------------------------------------------------------
   BACKFILL DE ORFAOS
   Clientes citados no faturamento mas ausentes do cadastro (dClientes.xlsx).
   Sem isto, a FK do fato barra a linha e perdemos faturamento na
   reconciliacao. Criamos um registro-esqueleto marcado para revisao.
   (Produtos: 0 orfaos apos TRIM. Vendedores: codigos vazios viram NULL.)
   --------------------------------------------------------------------- */
INSERT INTO dw.dim_cliente (chave_cliente, nome, situacao)
SELECT DISTINCT TRIM(r.cod_cliente) || TRIM(r.loja_cliente), '(cliente nao cadastrado)', 'REVISAR'
FROM raw.faturamento r
LEFT JOIN dw.dim_cliente c
       ON c.chave_cliente = TRIM(r.cod_cliente) || TRIM(r.loja_cliente)
WHERE c.chave_cliente IS NULL;


/* =====================================================================
   POVOAMENTO DO FATO
   Aqui mora a regra: a conversao caixa->quilo acontece UMA vez,
   pelo LEFT JOIN com dw.map_produto_cx. Se o produto nao esta no
   de-para, fator = 1 e o codigo/UM ficam como vieram.

   Nota: os campos de texto vindos do SQL Server (Protheus) sao CHAR de
   largura fixa e chegam com espacos de preenchimento; por isso o TRIM
   no cod_protheus e no cod_vendedor. Sem isso a conversao -CX nunca
   dispara e o join com as dimensoes falha.
   ===================================================================== */
INSERT INTO dw.fato_faturamento (
    filial, nfe, serie, item_nf,
    cod_produto, chave_cliente, cod_vendedor, dt_emissao,
    qtd, um, preco_unit, total,
    aliq_icms, aliq_pis, aliq_cofins, aliq_icmsst,
    cfop, cond_pgto, tab_preco, tipo, tipo_entrega
)
WITH base AS (
    SELECT
        r.*,
        COALESCE(m.produto_base, TRIM(r.cod_protheus)) AS cod_produto_base,
        COALESCE(m.fator, 1)                     AS fator,
        (m.produto_base IS NOT NULL)             AS convertido
    FROM raw.faturamento r
    LEFT JOIN dw.map_produto_cx m
           ON m.produto_cx = TRIM(r.cod_protheus)
)
SELECT
    TRIM(filial),
    TRIM(nfe),
    TRIM(serie),
    TRIM(item_nf),
    cod_produto_base,
    (TRIM(cod_cliente) || TRIM(loja_cliente))            AS chave_cliente,
    NULLIF(TRIM(cod_vendedor), '')                       AS cod_vendedor,
    dt_emissao,
    quant * fator                                        AS qtd,
    CASE WHEN convertido THEN 'KG' ELSE TRIM(um) END     AS um,
    (total + COALESCE(desc_zfr,0)) / NULLIF(quant * fator, 0) AS preco_unit,
    total,
    aliq_icms, aliq_pis, aliq_cofins, aliq_icmsst,
    TRIM(cfop), cond_pgto, tab_preco, TRIM(tipo), tipo_entrega
FROM base;


/* ---------------------------------------------------------------------
   CONFERENCIA RAPIDA (reconciliacao com a planilha atual)
   --------------------------------------------------------------------- */
SELECT count(*) AS linhas, sum(total) AS faturamento_total
FROM dw.fato_faturamento;
