section Section1;

shared dEstados = let
    Fonte = Excel.Workbook(File.Contents("\\192.168.67.201\Departamentos$\PUBLICA\T.I\01. BASES\fManual.xlsx"), null, true),
    dRegiao_Table = Fonte{[Item="dRegiao",Kind="Table"]}[Data],
    #"Colunas Renomeadas" = Table.RenameColumns(dRegiao_Table,{{"Coluna 1", "Unidade federativa"}, {"Coluna 2", "Sigla"}, {"Coluna 3", "Região"}})
in
    #"Colunas Renomeadas";

shared sqlClientes = let
    Fonte = "
SELECT
    SA1.A1_COD      AS _COD,
    SA1.A1_LOJA     AS _LJ,
    SA1.A1_PESSOA   AS _PFJ,
    SA1.A1_NOME     AS _NOMECLIENTE,
    SA1.A1_NREDUZ   AS _NREDUZCLIENTE,
    SA1.A1_GRPVEN   AS _CODRED,
    SA1.A1_END      AS _ENDCLIENTE,
    SA1.A1_BAIRRO   AS _BAIRROCLIENTE,
    SA1.A1_EST      AS _ESTCLIENTE,
    SA1.A1_CGC      AS _CGCCLIENTE,
    SA1.A1_MUN      AS _MUNCLIENTE,
    SA1.A1_X_FREC   AS _FORMAPGTOCLIENTE,
    SA1.A1_COND     AS _CONDPGTO,
    SA1.A1_CONTA    AS _CONTACONTABIL,
    SA1.A1_BCO1     AS _BCOCLIENTE,
    SA1.A1_COMIS    AS _COMISCLIENTE,
    SA1.A1_DESC     AS _DESCCLIENTE,
    SA1.A1_VEND     AS _CODVEND,
    SA1.A1_VEND3    AS _GERENTE,
    CAST(SA1.A1_DTCAD AS DATE)
                    AS DTCADASTRO,
    CAST(SA1.A1_ULTCOM AS DATE)
                    AS _DTAULTCOMPRA,
    SA1.A1_CEP      AS CEP,
    SA1.A1_X_TPCLI  AS TPCLI,
    SA1.A1_TIPO     AS TP,
    SA1.A1_MSBLQL   AS _SITUACAO
FROM SA1010 SA1
WHERE SA1.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared dClientes = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlClientes, CommandTimeout=#duration(69, 10, 39, 0)]),
  #"Colunas renomeadas" = Table.RenameColumns(Fonte, {{"_COMISCLIENTE", "_%COMISCLIENTE"}, {"_DESCCLIENTE", "_%DESCCLIENTE"}}),
  #"Colunas mescladas" = Table.CombineColumns(#"Colunas renomeadas", {"_COD", "_LJ"}, Combiner.CombineTextByDelimiter("", QuoteStyle.None), "_CHAVECLIENTE"),
  #"Consultas mescladas" = Table.NestedJoin(#"Colunas mescladas", {"_ESTCLIENTE"}, dEstados, {"Sigla"}, "dEstados", JoinKind.LeftOuter),
  #"Expandido dEstados" = Table.ExpandTableColumn(#"Consultas mescladas", "dEstados", {"Unidade federativa", "Região"}, {"Unidade federativa", "Região"}),
  #"Colunas reordenadas" = Table.ReorderColumns(#"Expandido dEstados", {"_CHAVECLIENTE", "_PFJ", "_NOMECLIENTE", "_NREDUZCLIENTE", "_ENDCLIENTE", "_BAIRROCLIENTE", "_ESTCLIENTE", "Região", "Unidade federativa", "_CGCCLIENTE", "_MUNCLIENTE", "_FORMAPGTOCLIENTE", "_CONDPGTO", "_CONTACONTABIL", "_BCOCLIENTE", "_%COMISCLIENTE", "_%DESCCLIENTE", "_CODVEND", "_DTAULTCOMPRA"}),
  #"Texto em maiúscula" = Table.TransformColumns(#"Colunas reordenadas", {{"Região", each Text.Upper(_), type nullable text}, {"Unidade federativa", each Text.Upper(_), type nullable text}}),
  #"Colunas renomeadas 1" = Table.RenameColumns(#"Texto em maiúscula", {{"Região", "_REGIAOCLIENTE"}, {"Unidade federativa", "_ESTCLIENTEDESCR"}}),
  #"Colunas reordenadas 1" = Table.ReorderColumns(#"Colunas renomeadas 1", {"_CHAVECLIENTE", "_PFJ", "_NOMECLIENTE", "_NREDUZCLIENTE", "_ENDCLIENTE", "_BAIRROCLIENTE", "_ESTCLIENTE", "_ESTCLIENTEDESCR", "_REGIAOCLIENTE", "_CGCCLIENTE", "_MUNCLIENTE", "_FORMAPGTOCLIENTE", "_CONDPGTO", "_CONTACONTABIL", "_BCOCLIENTE", "_%COMISCLIENTE", "_%DESCCLIENTE", "_CODVEND", "_DTAULTCOMPRA"}),
  #"Tipo de coluna alterado" = Table.TransformColumnTypes(#"Colunas reordenadas 1", {{"_DTAULTCOMPRA", type date}, {"DTCADASTRO", type date}})
in
  #"Tipo de coluna alterado";

shared sqlRedes = let
    Fonte = "
SELECT
    ACY.ACY_GRPVEN,
    ACY.ACY_DESCRI
FROM ACY010 ACY
WHERE ACY.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared dRedes = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlRedes, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlCondPgt = let
    Fonte = "
SELECT
    SE4.E4_CODIGO   AS CODCOND,
    SE4.E4_COND     AS CONDICAO,
    SE4.E4_DESCRI   AS DESCRICOND,
    SE4.E4_DESCFIN / 100
                    AS DESCFIN
FROM SE4010 SE4
WHERE SE4.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared dCondPgt = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlCondPgt, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlTabelaPreco = let
    Fonte = "
SELECT DISTINCT
    DA0.DA0_CODTAB  AS CODTABELA,
    DA0.DA0_DESCRI  AS DESCRICAO,
    DA1.DA1_CODPRO  AS CODPROD,
    SB1.B1_DESC     AS PRODUTO,
    DA1.DA1_PRCVEN  AS PRCUNIT,
    DA1.DA1_ESTADO  AS UF
FROM DA0010 DA0
    INNER JOIN DA1010 DA1 ON DA1.D_E_L_E_T_ = ''
        AND DA1.DA1_FILIAL = DA0.DA0_FILIAL
        AND DA1.DA1_CODTAB = DA0.DA0_CODTAB
    INNER JOIN SB1010 SB1 ON SB1.D_E_L_E_T_ = ''
        AND SB1.B1_COD = DA1.DA1_CODPRO
WHERE DA0.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared dTabelaPreco = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlTabelaPreco, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlfProspect = let
    Fonte = "
SELECT
SUS.US_NOME,
SUS.US_CGC,
SUS.US_MUN,
SUS.US_EST,
SUS.US_DDD,
SUS.US_TEL,
SUS.US_EMAIL,
CAST(SUS.US_DTCAD AS DATE) AS DTCADASTRO,
SUS.US_STATUS,
SUS.US_VEND,
SUS.US_X_MOTI AS MOTIVO,
SUS.US_X_TRAV AS IMPEDITIVO
FROM SUS010 SUS
WHERE SUS.D_E_L_E_T_ = ''
AND SUS.US_VEND NOT IN ('000000', '')
    "
in
    Fonte;

shared fProspect = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlfProspect, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared __STATUS__ = let
    Fonte = if Table.RowCount(Table.Combine({dTabelaPreco, dEstados, dClientes, dRedes, dCondPgt})) > 0 then DateTime.LocalNow() else "Pendente"
in
    Fonte;