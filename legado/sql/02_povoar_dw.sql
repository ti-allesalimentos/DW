/* =====================================================================
   ALLES — Povoamento da camada dw (gold) a partir do raw (bronze)
   ---------------------------------------------------------------------
   Traducao das tratativas de Power Query (M) para SQL:
     - TRIM em todos os textos (campos CHAR do Protheus vem com padding)
     - renome dos aliases (_CODPRODUTO -> cod_produto, etc.)
     - chave_cliente = TRIM(A1_COD) || TRIM(A1_LOJA)
     - join estado -> regiao via raw.regiao (aba dRegiao do fManual)
     - conversao caixa->quilo (-CX) no fato, via dw.map_produto_cx
   Idempotente: TRUNCATE + INSERT. Rode depois do raw carregado.
   Ordem: dimensoes primeiro, fato por ultimo (respeita as FKs).
   ===================================================================== */

TRUNCATE dw.fato_faturamento;
TRUNCATE dw.dim_produto, dw.dim_familia, dw.dim_cliente,
         dw.dim_vendedor, dw.dim_calendario CASCADE;


/* ---------- dim_produto (raw.produtos <- SB1010) ---------- */
INSERT INTO dw.dim_produto
    (cod_produto, descricao, tipo, um, grupo_estoque,
     conta_contabil, agrupamento, ult_preco_compra, dt_ult_compra)
SELECT DISTINCT ON (TRIM("_CODPRODUTO"))
    TRIM("_CODPRODUTO"),
    TRIM("_DESCPRODUTO"),
    TRIM("_TIPOPRDUTO"),
    TRIM("_UNIDADEMEDIDAPRODUTO"),
    TRIM("_GRUPOESTOQUE"),
    TRIM("_CONTA"),
    TRIM("B1_X_AGRUP"),
    "Ult. Preco Comp.",
    CASE WHEN TRIM("_DTAULTCOMPRA") ~ '^\d{8}$'
         THEN NULLIF(to_date(TRIM("_DTAULTCOMPRA"), 'YYYYMMDD'), DATE '1900-01-01')
         ELSE NULL END
FROM raw.produtos
WHERE TRIM("_CODPRODUTO") <> ''
ORDER BY TRIM("_CODPRODUTO");


/* ---------- dim_familia (raw.familia <- fManual/dFamilia) ---------- */
INSERT INTO dw.dim_familia
    (cod, descricao, familia, descricao_comercial, marca, sub_recorte)
SELECT DISTINCT ON (TRIM(cod))
    TRIM(cod), TRIM(descricao), TRIM(familia),
    TRIM(descricao_comercial), TRIM(marca), TRIM(sub_recorte)
FROM raw.familia
WHERE TRIM(cod) <> ''
ORDER BY TRIM(cod);


/* ---------- dim_cliente (raw.clientes <- SA1010 + raw.regiao) ----------
   chave_cliente = TRIM(_COD) || TRIM(_LJ); estado -> regiao pelo de-para;
   datas '1900-01-01' (sentinela vazia do Protheus) viram NULL. */
INSERT INTO dw.dim_cliente
    (chave_cliente, cod_cliente, loja_cliente, pfj, nome, nome_reduzido,
     cgc, endereco, bairro, municipio, estado, estado_desc, regiao,
     cond_pgto, conta_contabil, gerente, cod_vendedor,
     pct_comissao, pct_desconto, situacao, cep, dt_cadastro, dt_ult_compra)
SELECT DISTINCT ON (TRIM(c."_COD") || TRIM(c."_LJ"))
    TRIM(c."_COD") || TRIM(c."_LJ"),
    TRIM(c."_COD"),
    TRIM(c."_LJ"),
    TRIM(c."_PFJ"),
    TRIM(c."_NOMECLIENTE"),
    TRIM(c."_NREDUZCLIENTE"),
    TRIM(c."_CGCCLIENTE"),
    TRIM(c."_ENDCLIENTE"),
    TRIM(c."_BAIRROCLIENTE"),
    TRIM(c."_MUNCLIENTE"),
    TRIM(c."_ESTCLIENTE"),
    UPPER(r.estado_desc),
    UPPER(r.regiao),
    TRIM(c."_CONDPGTO"),
    TRIM(c."_CONTACONTABIL"),
    TRIM(c."_GERENTE"),
    NULLIF(TRIM(c."_CODVEND"), ''),
    c."_COMISCLIENTE",
    c."_DESCCLIENTE",
    TRIM(c."_SITUACAO"),
    TRIM(c."CEP"),
    NULLIF(c."DTCADASTRO", DATE '1900-01-01'),
    NULLIF(c."_DTAULTCOMPRA", DATE '1900-01-01')
FROM raw.clientes c
LEFT JOIN raw.regiao r
       ON UPPER(TRIM(r.sigla)) = UPPER(TRIM(c."_ESTCLIENTE"))
WHERE TRIM(c."_COD") <> ''
ORDER BY TRIM(c."_COD") || TRIM(c."_LJ");


/* ---------- dim_vendedor (raw.vendedores <- SA3010 self-join) ---------- */
INSERT INTO dw.dim_vendedor
    (cod_vendedor, nome, cod_gerente, pct_comissao,
     nome_gerente, pct_comissao_gerente, alias)
SELECT DISTINCT ON (TRIM("_CODVEND"))
    TRIM("_CODVEND"),
    TRIM("_NOMEVEND"),
    NULLIF(TRIM("_GERENVEND"), ''),
    "_COMISVEND",
    TRIM("_NOMEGERENTE"),
    "_COMISGERENTE",
    TRIM("_ALIAS")
FROM raw.vendedores
WHERE TRIM("_CODVEND") <> ''
ORDER BY TRIM("_CODVEND");


/* ---------- dim_calendario (raw.calendario <- dCalendario) ---------- */
INSERT INTO dw.dim_calendario
    (data, ano, mes, mes_nome, trimestre, dia, dia_semana_nome,
     dia_util, feriado, ano_fiscal, mes_fiscal)
SELECT DISTINCT ON (data::date)
    data::date, ano, mes, mes_nome, trimestre, dia, dia_semana_nome,
    dia_util, feriado, ano_fiscal, mes_fiscal
FROM raw.calendario
ORDER BY data::date;


/* ---------- fato_faturamento (raw.faturamento) ----------
   A conversao -CX ocorre UMA vez, pelo join com dw.map_produto_cx.
   As FKs usam LEFT JOIN nas dimensoes: se a chave nao existe na dim
   (ex.: cliente '02020202'), grava NULL em vez de quebrar a FK — assim
   a linha (e a receita) e preservada. */
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
    b.filial,
    b.nfe,
    b.serie,
    b.item_nf,
    p.cod_produto,                                   -- NULL se produto ausente
    cli.chave_cliente,                               -- NULL se cliente ausente
    v.cod_vendedor,                                  -- NULL se vendedor ausente
    cal.data,                                        -- NULL se data fora do calendario
    b.quant * b.fator                                            AS qtd,
    CASE WHEN b.convertido THEN 'KG' ELSE b.um END              AS um,
    (b.total + COALESCE(b.desc_zfr, 0)) / NULLIF(b.quant * b.fator, 0) AS preco_unit,
    b.total,
    b.aliq_icms, b.aliq_pis, b.aliq_cofins, b.aliq_icmsst,
    b.cfop, b.cond_pgto, b.tab_preco, b.tipo, b.tipo_entrega
FROM base b
LEFT JOIN dw.dim_produto    p   ON p.cod_produto   = b.cod_produto_base
LEFT JOIN dw.dim_cliente    cli ON cli.chave_cliente = TRIM(b.cod_cliente) || TRIM(b.loja_cliente)
LEFT JOIN dw.dim_vendedor   v   ON v.cod_vendedor  = NULLIF(TRIM(b.cod_vendedor), '')
LEFT JOIN dw.dim_calendario cal ON cal.data        = b.dt_emissao;


/* ---------- conferencia rapida ---------- */
SELECT 'dim_produto'   t, count(*) FROM dw.dim_produto
UNION ALL SELECT 'dim_familia',    count(*) FROM dw.dim_familia
UNION ALL SELECT 'dim_cliente',    count(*) FROM dw.dim_cliente
UNION ALL SELECT 'dim_vendedor',   count(*) FROM dw.dim_vendedor
UNION ALL SELECT 'dim_calendario', count(*) FROM dw.dim_calendario
UNION ALL SELECT 'fato_faturamento', count(*) FROM dw.fato_faturamento
ORDER BY 1;
