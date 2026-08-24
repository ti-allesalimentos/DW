section Section1;

shared sqlFornecedor = let
    Fonte = "
SELECT 
    SA2.A2_COD      AS CODFOR, 
    SA2.A2_LOJA     AS LJFOR,
    SA2.A2_NREDUZ   AS FORNECEDOR,
	SA2.A2_CGC      AS CNPJ,
	SA2.A2_NOME     AS NOMEFORNECE,
    SA2.A2_END      AS ENDERECO,
    SA2.A2_BAIRRO   AS BAIRRO,
    SA2.A2_MUN      AS CIDADE,
    SA2.A2_EST      AS UF,
    SA2.A2_CEP      AS CEP,
    SA2.A2_EMAIL    AS ""E-MAIL"",
    SA2.A2_GRPTRIB  AS GRPTRIB
FROM 
    SA2010 SA2
WHERE 
    SA2.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared dFornecedor = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlFornecedor, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlProduto = let
    Fonte = "
SELECT 
    SB1.B1_COD, 
    SB1.B1_DESC, 
    SB1.B1_UM, 
    SB1.B1_EMIN, 
    SB1.B1_ESTSEG, 
    SB1.B1_PE, 
    SB1.B1_TIPE, 
    SB1.B1_LE, 
    SB1.B1_LM
FROM 
    SB1010 SB1
WHERE 
    SB1.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared dProduto = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlProduto, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlForneceSE2 = let
    Fonte = "
SELECT 
    SE2.E2_FORNECE,
    SE2.E2_LOJA,
    SE2.E2_NOMFOR
FROM SE2010 SE2
WHERE SE2.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared dForneceSE2 = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlForneceSE2, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqldCondPag = let
    Fonte = "
    SELECT
        E4_CODIGO AS COD,
        E4_TIPO AS TIPO,
        E4_COND AS COND,
        E4_DDD AS FORADIA
    FROM SE4010 WHERE D_E_L_E_T_ = ''
    "
in
    Fonte;

shared dCondPag = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqldCondPag, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared __STATUS__ = let
    Fonte = if Table.RowCount(Table.Combine({dFornecedor, dProduto, dForneceSE2, dCondPag})) > 0 then DateTime.LocalNow() else "Pendente"
in
    Fonte;

shared __SQL__ = let
    #"Linhas Filtradas" = Table.SelectRows(Record.ToTable(#shared), each Text.StartsWith([Name], "sql"))
in
    #"Linhas Filtradas";