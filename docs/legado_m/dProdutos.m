section Section1;

shared dFamilia = let
    Fonte = Excel.Workbook(File.Contents("\\192.168.67.201\Departamentos$\PUBLICA\T.I\01. BASES\fManual.xlsx"), null, true),
    dGrupo_ = Fonte{[Item="dFamilia",Kind="Table"]}[Data]
in
	dGrupo_;

shared sqldProdutos = let
    Fonte = "
SELECT 
    SB1.B1_COD      AS _CODPRODUTO,
    SB1.B1_DESC     AS _DESCPRODUTO,
    SB1.B1_TIPO     AS _TIPOPRDUTO,
    SB1.B1_UM       AS _UNIDADEMEDIDAPRODUTO,
    SB1.B1_GRUPO    AS _GRUPOESTOQUE,
    SB1.B1_UCOM     AS _DTAULTCOMPRA,
    SB1.B1_CONTA    AS _CONTA,
    SB1.B1_X_AGRUP,
    SB1.B1_UPRC     AS ""Ult. Preco Comp."" 
FROM SB1010 SB1
WHERE SB1.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared dProdutos = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqldProdutos, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqldGrupo = let
    Fonte = "
SELECT
    SBM.BM_GRUPO AS GRUPO,
    SBM.BM_DESC  AS DESCRICAO
FROM SBM010 SBM
WHERE SBM.D_E_L_E_T_ = '' 
    "
in
    Fonte;

shared dGrupo = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqldGrupo, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared __STATUS__ = let
    Fonte = if Table.RowCount(Table.Combine({dProdutos, dFamilia, dGrupo})) > 0 then DateTime.LocalNow() else "Pendente"
in
    Fonte;

shared __SQL__ = let
    Fonte = Table.SelectRows(Record.ToTable(#shared), each Text.StartsWith([Name], "sql"))
in
    Fonte;