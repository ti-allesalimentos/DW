section Section1;

shared sqlSB2 = let
    Fonte = "
SELECT  
SB2.B2_FILIAL,
SB2.B2_COD,
SB2.B2_LOCAL,
SB2.B2_QATU, 
SB2.B2_QTSEGUM
FROM SB2010 SB2
WHERE SB2.D_E_L_E_T_ <> '*'
	AND SB2.B2_COD LIKE '%PA%'
	AND SB2.B2_LOCAL NOT IN ('DV', 'BO', 'AR', 'DP', 'CO')
    "
in
    Fonte;

shared fSB2 = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlSB2, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared #"sqlSB2 (2)" = let
    Fonte = "
SELECT  
SB2.B2_FILIAL,
SB2.B2_COD,
SB2.B2_LOCAL,
SB2.B2_QATU, 
SB2.B2_QTSEGUM
FROM SB2010 SB2
WHERE SB2.D_E_L_E_T_ <> '*'
	AND SB2.B2_COD LIKE '%PA%'

    "
in
    Fonte;

shared #"fSB2 (2)" = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=#"sqlSB2 (2)", CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlEdiCte = let
    Fonte = "
SELECT
GXG_FILDOC AS FILIAL,
GXG_EDIARQ AS ARQUIVO,
GXG_NRDF AS ""NR CTE"",
CAST(GXG_DTEMIS AS DATE) AS DTEMISSAO,
CAST(GXG_DTIMP AS DATE) AS DTIMPORTACAO,
GXG_CDESP AS ESPECIE,
GXG_EMISDF AS CODEMISSOR,
GU3.GU3_NMEMIT AS EMISSOR,
GXG_FRVAL AS VALOR,
GXG_PESOR AS PESO,
GXG_UFFIM AS ""UF INICIO"",
GXG_UFFIM AS ""UF DESTINO"",
CASE 
    WHEN GXG_EDISIT = '1' THEN 'IMPORTADO'
    WHEN GXG_EDISIT = '2' THEN 'IMPORTADO COM ERRO'
    WHEN GXG_EDISIT = '3' THEN 'REJEITADO'
    WHEN GXG_EDISIT = '4' THEN 'PROCESSADO'
ELSE 'ERRO IMPEDITIVO'
END AS SITUACAO
FROM GXG010 GXG
LEFT JOIN GU3010 GU3
ON GU3.D_E_L_E_T_ = ''
AND GU3_CDEMIT = GXG_EMISDF
WHERE GXG.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared fEdiCte = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlEdiCte, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlDocFrete = let
    Fonte = "
SELECT DISTINCT
    CASE
        WHEN GW3.GW3_TPDF = '1' THEN 'NORMAL'
        WHEN GW3.GW3_TPDF = '2' THEN 'COMPLEMENTAR VALOR'
        WHEN GW3.GW3_TPDF = '3' THEN 'COMPLEMENTAR IMPOSTO'
        WHEN GW3.GW3_TPDF = '4' THEN 'REENTREGA'
        WHEN GW3.GW3_TPDF = '5' THEN 'DEVOLUCAO'
        WHEN GW3.GW3_TPDF = '6' THEN 'REDESPACHO'
        WHEN GW3.GW3_TPDF = '7' THEN 'SERVICO'
        ELSE 'OUTRO'
    END             AS ""TIPO_DOCUMENTO"",
    GW4.GW4_FILIAL  AS ""Filial"",
    CAST(GW3.GW3_DTEMIS AS DATE)
                    AS ""Dt Emissao"",
    GW4.GW4_NRDF    AS ""Numero DF"",
    GW4.GW4_NRDC    AS ""Numero DC"",
    SUBSTRING(GW1.GW1_NRROM, 1, 6)
                    AS ""Numero Romaneio"",
    GU3.GU3_NMEMIT  AS ""Nome"",
    CAST(GW3.GW3_DTFIS AS DATE)
                    AS ""Data Fiscal"",
    GWD.GWD_DSOCOR  AS ""Descricao Ocorrencia"",
    GW3.GW3_VLDF    AS ""Valor Docto"",
    GW4.GW4_CDESP   AS ""Especie Doc"",
    GW4.GW4_SERDF   AS ""Serie DF"",
    GW4.GW4_EMISDF  AS ""Emissor DF"",
    AC9.AC9_CODOBJ  AS ""Cod. Objeto""
FROM GW4010 GW4
    LEFT JOIN GU3010 GU3 ON GU3.D_E_L_E_T_ = ''
        AND GW4.GW4_EMISDF = GU3.GU3_CDEMIT
    LEFT JOIN GW3010 GW3 ON GW3.D_E_L_E_T_ = ''
        AND GW4.GW4_FILIAL = GW3.GW3_FILIAL
        AND GW4.GW4_CDESP  = GW3.GW3_CDESP
        AND GW4.GW4_EMISDF = GW3.GW3_EMISDF
        AND GW4.GW4_SERDF  = GW3.GW3_SERDF
        AND GW4.GW4_NRDF   = GW3.GW3_NRDF
    LEFT JOIN GW1010 GW1 ON GW1.D_E_L_E_T_ = ''
        AND GW4.GW4_FILIAL = GW1.GW1_FILIAL
        AND GW4.GW4_EMISDC = GW1.GW1_EMISDC
        AND GW4.GW4_SERDC  = GW1.GW1_SERDC
        AND GW4.GW4_NRDC   = GW1.GW1_NRDC
    LEFT JOIN GWL010 GWL ON GWL.D_E_L_E_T_ = ''
        AND GW4.GW4_FILIAL = GWL.GWL_FILIAL
        AND GW4.GW4_NRDC   = GWL.GWL_NRDC
        AND GW4.GW4_EMISDC = GWL.GWL_EMITDC
        AND GW4.GW4_SERDC  = GWL.GWL_SERDC
        AND GW4.GW4_TPDC   = GWL.GWL_TPDC
    LEFT JOIN GWD010 GWD ON GWD.D_E_L_E_T_ = ''
        AND GWL.GWL_FILIAL = GWD.GWD_FILIAL
        AND GWL.GWL_NROCO  = GWD.GWD_NROCO
        AND GW1.GW1_EMISDC = GWD.GWD_CDTRP
    LEFT JOIN AC9010 AC9 ON AC9.D_E_L_E_T_ = ''
        AND AC9.AC9_ENTIDA = 'GWD'
        AND GWL.GWL_FILIAL + GWL.GWL_NROCO = AC9.AC9_CODENT
WHERE GW4.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared fDocFrete = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlDocFrete, CommandTimeout=#duration(69, 10, 39, 0)]),
  #"Texto aparado 1" = Table.TransformColumns(Fonte, {{"Cod. Objeto", each Text.Trim(_), type nullable text}, {"Emissor DF", each Text.Trim(_), type text}, {"Serie DF", each Text.Trim(_), type text}, {"Especie Doc", each Text.Trim(_), type text}, {"Nome", each Text.Trim(_), type nullable text}, {"Descricao Ocorrencia", each Text.Trim(_), type nullable text}, {"Numero DC", each Text.Trim(_), type text}, {"Numero DF", each Text.Trim(_), type text}, {"Filial", each Text.Trim(_), type text}, {"TIPO_DOCUMENTO", each Text.Trim(_), type text}}),
  #"Tipo de coluna alterado" = Table.TransformColumnTypes(#"Texto aparado 1", {{"Valor Docto", Currency.Type}, {"Data Fiscal", type date}, {"Dt Emissao", type date}})
in
  #"Tipo de coluna alterado";

shared __STATUS__ = let
    Fonte = if Table.RowCount(Table.Combine({fSB2, #"fSB2 (2)", fEdiCte, fDocFrete})) > 0 then DateTime.LocalNow() else "Pendente"
in
    Fonte;