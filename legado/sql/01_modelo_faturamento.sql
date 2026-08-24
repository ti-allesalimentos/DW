/* =====================================================================
   ALLES — Data Warehouse  |  Piloto: FATURAMENTO
   Modelo estrela em PostgreSQL
   ---------------------------------------------------------------------
   Camadas:
     raw  (bronze) -> pouso fiel do extrato do Protheus, sem regra
     dw   (gold)   -> dimensoes, fato e tabela de apoio, ja tratados
   Convencao: nomes em minusculo com _ ; datas em DATE ; dinheiro NUMERIC
   ===================================================================== */

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS dw;


/* =====================================================================
   1) CAMADA RAW (BRONZE) — pouso do extrato do Protheus
   Uma linha = um item de nota fiscal, exatamente como sai do SD2.
   Aqui NAO aplicamos a conversao -CX: guardamos o dado cru para auditoria.
   ===================================================================== */
DROP TABLE IF EXISTS raw.faturamento;
CREATE TABLE raw.faturamento (
    filial          text,
    nfe             text,
    serie           text,
    item_nf         text,
    cod_protheus    text,        -- D2_COD (pode terminar em '-CX')
    quant           numeric(18,4),
    um              text,
    total           numeric(18,2),
    desc_zfr        numeric(18,2),
    cfop            text,
    cod_cliente     text,        -- D2_CLIENTE
    loja_cliente    text,        -- D2_LOJA
    dt_emissao      date,
    cond_pgto       text,
    tab_preco       text,
    duplicata       text,
    estado          text,
    tipo_cli        text,
    cod_vendedor    text,
    cond_especial   text,
    tipo            text,
    nfori_refatura  text,
    tipo_entrega    text,
    aliq_icms       numeric(9,4),
    aliq_pis        numeric(9,4),
    aliq_cofins     numeric(9,4),
    aliq_icmsst     numeric(9,4),
    carregado_em    timestamp DEFAULT now()
);


/* =====================================================================
   2) TABELA DE APOIO — de-para de conversao caixa -> quilo
   Substitui o CASE gigante repetido em 8 queries. Produto novo = 1 linha.
   ===================================================================== */
DROP TABLE IF EXISTS dw.map_produto_cx;
CREATE TABLE dw.map_produto_cx (
    produto_cx    text PRIMARY KEY,   -- ex.: 'PA01010001-CX'
    produto_base  text NOT NULL,      -- ex.: 'PA01010001'
    fator         numeric(12,6) NOT NULL
);

INSERT INTO dw.map_produto_cx (produto_cx, produto_base, fator) VALUES
    ('PA01010001-CX', 'PA01010001', 10),
    ('PA01010005-CX', 'PA01010005', 10),
    ('PA01010006-CX', 'PA01010006', 9.6),
    ('PA01010011-CX', 'PA01010011', 10),
    ('PA01020010-CX', 'PA01020010', 2.016),
    ('PA01020012-CX', 'PA01020012', 4),
    ('PA01020021-CX', 'PA01020021', 2.016),
    ('PA01020034-CX', 'PA01020034', 13.44);


/* =====================================================================
   3) DIMENSOES (GOLD)
   ===================================================================== */

DROP TABLE IF EXISTS dw.dim_produto CASCADE;
CREATE TABLE dw.dim_produto (
    cod_produto     text PRIMARY KEY,   -- B1_COD (codigo base, ja sem -CX)
    descricao       text,
    tipo            text,
    um              text,
    grupo_estoque   text,
    conta_contabil  text,
    agrupamento     text,
    ult_preco_compra numeric(18,4),
    dt_ult_compra   date
);

DROP TABLE IF EXISTS dw.dim_familia;
CREATE TABLE dw.dim_familia (
    cod                 text PRIMARY KEY,   -- casa com dim_produto.cod_produto
    descricao           text,
    familia             text,
    descricao_comercial text,
    marca               text,
    sub_recorte         text
);

DROP TABLE IF EXISTS dw.dim_cliente;
CREATE TABLE dw.dim_cliente (
    chave_cliente   text PRIMARY KEY,   -- A1_COD || A1_LOJA
    cod_cliente     text,
    loja_cliente    text,
    pfj             text,               -- Fisica / Juridica
    nome            text,
    nome_reduzido   text,
    cgc             text,
    endereco        text,
    bairro          text,
    municipio       text,
    estado          text,
    estado_desc     text,
    regiao          text,
    cond_pgto       text,
    conta_contabil  text,
    gerente         text,
    cod_vendedor    text,
    pct_comissao    numeric(9,4),
    pct_desconto    numeric(9,4),
    situacao        text,
    cep             text,
    dt_cadastro     date,
    dt_ult_compra   date
);

DROP TABLE IF EXISTS dw.dim_vendedor;
CREATE TABLE dw.dim_vendedor (
    cod_vendedor    text PRIMARY KEY,
    nome            text,
    cod_gerente     text,
    nome_gerente    text,
    pct_comissao    numeric(9,4),
    pct_comissao_gerente numeric(9,4),
    alias           text
);

DROP TABLE IF EXISTS dw.dim_calendario;
CREATE TABLE dw.dim_calendario (
    data            date PRIMARY KEY,
    ano             int,
    mes             int,
    mes_nome        text,
    trimestre       int,
    dia             int,
    dia_semana_nome text,
    dia_util        boolean,
    feriado         text,
    ano_fiscal      text,               -- ex.: 'FY 2024-2025' (Abr-Mar)
    mes_fiscal      int
);


/* =====================================================================
   4) FATO (GOLD)
   Grao: item de nota fiscal. sk_ = chave substituta (surrogate).
   ===================================================================== */
DROP TABLE IF EXISTS dw.fato_faturamento;
CREATE TABLE dw.fato_faturamento (
    sk_faturamento  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- chaves de negocio (identificam a linha de NF)
    filial          text,
    nfe             text,
    serie           text,
    item_nf         text,
    -- chaves estrangeiras (ligam as dimensoes)
    cod_produto     text REFERENCES dw.dim_produto(cod_produto),
    chave_cliente   text REFERENCES dw.dim_cliente(chave_cliente),
    cod_vendedor    text REFERENCES dw.dim_vendedor(cod_vendedor),
    dt_emissao      date REFERENCES dw.dim_calendario(data),
    -- medidas
    qtd             numeric(18,3),      -- ja convertida para quilo quando aplicavel
    um              text,
    preco_unit      numeric(18,6),
    total           numeric(18,2),
    -- aliquotas de imposto (%)
    aliq_icms       numeric(9,4),
    aliq_pis        numeric(9,4),
    aliq_cofins     numeric(9,4),
    aliq_icmsst     numeric(9,4),
    -- atributos degenerados (ficam no proprio fato)
    cfop            text,
    cond_pgto       text,
    tab_preco       text,
    tipo            text,
    tipo_entrega    text,
    -- controle
    carregado_em    timestamp DEFAULT now(),
    UNIQUE (filial, nfe, serie, item_nf)
);

CREATE INDEX ix_fat_dtemissao ON dw.fato_faturamento (dt_emissao);
CREATE INDEX ix_fat_produto   ON dw.fato_faturamento (cod_produto);
CREATE INDEX ix_fat_cliente   ON dw.fato_faturamento (chave_cliente);


/* =====================================================================
   5) POVOAMENTO (dimensoes + fato)
   Este arquivo (01) cria apenas a ESTRUTURA e o de-para. O povoamento
   das dimensoes e do fato — que depende do raw ja carregado pela
   ingestao — fica em sql/02_povoar_dw.sql, para separar
   claramente "criar o modelo" de "carregar os dados".

   Ordem de execucao da fase de transformacao:
     1) sql/01_modelo_faturamento.sql        (este: DDL + map_produto_cx)
     2) ingestion/extract_protheus.py         (raw.faturamento/produtos/clientes/vendedores)
     3) ingestion/extract_dimensoes_excel.py  (raw.familia/regiao/calendario — fontes manuais)
     4) sql/02_povoar_dw.sql                  (dw.dim_* e dw.fato_faturamento)
   ===================================================================== */
