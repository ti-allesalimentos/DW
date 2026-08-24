section Section1;

shared sqlProdutoAcabado = let
    Fonte = "
SELECT 
    SD3.D3_FILIAL       AS FILIAL,
    SC2.C2_PRODUTO      AS CODPAI,
    SB1_PAI.B1_DESC     AS PRODUTOPAI,
    SD3.D3_OP           AS OP,
    SD3.D3_COD          AS CODPROD,
    SB1_FILHO.B1_DESC   AS PRODUTO,
    SD3.D3_UM           AS UM,
    SUM(SD3.D3_QUANT)   AS QTD_TOTAL,
    SD3.D3_TM           AS TM,
    SD3.D3_GRUPO        AS GRUPOPROD,
    CAST(MIN(SD3.D3_EMISSAO) AS DATE)
                        AS DTPRODUCAO
FROM SD3010 SD3
INNER JOIN SC2010 SC2 
    ON SC2.D_E_L_E_T_ = '' 
    AND SC2.C2_FILIAL = SD3.D3_FILIAL 
    AND (SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN) = SD3.D3_OP
INNER JOIN SB1010 SB1_PAI 
    ON SB1_PAI.D_E_L_E_T_ = '' 
    AND SB1_PAI.B1_COD = SC2.C2_PRODUTO
INNER JOIN SB1010 SB1_FILHO 
    ON SB1_FILHO.D_E_L_E_T_ = '' 
    AND SB1_FILHO.B1_COD = SD3.D3_COD
WHERE SD3.D_E_L_E_T_ = ''
    AND SD3.D3_OP <> ''
    AND SD3.D3_COD NOT LIKE '%MOD%'
    AND SD3.D3_OP NOT LIKE '%OS%'
    AND SD3.D3_TM = '010'
GROUP BY 
    SD3.D3_FILIAL,
    SC2.C2_PRODUTO,
    SB1_PAI.B1_DESC,
    SD3.D3_OP,
    SD3.D3_COD,
    SB1_FILHO.B1_DESC,
    SD3.D3_UM,
    SD3.D3_TM,
    SD3.D3_GRUPO
    "
in
    Fonte;

shared dProdutoAcabado = let
  Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlProdutoAcabado, CommandTimeout=#duration(69, 10, 39, 0)]),
  #"Tipo de coluna alterado" = Table.TransformColumnTypes(Fonte, {{"DTPRODUCAO", type date}}),
  #"Linhas filtradas" = Table.SelectRows(#"Tipo de coluna alterado", each ([FILIAL] = "01004"))
in
  #"Linhas filtradas";

shared sqlConsumo = let
    Fonte = "
SELECT 
    SD3.D3_FILIAL       AS FILIAL,
    SC2.C2_PRODUTO      AS CODPAI,
    SB1_PAI.B1_DESC     AS PRODUTOPAI,
    SD3.D3_OP           AS OP,
    SD3.D3_COD          AS CODPROD,
    SB1_FILHO.B1_DESC   AS PRODUTO,
    SD3.D3_UM           AS UM,
    SUM(SD3.D3_QUANT)   AS QTD_TOTAL,
    SD3.D3_TM           AS TM,
    SD3.D3_GRUPO        AS GRUPOPROD,
   CAST(MIN(SD3.D3_EMISSAO) AS DATE)
                        AS DTENTRADA
FROM SD3010 SD3
INNER JOIN SC2010 SC2 ON SC2.D_E_L_E_T_ = '' 
    AND SC2.C2_FILIAL = SD3.D3_FILIAL 
    AND (SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN) = SD3.D3_OP
INNER JOIN SB1010 SB1_PAI ON SB1_PAI.D_E_L_E_T_ = '' 
    AND SB1_PAI.B1_COD = SC2.C2_PRODUTO
INNER JOIN SB1010 SB1_FILHO ON SB1_FILHO.D_E_L_E_T_ = '' 
    AND SB1_FILHO.B1_COD = SD3.D3_COD
WHERE SD3.D_E_L_E_T_ = ''
    AND SD3.D3_OP <> ''
    AND SD3.D3_COD NOT LIKE '%MOD%'
    AND SD3.D3_OP NOT LIKE '%OS%'
    AND SD3.D3_CF LIKE '%RE%'
	AND SD3.D3_ESTORNO <> 'S'
GROUP BY 
    SD3.D3_FILIAL,
    SC2.C2_PRODUTO,
    SB1_PAI.B1_DESC,
    SD3.D3_OP,
    SD3.D3_COD,
    SB1_FILHO.B1_DESC,
    SD3.D3_UM,
    SD3.D3_TM,
    SD3.D3_GRUPO,
	SD3.D3_EMISSAO
    "
in
    Fonte;

shared dConsumo = let
  Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlConsumo, CommandTimeout=#duration(69, 10, 39, 0)]),
  #"Tipo de coluna alterado" = Table.TransformColumnTypes(Fonte, {{"DTENTRADA", type date}})
in
    #"Tipo de coluna alterado";

shared sqlEntradas = let
    Fonte = "
SELECT DISTINCT 
SF1.F1_FILIAL   AS FILIAL,
SF1.F1_DOC      AS NF,
SF1.F1_SERIE    AS SERIE,
SF1.F1_FORNECE  AS CODFOR,
SF1.F1_LOJA     AS LJ,
SF1.F1_COND     AS CONDPAG,
CAST(SF1.F1_EMISSAO AS DATE)
                AS DTEMISSAO,
CAST(SF1.F1_DTDIGIT AS DATE)
                AS DTLANCAMENTO,
SD1.D1_COD      AS CODIGO,
SD1.D1_UM       AS UM,
SD1.D1_QUANT    AS QTD,
SD1.D1_VUNIT    AS VRUNIT,
SD1.D1_TOTAL    AS VRTOTAL
FROM SF1010 SF1
INNER JOIN SD1010 SD1 ON SD1.D_E_L_E_T_ = '' 
	AND SD1.D1_FILIAL = SF1.F1_FILIAL 
	AND SD1.D1_DOC  = SF1.F1_DOC
	AND SD1.D1_SERIE = SF1.F1_SERIE
	AND SD1.D1_FORNECE = SF1.F1_FORNECE
	AND SD1.D1_LOJA = SF1.F1_LOJA
WHERE SF1.D_E_L_E_T_ = ''
	AND SF1.F1_TIPO IN ('N', 'C')
    AND SF1.F1_DOC <> '0000000NF'
 AND SF1.F1_DOC <> '20062501Q'
    "
in
    Fonte;

shared dEntradas = let
  Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlEntradas, CommandTimeout=#duration(69, 10, 39, 0)]),
  #"Tipo de coluna alterado" = Table.TransformColumnTypes(Fonte, {{"DTEMISSAO", type date}, {"DTLANCAMENTO", type date}})
in
    #"Tipo de coluna alterado";

shared sqlSaldoInicial = let
    Fonte = "
SELECT
    B9.B9_FILIAL,
    B9.B9_COD,
    B9.B9_LOCAL,
    B9.B9_DATA,
    B9.B9_QINI,
    B9.B9_VINI1,
    B9.B9_CM1
FROM SB9010 B9
WHERE B9.D_E_L_E_T_ = '' 
    AND B9.B9_DATA = ''
    "
in
    Fonte;

shared dSaldoInicial = let
  Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlSaldoInicial, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlComissao = let
    Fonte = "
SELECT DISTINCT 
SF1.F1_FILIAL   AS FILIAL,
SF1.F1_DOC      AS NF,
SF1.F1_SERIE    AS SERIE,
SF1.F1_FORNECE  AS CODFOR,
SF1.F1_LOJA     AS LJ,
SF1.F1_COND     AS CONDPAG,
CAST(SF1.F1_EMISSAO AS DATE)
                AS DTEMISSAO,
CAST(SF1.F1_DTDIGIT AS DATE)
                AS DTLANCAMENTO,
SD1.D1_COD      AS CODIGO,
SD1.D1_UM       AS UM,
SD1.D1_QUANT    AS QTD,
SD1.D1_VUNIT    AS VRUNIT,
SD1.D1_TOTAL    AS VRTOTAL,
SD1.D1_NFORI,
SD1.D1_SERIORI
FROM SF1010 SF1
INNER JOIN SD1010 SD1 ON SD1.D_E_L_E_T_ = '' 
	AND SD1.D1_FILIAL = SF1.F1_FILIAL 
	AND SD1.D1_DOC  = SF1.F1_DOC
	AND SD1.D1_SERIE = SF1.F1_SERIE
	AND SD1.D1_FORNECE = SF1.F1_FORNECE
	AND SD1.D1_LOJA = SF1.F1_LOJA
WHERE SF1.D_E_L_E_T_ = ''
	AND SF1.F1_TIPO = 'C'

    "
in
    Fonte;

shared dComissao = let
  Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlComissao, CommandTimeout=#duration(69, 10, 39, 0)]),
  #"Tipo de coluna alterado" = Table.TransformColumnTypes(Fonte, {{"DTEMISSAO", type date}, {"DTLANCAMENTO", type date}}),
  #"Linhas filtradas" = Table.SelectRows(#"Tipo de coluna alterado", each ([SERIE] = "COM")),
  #"Linhas agrupadas" = Table.Group(#"Linhas filtradas", {"FILIAL", "NF", "SERIE", "CODFOR", "LJ", "CODIGO", "D1_NFORI", "D1_SERIORI"}, {{"Vr Total", each List.Sum([VRTOTAL]), type nullable number}}),
  #"Duplicatas removidas" = Table.Distinct(#"Linhas agrupadas", {"FILIAL", "NF", "SERIE", "CODFOR", "LJ", "CODIGO", "D1_NFORI", "D1_SERIORI", "Vr Total"})
in
  #"Duplicatas removidas";

shared sqlCCusto = let
    Fonte = "
SELECT DISTINCT
    SD3.D3_FILIAL   AS FILIAL,
    CAST(SD3.D3_EMISSAO AS DATE)       
                    AS DTEMISSAO,
    SD3.D3_COD      AS CODPROD,
    SB1.B1_DESC     AS PRODUTO,
    SD3.D3_QUANT    AS QTD,
    SD3.D3_UM       AS UM,
    SD3.D3_CC       AS CCUSTO,
    CTT.CTT_DESC01  AS DESCCENTROCUSTO
FROM SD3010 SD3
    INNER JOIN SB1010 SB1 ON SB1.D_E_L_E_T_ = ''
        AND SB1.B1_COD = SD3.D3_COD
    INNER JOIN CTT010 CTT ON CTT.D_E_L_E_T_ = ''
        AND CTT.CTT_CUSTO = SD3.D3_CC
WHERE SD3.D_E_L_E_T_ = ''
    AND SD3.D3_OP = ''
    AND SD3.D3_TM = '505'
    AND SD3.D3_CC <> ''
    "
in
    Fonte;

shared fCCusto = let
  Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlCCusto, CommandTimeout=#duration(69, 10, 39, 0)]),
  #"Tipo de coluna alterado" = Table.TransformColumnTypes(Fonte, {{"DTEMISSAO", type date}})
in
  #"Tipo de coluna alterado";

shared sqlPerdas = let
    Fonte = "
SELECT 
    CAST(MIN(SD3.D3_EMISSAO) AS DATE)
                        AS DTLANCAMENTO,
    SD3.D3_FILIAL       AS ""BC_FILIAL"",
    SD3.D3_OP           AS ""BC_OP"",
    SC2.C2_PRODUTO      AS CODPAI,
    SB1_PAI.B1_DESC     AS PRODUTOPAI,
    SD3.D3_COD          AS ""BC_PRODUTO"",
    SB1_FILHO.B1_DESC   AS ""B1_DESC"",
    SUM(SD3.D3_QUANT)   AS ""BC_QUANT""
FROM SD3010 SD3
INNER JOIN SC2010 SC2 ON SC2.D_E_L_E_T_ = '' 
    AND SC2.C2_FILIAL = SD3.D3_FILIAL 
    AND (SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN) = SD3.D3_OP
INNER JOIN SB1010 SB1_PAI ON SB1_PAI.D_E_L_E_T_ = '' 
    AND SB1_PAI.B1_COD = SC2.C2_PRODUTO
INNER JOIN SB1010 SB1_FILHO ON SB1_FILHO.D_E_L_E_T_ = '' 
    AND SB1_FILHO.B1_COD = SD3.D3_COD
WHERE SD3.D_E_L_E_T_ = ''
    AND SD3.D3_OP <> ''
    AND SD3.D3_TM = '507'
	AND SD3.D3_ESTORNO <> 'S'
GROUP BY 
    SD3.D3_FILIAL,
    SC2.C2_PRODUTO,
    SB1_PAI.B1_DESC,
    SD3.D3_OP,
    SD3.D3_COD,
    SB1_FILHO.B1_DESC,
	SD3.D3_EMISSAO
    "
in
    Fonte;

shared fPerdas = let
  Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlPerdas, CommandTimeout=#duration(69, 10, 39, 0)]),
  #"Tipo de coluna alterado" = Table.TransformColumnTypes(Fonte, {{"DTLANCAMENTO", type date}}),
  #"Nome do mês inserido" = Table.AddColumn(#"Tipo de coluna alterado", "Nome do mês", each Date.MonthName([DTLANCAMENTO]), type nullable text),
  #"Texto aparado" = Table.TransformColumns(#"Nome do mês inserido", {{"PRODUTOPAI", each Text.Trim(_), type text}}),
  #"Texto aparado 1" = Table.TransformColumns(#"Texto aparado", {{"B1_DESC", each Text.Trim(_), type text}})
in
  #"Texto aparado 1";

shared sqlFrenteEntradas = let
    Fonte = "
WITH CTE_GW3 AS (
    SELECT DISTINCT
        GW3_NRDF,
        GW3_VLDF,
        GW3_CDESP,
        GW3_EMISDF,
        GW3_SERDF,
        GW3_DTEMIS
    FROM GW3010
    WHERE D_E_L_E_T_ = ''
),

CTE_CTE_AGG AS (
    SELECT
        GW1_NRDC,
        GW1_CDTPDC,
        GW1_SERDC,
        GW1_EMISDC,
        STRING_AGG(
            RTRIM(GW3.GW3_NRDF) + ':' +
            CAST(GW3.GW3_VLDF AS VARCHAR(20)),
            ' - '
        ) AS CTE_VLDF
    FROM (
        SELECT DISTINCT
            GW1_NRDC,
            GW1_CDTPDC,
            GW1_SERDC,
            GW1_EMISDC,
            GW3.GW3_NRDF,
            GW3.GW3_VLDF
        FROM GW1010 GW1
        INNER JOIN GW4010 GW4
            ON GW4.D_E_L_E_T_ = ''
            AND GW1_NRDC   = GW4_NRDC
            AND GW1_CDTPDC = GW4_TPDC
            AND GW1_SERDC  = GW4_SERDC
            AND GW1_EMISDC = GW4_EMISDC
        INNER JOIN CTE_GW3 GW3
            ON GW3.GW3_CDESP  = GW4_CDESP
            AND GW3.GW3_EMISDF = GW4_EMISDF
            AND GW3.GW3_SERDF  = GW4_SERDF
            AND GW3.GW3_NRDF   = GW4_NRDF
            AND GW3.GW3_DTEMIS = GW4_DTEMIS
        WHERE GW1.D_E_L_E_T_ = ''
    ) GW3
    GROUP BY GW1_NRDC, GW1_CDTPDC, GW1_SERDC, GW1_EMISDC
)

SELECT
    GWM_FILIAL  AS FILIAL,
    GWM_NRDC    AS NF,
    GWM_SEQGW8  AS ITEM,
    GWM_SERDC   AS SERIE,

    SA2.A2_COD  AS CODFOR,
    SA2.A2_LOJA AS LJ,

    MAX(CAST(GWM_DTEMDC AS DATE)) AS DTEMISSAO,

    MAX(GWM_ITEM)      AS CODIGO,
    MAX(SD1.D1_UM)     AS UM,

    SUM(SD1.D1_QUANT)  AS QTD,
    MAX(SD1.D1_VUNIT)  AS VRUNIT,
    SUM(SD1.D1_TOTAL)  AS VRTOTAL,

    SUM(GWM_VLFRE1)    AS FRETE,
    MAX(GWM_PCRAT) / 100    AS PERCENTUAL,

    MAX(AGG.CTE_VLDF)  AS CTE_VLDF

FROM GWM010 GWM

LEFT JOIN GW1010 GW1
    ON GW1.D_E_L_E_T_ = ''
    AND GW1_CDTPDC  = GWM_CDTPDC
    AND GW1_EMISDC  = GWM_EMISDC
    AND GW1_SERDC   = GWM_SERDC
    AND GW1_NRDC    = GWM_NRDC

LEFT JOIN GU3010 GU3
    ON GU3.D_E_L_E_T_ = ''
    AND GWM.GWM_EMISDC = GU3.GU3_CDEMIT

LEFT JOIN SA2010 SA2
    ON SA2.D_E_L_E_T_ = ''
    AND REPLACE(REPLACE(REPLACE(SA2.A2_CGC,'.',''),'/',''),'-','')
      = REPLACE(REPLACE(REPLACE(GU3.GU3_IDFED,'.',''),'/',''),'-','')

LEFT JOIN SD1010 SD1
    ON SD1.D_E_L_E_T_ = ''
    AND SD1.D1_FILIAL  = GWM_FILIAL
    AND SD1.D1_DOC     = GWM_NRDC
    AND SD1.D1_ITEM    = GWM_SEQGW8
    AND SD1.D1_SERIE   = GWM_SERDC
    AND SD1.D1_FORNECE = SA2.A2_COD
    AND SD1.D1_LOJA    = SA2.A2_LOJA

LEFT JOIN CTE_CTE_AGG AGG
    ON AGG.GW1_NRDC   = GWM_NRDC
    AND AGG.GW1_CDTPDC = GWM_CDTPDC
    AND AGG.GW1_SERDC  = GWM_SERDC
    AND AGG.GW1_EMISDC = GWM_EMISDC

WHERE GWM.D_E_L_E_T_ = ''
    AND GWM_TPDOC = '1'
    AND GWM.GWM_DTEMIS > 20260416
    AND GWM.GWM_ITEM NOT LIKE 'PA%'
    AND GWM.GWM_ITEM NOT LIKE 'AM%'
    -- AND GWM.GWM_NRDC = '000031272       '

GROUP BY
    GWM_FILIAL,
    GWM_NRDC,
    GWM_SEQGW8,
    GWM_SERDC,
    SA2.A2_COD,
    SA2.A2_LOJA

ORDER BY
    FILIAL,
    NF,
    ITEM
    "
in
    Fonte;

shared dFrenteEntradas = let
  Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlFrenteEntradas, CommandTimeout=#duration(69, 10, 39, 0)]),
    #"Tipo Alterado" = Table.TransformColumnTypes(Fonte,{{"DTEMISSAO", type date}, {"FRETE", Currency.Type}, {"VRTOTAL", Currency.Type}, {"VRUNIT", Currency.Type}, {"QTD", Currency.Type}, {"PERCENTUAL", Percentage.Type}})
in
    #"Tipo Alterado";

shared sqldCTT = let
    Fonte = "
SELECT
CTT.CTT_CUSTO AS CC,
CTT.CTT_DESC01 AS DESCRICAO_CC
FROM CTT010 CTT
WHERE CTT.D_E_L_E_T_ = ''
AND CTT.CTT_FILIAL = '01'
AND CTT.CTT_CUSTO > '01'
AND CTT.CTT_CUSTO < '03'
    "
in
    Fonte;

shared dCTT = let
  Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqldCTT, CommandTimeout=#duration(69, 10, 39, 0)]),
    #"Texto Cortado" = Table.TransformColumns(Fonte,{{"CC", Text.Trim, type text}})
in
    #"Texto Cortado";

shared __STATUS__ = let
    Fonte = if Table.RowCount(Table.Combine({dProdutoAcabado, dConsumo, dEntradas, dSaldoInicial, dComissao, fCCusto, fPerdas, dFrenteEntradas})) > 0 then DateTime.LocalNow() else "Pendente"
in
    Fonte;

shared __SQL__ = let
    #"Linhas Filtradas" = Table.SelectRows(Record.ToTable(#shared), each Text.StartsWith([Name], "sql"))
in
    #"Linhas Filtradas";