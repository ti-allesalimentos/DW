/* =====================================================================
   ALLES — Fatos comerciais adicionais (gold) a partir do raw
   ---------------------------------------------------------------------
   Espelho das abas extras da fFaturamento.xlsx, uma dw.fato_* por tipo.
   A conversao -CX ja veio EMBUTIDA em cada query de origem (cada uma tem
   sua propria lista), entao aqui so aplicamos TRIM / cast de data / chave.
   Datas-texto vem como 'DD-MM-YYYY' (CONVERT 105 do SQL Server).
   Idempotente: DROP + CREATE AS SELECT. Rode depois do raw carregado.
   ===================================================================== */

/* ---------- dimensoes manuais de devolucao ---------- */
DROP TABLE IF EXISTS dw.dim_destino;
CREATE TABLE dw.dim_destino AS
SELECT DISTINCT ON (TRIM(sigla))
    TRIM(sigla) AS sigla, TRIM(descricao) AS descricao
FROM raw.destino WHERE TRIM(sigla) <> '' ORDER BY TRIM(sigla);

DROP TABLE IF EXISTS dw.dim_motivo_dev;
CREATE TABLE dw.dim_motivo_dev AS
SELECT DISTINCT ON (TRIM(sigla))
    TRIM(sigla) AS sigla, TRIM(motivo) AS motivo, TRIM(categoria) AS categoria
FROM raw.motivo_dev WHERE TRIM(sigla) <> '' ORDER BY TRIM(sigla);


/* ---------- fato_devolucoes (SD1010, entradas) ---------- */
DROP TABLE IF EXISTS dw.fato_devolucoes;
CREATE TABLE dw.fato_devolucoes AS
SELECT
    TRIM("FILIAL")                              AS filial,
    TRIM("NF")                                  AS nf,
    TRIM("ITEM")                                AS item_nf,
    TRIM("CODPROD")                             AS cod_produto,
    NULLIF(TRIM("CLIENTE"), '') || TRIM("LJCLI") AS chave_cliente,
    "QTD"::numeric(18,3)                        AS qtd,
    TRIM("UM")                                  AS um,
    "VRUNIT"::numeric(18,6)                     AS vr_unit,
    "VRTOTAL"::numeric(18,2)                    AS total,
    to_date(NULLIF(TRIM("EMISSAO"), ''), 'DD-MM-YYYY')       AS dt_emissao,
    to_date(NULLIF(TRIM("LANCAMENTO"), ''), 'DD-MM-YYYY')    AS dt_lancamento,
    to_date(NULLIF(TRIM("DTAEMISSNFORI"), ''), 'DD-MM-YYYY') AS dt_emiss_nf_ori,
    TRIM("NFORIGEM")                            AS nf_origem,
    TRIM("SERIE")                               AS serie,
    TRIM("MOTIVODEV")                           AS motivo_dev,
    TRIM("DESTINO")                             AS destino,
    TRIM("F1_FORMUL")                           AS formul
FROM raw.devolucoes;


/* ---------- fato_bonificacao (SD2010, CFOP 591x/691x) ---------- */
DROP TABLE IF EXISTS dw.fato_bonificacao;
CREATE TABLE dw.fato_bonificacao AS
SELECT
    TRIM("FILIAL")                              AS filial,
    TRIM("NFE")                                 AS nfe,
    TRIM("_SERIE")                              AS serie,
    TRIM("ITEM")                                AS item_nf,
    TRIM("CODPROD")                             AS cod_produto,
    TRIM("CODCLI") || TRIM("LJCLI")             AS chave_cliente,
    NULLIF(TRIM("_CODVEND"), '')                AS cod_vendedor,
    "_DTEMISSAO"                                AS dt_emissao,
    "QTD"::numeric(18,3)                        AS qtd,
    TRIM("UM")                                  AS um,
    "PRCUNIT"::numeric(18,6)                    AS preco_unit,
    "TOTAL"::numeric(18,2)                      AS total,
    TRIM("CFOP")                                AS cfop,
    TRIM("_ESTADO")                             AS estado,
    TRIM("TIPO")                                AS tipo
FROM raw.bonificacao;


/* ---------- fato_refaturamento (SD2010, C5_X_REFAT preenchido) ---------- */
DROP TABLE IF EXISTS dw.fato_refaturamento;
CREATE TABLE dw.fato_refaturamento AS
SELECT
    TRIM("FILIAL")                              AS filial,
    TRIM("NFE")                                 AS nfe,
    TRIM("_SERIE")                              AS serie,
    TRIM("CODPROD")                             AS cod_produto,
    to_date(NULLIF(TRIM("_DTEMISSAO"), ''), 'DD-MM-YYYY') AS dt_emissao,
    "QTD"::numeric(18,3)                        AS qtd,
    TRIM("UM")                                  AS um,
    "PRCUNIT"::numeric(18,6)                    AS preco_unit,
    "TOTAL"::numeric(18,2)                      AS total,
    TRIM("CFOP")                                AS cfop,
    TRIM("NFORIREFATURA")                       AS nf_ori_refatura
FROM raw.refaturamento;


/* ---------- fato_remessa (SD2010, CFOP 590x/690x) ----------
   Tabela unica com discriminador tipo_remessa. Hoje so populamos
   INDUSTRIALIZACAO; quando a query triangular receber os CFOPs corretos,
   inserir aqui aquelas linhas com tipo_remessa = 'TRIANGULAR'. */
DROP TABLE IF EXISTS dw.fato_remessa;
CREATE TABLE dw.fato_remessa AS
SELECT
    'INDUSTRIALIZACAO'::text                    AS tipo_remessa,
    TRIM("FILIAL")                              AS filial,
    TRIM("NFE")                                 AS nfe,
    TRIM("_SERIE")                              AS serie,
    TRIM("ITEM")                                AS item_nf,
    TRIM("CODPROD")                             AS cod_produto,
    TRIM("CODCLI") || TRIM("LJCLI")             AS chave_cliente,
    NULLIF(TRIM("_CODVEND"), '')                AS cod_vendedor,
    to_date(NULLIF(TRIM("_DTEMISSAO"), ''), 'DD-MM-YYYY') AS dt_emissao,
    "QTD"::numeric(18,3)                        AS qtd,
    TRIM("UM")                                  AS um,
    "PRCUNIT"::numeric(18,6)                    AS preco_unit,
    "TOTAL"::numeric(18,2)                      AS total,
    TRIM("CFOP")                                AS cfop,
    TRIM("_ESTADO")                             AS estado,
    TRIM("TIPO")                                AS tipo
FROM raw.rem_industrializacao;


/* ---------- fato_acordo_comercial (SD1010, TES 050/052) ---------- */
DROP TABLE IF EXISTS dw.fato_acordo_comercial;
CREATE TABLE dw.fato_acordo_comercial AS
SELECT
    TRIM("FILIAL")                              AS filial,
    TRIM("ITEM")                                AS item_nf,
    TRIM("CODPROD")                             AS cod_produto,
    NULLIF(TRIM("CLIENTE"), '') || TRIM("LJCLI") AS chave_cliente,
    "QTD"::numeric(18,3)                        AS qtd,
    TRIM("UM")                                  AS um,
    "VRUNIT"::numeric(18,6)                     AS vr_unit,
    "PRCUNIT"::numeric(18,6)                    AS preco_unit,
    "VRTOTAL"::numeric(18,2)                    AS total,
    TRIM("NFORIGEM")                            AS nf_origem,
    TRIM("TIPO")                                AS tipo,
    to_date(NULLIF(TRIM("EMISSAO"), ''), 'DD-MM-YYYY') AS dt_emissao,
    TRIM("ITEMORI")                             AS item_ori
FROM raw.acordo_comercial;


/* ---------- fato_coopeval_remessa (SD2010, cliente 07390806) ---------- */
DROP TABLE IF EXISTS dw.fato_coopeval_remessa;
CREATE TABLE dw.fato_coopeval_remessa AS
SELECT
    TRIM("FILIAL")                              AS filial,
    TRIM("NFE")                                 AS nfe,
    TRIM("_SERIE")                              AS serie,
    TRIM("ITEM")                                AS item_nf,
    TRIM("CODPROD")                             AS cod_produto,
    TRIM("PRODUTO")                             AS produto_desc,
    TRIM("CODCLI") || TRIM("LJCLI")             AS chave_cliente,
    NULLIF(TRIM("_CODVEND"), '')                AS cod_vendedor,
    to_date(NULLIF(TRIM("_DTEMISSAO"), ''), 'DD-MM-YYYY') AS dt_emissao,
    "QTD"::numeric(18,3)                        AS qtd,
    TRIM("UM")                                  AS um,
    "PRCUNIT"::numeric(18,6)                    AS preco_unit,
    "TOTAL"::numeric(18,2)                      AS total,
    TRIM("CFOP")                                AS cfop,
    TRIM("_ESTADO")                             AS estado
FROM raw.coopeval_remessa;


/* ---------- conferencia ---------- */
SELECT 'dim_destino'          t, count(*) FROM dw.dim_destino
UNION ALL SELECT 'dim_motivo_dev',        count(*) FROM dw.dim_motivo_dev
UNION ALL SELECT 'fato_devolucoes',       count(*) FROM dw.fato_devolucoes
UNION ALL SELECT 'fato_bonificacao',      count(*) FROM dw.fato_bonificacao
UNION ALL SELECT 'fato_refaturamento',    count(*) FROM dw.fato_refaturamento
UNION ALL SELECT 'fato_remessa',          count(*) FROM dw.fato_remessa
UNION ALL SELECT 'fato_acordo_comercial', count(*) FROM dw.fato_acordo_comercial
UNION ALL SELECT 'fato_coopeval_remessa', count(*) FROM dw.fato_coopeval_remessa
ORDER BY 1;
