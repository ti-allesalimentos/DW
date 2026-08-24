section Section1;

shared __STATUS__ = let
    Fonte = if Table.RowCount(Table.Combine({fNotasSemAnexo, fDocCont, fConfLanc, fSaidas, fPedidos})) > 0 then DateTime.LocalNow() else "Pendente"
in
    Fonte;

shared __SQL__ = let
    #"Linhas Filtradas" = Table.SelectRows(Record.ToTable(#shared), each Text.StartsWith([Name], "sql"))
in
    #"Linhas Filtradas";

shared sqlfNotasSemAnexo = let
    Fonte = "
SELECT 
    SF1.F1_FILIAL,
    SF1.F1_ESPECIE,
    SF1.F1_DOC,
    SF1.F1_SERIE,
    SF1.F1_FORNECE,
    SF1.F1_LOJA,
    SA2.A2_NOME,
    CAST(SF1.F1_EMISSAO AS DATE) AS F1_EMISSAO,
    AC9.AC9_FILENT,
    AC9.AC9_CODENT,
    AC9.AC9_CODOBJ
FROM SF1010 SF1
    LEFT JOIN SA2010 SA2 ON SA2.D_E_L_E_T_ <> '*'
        AND SF1.F1_FORNECE  = SA2.A2_COD
        AND SF1.F1_LOJA     = SA2.A2_LOJA
    LEFT JOIN AC9010 AC9 ON AC9.D_E_L_E_T_ = ''
        AND AC9.AC9_ENTIDA = 'SF1'
        AND SF1.F1_FILIAL = AC9.AC9_FILENT
        AND SF1.F1_DOC + SF1.F1_SERIE + SF1.F1_FORNECE + SF1.F1_LOJA = AC9.AC9_CODENT
WHERE SF1.D_E_L_E_T_ = ''
    AND SF1.F1_ESPECIE NOT IN ('SPED', 'CTE')
    "
in
    Fonte;

shared fNotasSemAnexo = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlfNotasSemAnexo, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlfDocCont = let
    Fonte = "
SELECT
    SF1.F1_FILIAL   AS FILIAL,
    SF1.F1_DOC      AS NF,
    SF1.F1_SERIE    AS SERIE,
    SD1.D1_ITEM     AS ITEM,
    SD1.D1_COD      AS CODIGO,
    SB1.B1_DESC     AS DESCRICAO,
    SX52.X5_DESCRI  AS TIPO_DESC,
    SBM.BM_DESC     AS DESCRICAO,
    SD1.D1_TOTAL    AS VALOR,
    SF1.F1_FORNECE  AS FORNEC_CLIEN_CODIGO,
    SF1.F1_LOJA     AS FORNEC_CLIEN_LOJA,
    COALESCE(SA2.A2_NOME, SA1.A1_NOME)   
                    AS FORNEC_CLIEN_NOME,
    CAST(SF1.F1_EMISSAO AS DATE)
                    AS EMISSAO,
    SF1.F1_TIPO     AS TIPO,
    SF1.F1_VALBRUT  AS VALOR_BRUTO,
    SF1.F1_ESPECIE  AS ESPEC_CODIGO,
    SX521.X5_DESCRI AS ESPEC_DESC
FROM SF1010 SF1
    INNER JOIN SD1010 SD1 ON SD1.D_E_L_E_T_ <> '*'
        AND SF1.F1_DOC      = SD1.D1_DOC
        AND SF1.F1_SERIE    = SD1.D1_SERIE
    LEFT JOIN SA2010 SA2 ON SA2.D_E_L_E_T_ <> '*'
        AND SF1.F1_FORNECE  = SA2.A2_COD
        AND SF1.F1_LOJA     = SA2.A2_LOJA
    LEFT JOIN SA1010 SA1 ON SA1.D_E_L_E_T_ <> '*'
        AND SF1.F1_FORNECE  = SA1.A1_COD
        AND SF1.F1_LOJA     = SA1.A1_LOJA
    LEFT JOIN SX5010 SX521 ON SX521.D_E_L_E_T_ <> '*'
        AND SX521.X5_TABELA = '21'
        AND SA2.A2_GRPTRIB  = SX521.X5_CHAVE 
    INNER JOIN SB1010 SB1 ON SB1.D_E_L_E_T_ <> '*'
        AND SD1.D1_COD      = SB1.B1_COD
    INNER JOIN SX5010 SX52 ON SX52.D_E_L_E_T_ <> '*'
        AND SX52.X5_TABELA  = '02'
        AND SB1.B1_TIPO     = SX52.X5_CHAVE 
    INNER JOIN SBM010 SBM ON SBM.D_E_L_E_T_ <> '*'
        AND SB1.B1_GRUPO    = SBM.BM_GRUPO
WHERE
    SF1.D_E_L_E_T_ <> '*' 
    "
in
    Fonte;

shared fDocCont = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlfDocCont, CommandTimeout=#duration(69, 10, 39, 0)]),
    #"Tipo Alterado" = Table.TransformColumnTypes(Fonte,{{"EMISSAO", type date}})
in
    #"Tipo Alterado";

shared sqlfConfLanc = let
    Fonte = "#(cr)#(lf)SELECT #(cr)#(lf)   E2_FILIAL   AS ""Filial"", #(cr)#(lf)    E2_PREFIXO  AS ""Prefixo"", #(cr)#(lf)    E2_NUM      AS ""No. Titulo"", #(cr)#(lf)    E2_PARCELA  AS ""Parcela"",#(cr)#(lf)    E2_TIPO     AS ""Tipo"", #(cr)#(lf)    ED_DESCRIC  AS ""Natureza"", #(cr)#(lf)    E2_FORNECE  AS ""Fornecedor"", #(cr)#(lf)    E2_LOJA     AS ""Loja"", #(cr)#(lf)    SA2.A2_NOME AS ""Nome Fornecedor"",#(cr)#(lf)    CAST(E2_EMISSAO AS DATE) #(cr)#(lf)                AS ""DT Emissao"", #(cr)#(lf)    E2_VALOR AS ""Vlr.Titulo"", #(cr)#(lf)    CAST(E2_EMIS1 AS DATE) #(cr)#(lf)                AS ""DT Contab."",#(cr)#(lf)    CASE WHEN SUBSTRING(E2_USERLGI, 03, 1) != ' ' AND E2_USERLGI != '' THEN#(cr)#(lf)        CONVERT(VARCHAR,DATEADD(DAY,CONVERT(INT,CONCAT(ASCII(SUBSTRING(E2_USERLGI,12,1)) - 50, ASCII(SUBSTRING(E2_USERLGI,16,1)) - 50) + IIF(SUBSTRING(E2_USERLGI,08,1) = '<',10000,0)),'1996-01-01'), 103)#(cr)#(lf)        ELSE '' END#(cr)#(lf)                AS ""Data Alt."",#(cr)#(lf)    USR_LGI.USR_NOME AS ""Usuario Incl."",#(cr)#(lf)    CASE WHEN SUBSTRING(E2_USERLGA, 03, 1) != ' ' AND E2_USERLGA != '' THEN#(cr)#(lf)        CONVERT(VARCHAR,DATEADD(DAY,CONVERT(INT,CONCAT(ASCII(SUBSTRING(E2_USERLGA,12,1)) - 50, ASCII(SUBSTRING(E2_USERLGA,16,1)) - 50) + IIF(SUBSTRING(E2_USERLGA,08,1) = '<',10000,0)),'1996-01-01'), 103)#(cr)#(lf)        ELSE '' END #(cr)#(lf)                AS ""Data Alt."",#(cr)#(lf)    USR_LGA.USR_NOME AS ""Usuario Alt.""#(cr)#(lf)FROM SE2010#(cr)#(lf)    LEFT JOIN SED010 SED ON SED.D_E_L_E_T_ = ''#(cr)#(lf)        AND SE2010.E2_NATUREZ = SED.ED_CODIGO#(cr)#(lf)    LEFT JOIN SA2010 SA2 ON SA2.D_E_L_E_T_ = ''#(cr)#(lf)        AND SE2010.E2_FORNECE = SA2.A2_COD#(cr)#(lf)        AND SE2010.E2_LOJA = SA2.A2_LOJA#(cr)#(lf)    LEFT JOIN SYS_USR USR_LGA ON#(cr)#(lf)        USR_LGA.D_E_L_E_T_ = ''#(cr)#(lf)        AND #(cr)#(lf)            LEFT(SUBSTRING(E2_USERLGA, 11, 1) + SUBSTRING(E2_USERLGA, 15, 1) + SUBSTRING(E2_USERLGA, 19, 1) + SUBSTRING(E2_USERLGA, 02, 1) + SUBSTRING(E2_USERLGA, 06, 1) + SUBSTRING(E2_USERLGA, 10, 1) + SUBSTRING(E2_USERLGA, 14, 1) + SUBSTRING(E2_USERLGA, 01, 1) + SUBSTRING(E2_USERLGA, 18, 1) + SUBSTRING(E2_USERLGA, 05, 1) + SUBSTRING(E2_USERLGA, 09, 1) + SUBSTRING(E2_USERLGA, 13, 1) + SUBSTRING(E2_USERLGA, 17, 1) + SUBSTRING(E2_USERLGA, 04, 1) + SUBSTRING(E2_USERLGA, 08, 1), 6) = USR_LGA.USR_ID#(cr)#(lf)    LEFT JOIN SYS_USR USR_LGI ON#(cr)#(lf)        USR_LGI.D_E_L_E_T_ = ''#(cr)#(lf)        AND LEFT(SUBSTRING(E2_USERLGI, 11, 1) + SUBSTRING(E2_USERLGI, 15, 1) + SUBSTRING(E2_USERLGI, 19, 1) + SUBSTRING(E2_USERLGI, 02, 1) + SUBSTRING(E2_USERLGI, 06, 1) + SUBSTRING(E2_USERLGI, 10, 1) + SUBSTRING(E2_USERLGI, 14, 1) + SUBSTRING(E2_USERLGI, 01, 1) + SUBSTRING(E2_USERLGI, 18, 1) + SUBSTRING(E2_USERLGI, 05, 1) + SUBSTRING(E2_USERLGI, 09, 1) + SUBSTRING(E2_USERLGI, 13, 1) + SUBSTRING(E2_USERLGI, 17, 1) + SUBSTRING(E2_USERLGI, 04, 1) + SUBSTRING(E2_USERLGI, 08, 1), 6) = USR_LGI.USR_ID#(cr)#(lf)    WHERE SE2010.D_E_L_E_T_ = ''#(cr)#(lf)    "
in
    Fonte;

shared fConfLanc = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlfConfLanc, CommandTimeout=#duration(69, 10, 39, 0)]),
    #"Tipo Alterado" = Table.TransformColumnTypes(Fonte,{{"DT Emissao", type date}, {"DT Contab.", type date}, {"Data Alt.2", type date}})
in
    #"Tipo Alterado";

shared sqlfSDS = let
    Fonte = "
SELECT
    *
FROM SDS010
    "
in
    Fonte;

shared fSDS = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlfSDS, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlfSaidas = let
    Fonte = "
SELECT
    SF2.F2_FILIAL   AS ""Filial"",
    SF2.F2_TIPO     AS ""Tipo"",
    SF2.F2_ESPECIE  AS ""Especie"",
    SF2.F2_DOC      AS ""Doc"",
    SF2.F2_SERIE    AS ""Serie"",
    SF2.F2_CLIENTE  AS ""Cliente"",
    SF2.F2_LOJA     AS ""Loja"",
    SA1.A1_CGC      AS ""CNPJ/CPF"",
    SA1.A1_NOME     AS ""Razao Social"",
    CAST(SF2.F2_EMISSAO AS DATE) 
                    AS ""Dt_Emissao"",
    SF2.F2_VALBRUT  AS ""Vlr_Bruto"",
    SF2.F2_BASEICM  AS ""Base_ICMS"",
    SF2.F2_VALICM   AS ""Vlr_ICMS"",
    SF2.F2_ICMSRET  AS ""ICMS_Ret"",
SF2.F2_CHVNFE       AS ""Chave_Nfe""
FROM SF2010 SF2
LEFT JOIN SA1010 SA1 ON SA1.D_E_L_E_T_ = ''
    AND SA1.A1_COD  = SF2.F2_CLIENTE
    AND SA1.A1_LOJA = SF2.F2_LOJA
WHERE SF2.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared fSaidas = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlfSaidas, CommandTimeout=#duration(69, 10, 39, 0)]),
    #"Tipo Alterado" = Table.TransformColumnTypes(Fonte,{{"Dt_Emissao", type date}})
in
    #"Tipo Alterado";

shared sqlImpostosEntradas = let
    Fonte = "
SELECT
    SD1.D1_FILIAL   AS ""Filial"",
    SD1.D1_TIPO     AS ""Tipo Mov."",
    CAST(SD1.D1_DTDIGIT AS DATE) AS ""Dt Entrada"",
    CAST(SD1.D1_EMISSAO AS DATE) AS ""Dt Emissao"",
    SD1.D1_DOC      AS ""Num Doc"",
    SD1.D1_SERIE    AS ""Serie"",
    COALESCE (SA2.A2_NOME, SA1.A1_NOME)     AS ""Nome Fornecedor"",
    SD1.D1_CF       AS ""CFOP"",
    SD1.D1_TES      AS ""TES"",
    SD1.D1_PEDIDO   AS ""Pedido"",
    SD1.D1_COD      AS ""Cod Produto"",
    SB1.B1_DESC     AS ""Produto"",
    SD1.D1_IDTRIB   AS ""ID Trib"",
    F2B.F2B_TRIB    AS ""Tributo"",
    F2D.F2D_TRIB    AS ""Cod Trib"",
    F2B.F2B_DESC    AS ""Descricao"",
    F2D.F2D_BASE    AS ""Base Trib"",
    F2D.F2D_ALIQ    AS ""Aliq Trib"",
    F2D.F2D_VALOR   AS ""Vlr Trib""
FROM SD1010 SD1
LEFT JOIN F2D010 F2D ON F2D.D_E_L_E_T_ = '' AND SD1.D1_IDTRIB = F2D.F2D_IDREL
LEFT JOIN F2B010 F2B ON F2B.D_E_L_E_T_ = '' AND F2B.F2B_ID = F2D.F2D_IDCAD
LEFT JOIN SA2010 SA2 ON SA2.D_E_L_E_T_ = '' AND SD1.D1_FORNECE = SA2.A2_COD AND SD1.D1_LOJA = SA2.A2_LOJA
LEFT JOIN SA1010 SA1 ON SA1.D_E_L_E_T_ = '' AND SD1.D1_FORNECE = SA1.A1_COD AND SD1.D1_LOJA = SA1.A1_LOJA
LEFT JOIN SB1010 SB1 ON SB1.D_E_L_E_T_ = '' AND SB1.B1_COD = SD1.D1_COD
WHERE SD1.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared fImpostosEntradas = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlImpostosEntradas, CommandTimeout=#duration(69, 10, 39, 0)]),
    #"Tipo Alterado" = Table.TransformColumnTypes(Fonte,{{"Dt Entrada", type date}, {"Dt Emissao", type date}})
in
    #"Tipo Alterado";

shared sqlImpostosSaidas = let
    Fonte = "
SELECT
    SD2.D2_FILIAL   AS ""Filial"",
    SD2.D2_TIPO     AS ""Tipo Mov."",
    CAST(SD2.D2_EMISSAO AS DATE) AS ""Dt Emissao"",
    SD2.D2_DOC      AS ""Num Doc"",
    SD2.D2_SERIE    AS ""Serie"",
    COALESCE (SA2.A2_NOME, SA1.A1_NOME)     AS ""Nome Cliente"",
    SD2.D2_CF       AS ""CFOP"",
    SD2.D2_COD      AS ""Cod Produto"",
    SB1.B1_DESC     AS ""Produto"",
    SD2.D2_IDTRIB   AS ""ID Trib"",
    F2B.F2B_TRIB    AS ""Tributo"",
    F2D.F2D_TRIB    AS ""Cod Trib"",
    F2B.F2B_DESC    AS ""Descricao"",
    F2D.F2D_BASE    AS ""Base Trib"",
    F2D.F2D_ALIQ    AS ""Aliq Trib"",
    F2D.F2D_VALOR   AS ""Vlr Trib""
FROM SD2010 SD2
LEFT JOIN F2D010 F2D ON F2D.D_E_L_E_T_ = '' AND SD2.D2_IDTRIB = F2D.F2D_IDREL
LEFT JOIN F2B010 F2B ON F2B.D_E_L_E_T_ = '' AND F2B.F2B_ID = F2D.F2D_IDCAD
LEFT JOIN SA2010 SA2 ON SA2.D_E_L_E_T_ = '' AND SD2.D2_CLIENTE = SA2.A2_COD AND SD2.D2_LOJA = SA2.A2_LOJA
LEFT JOIN SA1010 SA1 ON SA1.D_E_L_E_T_ = '' AND SD2.D2_CLIENTE = SA1.A1_COD AND SD2.D2_LOJA = SA1.A1_LOJA
LEFT JOIN SB1010 SB1 ON SB1.D_E_L_E_T_ = '' AND SB1.B1_COD = SD2.D2_COD
WHERE SD2.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared fImpostosSaidas = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlImpostosSaidas, CommandTimeout=#duration(69, 10, 39, 0)]),
    #"Tipo Alterado" = Table.TransformColumnTypes(Fonte,{{"Dt Emissao", type date}})
in
    #"Tipo Alterado";

shared sqlSFT = let
    Fonte = "
SELECT
    SFT.FT_FILIAL   AS ""Filial"",
    SFT.FT_TIPOMOV  AS ""Tipo Mov."",
    SFT.FT_TIPO     AS ""Tipo Lanc"",
    CAST(SFT.FT_ENTRADA AS DATE) AS ""Dt Entrada"",
    CAST(SFT.FT_EMISSAO AS DATE) AS ""Dt Emissao"",
    SFT.FT_ESPECIE  AS ""Especie"",
    SFT.FT_NFISCAL  AS ""Doc. Fiscal"",
    SFT.FT_SERIE    AS ""Serie NF"",
    SX521.X5_DESCRI AS ESPEC_DESC,
    COALESCE(SA2.A2_NOME, SA1.A1_NOME) AS ""Razao Social"",
    SFT.FT_CFOP     AS ""Cod. Fiscal"",
    SFT.FT_CODISS   AS ""Cod. Servico"",
    SFT.FT_PRODUTO  AS ""Cod. Produto"",
    SX52.X5_DESCRI  AS TIPO_DESC,
    SBM.BM_DESC     AS DESCRICAO,
    SB1.B1_DESC     AS ""Produto"",
    SFT.FT_POSIPI   AS ""Cod. NCM"",
    SFT.FT_VALCONT  AS ""Vlr Contabil"",
    SFT.FT_TOTAL    AS ""Vlr Total"",
    SFT.FT_CLASFIS  AS ""Sit.Trib.ICMS"",
    SFT.FT_ALIQICM  AS ""Aliq. ICMS"",
    SFT.FT_BASEICM  AS ""Base ICMS"",
    SFT.FT_VALICM   AS ""Vlr ICMS"",
    SFT.FT_ISENICM  AS ""Vlr Isento ICMS"",
    SFT.FT_OUTRICM  AS ""Vlr Outro ICMS"",
    SFT.FT_CTIPI    AS ""Sit.Trib.IPI"",
    SFT.FT_BASEIPI  AS ""Vlr Base IPI"",
    SFT.FT_ALIQIPI  AS ""Aliq IPI"",
    SFT.FT_VALIPI   AS ""Vlr IPI"",
    SFT.FT_ISENIPI  AS ""Vlr Isento IPI"",
    SFT.FT_OUTRIPI  AS ""Vlr Outro IPI"",
    SFT.FT_BASERET  AS ""Vlr Base ICMS ST"",
    SFT.FT_ALIQSOL  AS ""Aliq ICMS ST"",
    SFT.FT_ICMSRET  AS ""Vlr ICMS ST"",
    SFT.FT_ICMSDIF  AS ""Vlr ICMS Diferido"",
    SFT.FT_CSTPIS   AS ""CST Pis"",
    SFT.FT_BASEPIS  AS ""Base PIS"",
    SFT.FT_ALIQPIS  AS ""Aliq. PIS"",
    SFT.FT_VALPIS   AS ""Vlr PIS"",
    SFT.FT_CSTCOF   AS ""CST COF"",
    SFT.FT_BASECOF  AS ""Base COFINS"",
    SFT.FT_ALIQCOF  AS ""Aliq. COFINS"",
    SFT.FT_VALCOF   AS ""Vlr COFINS"",
    SFT.FT_BASEIRR  AS ""Base IRRF"",
    SFT.FT_ALIQIRR  AS ""Aliq. IRRF"",
    SFT.FT_VALIRR   AS ""Vlr IRRF"",
    SFT.FT_BASEINS  AS ""Base INSS"",
    SFT.FT_ALIQINS  AS ""Aliq. INSS"",
    SFT.FT_VALINS   AS ""Vlr INSS"",
    SFT.FT_BRETPIS  AS ""Base Pis"",
    SFT.FT_ARETPIS  AS ""Aliq. PIS"",
    SFT.FT_VRETPIS  AS ""Vlr Pis"",
    SFT.FT_BRETCOF  AS ""Base Cofins"",
    SFT.FT_ARETCOF  AS ""Aliq. Cofins"",
    SFT.FT_VRETCOF  AS ""Vlr Cofins"",
    SFT.FT_BRETCSL  AS ""Base CSLL"",
    SFT.FT_ARETCSL  AS ""Aliq. CSLL"",
    SFT.FT_VRETCSL  AS ""Vlr CSLL"",
    SD1.D1_BASEISS  AS ""Base de ISS"",
    SD1.D1_ALIQISS  AS ""Aliq. ISS"",
    SD1.D1_VALISS   AS ""Vlr ISS""
FROM SFT010 SFT
LEFT JOIN SA2010 SA2 ON SA2.D_E_L_E_T_ = '' 
    AND SFT.FT_CLIEFOR = SA2.A2_COD 
    AND SFT.FT_LOJA = SA2.A2_LOJA
LEFT JOIN SA1010 SA1 ON SA1.D_E_L_E_T_ = '' 
    AND SFT.FT_CLIEFOR = SA1.A1_COD 
    AND SFT.FT_LOJA = SA1.A1_LOJA
LEFT JOIN SD1010 SD1 ON SD1.D_E_L_E_T_ = '' 
    AND SFT.FT_NFISCAL = SD1.D1_DOC 
    AND SFT.FT_SERIE = SD1.D1_SERIE 
    AND SFT.FT_CLIEFOR = SD1.D1_FORNECE 
    AND SFT.FT_LOJA = SD1.D1_LOJA
LEFT JOIN SB1010 SB1 ON SB1.D_E_L_E_T_ = '' 
    AND SB1.B1_COD = SFT.FT_PRODUTO
LEFT JOIN SX5010 SX521 ON SX521.D_E_L_E_T_ = '' 
    AND SX521.X5_TABELA = '21' 
    AND SA2.A2_GRPTRIB = SX521.X5_CHAVE 
INNER JOIN SX5010 SX52 ON SX52.D_E_L_E_T_ = '' 
    AND SX52.X5_TABELA = '02' 
    AND SB1.B1_TIPO = SX52.X5_CHAVE 
INNER JOIN SBM010 SBM ON SBM.D_E_L_E_T_ = '' 
    AND SB1.B1_GRUPO = SBM.BM_GRUPO
WHERE SFT.D_E_L_E_T_ = ''
"
in
    Fonte;

shared fSFT = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlSFT, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlSDT = let
    Fonte = "
SELECT 
    SDT.DT_FILIAL AS ""Filial"",
    SDT.DT_ITEM AS ""Item"",
    SDT.DT_COD AS ""COD"",
    SB1.B1_DESC AS ""Produto"",
    SDT.DT_PRODFOR AS ""Prd. For/Cli"",
    SDT.DT_DESCFOR AS ""Desc For/Cli"",
    SDT.DT_FORNEC AS ""Forn/Cliente"",
    SDT.DT_LOJA AS ""Loja"",
    COALESCE(SA2.A2_NOME, SA1.A1_NOME) AS ""Nome Fornecedor"",
    SDT.DT_DOC AS ""Documento"",
    SDT.DT_SERIE AS ""Serie"",
    SDT.DT_QUANT AS ""Quantidade"",
    SDT.DT_VUNIT AS ""Vlr.Unitario"",
    SDT.DT_TOTAL AS ""Vlr.Total"",
    SDT.DT_VALFRE AS ""Vlr.Frete"",
    SDT.DT_DESPESA AS ""Vlr.Despesas"",
    SDT.DT_VALDESC AS ""Desconto"",
    SDT.DT_XBASICM AS ""Base ICM XML"",
    SDT.DT_XMLICM AS ""Vlr. ICMS XML"",
    SDT.DT_XBICST AS ""B.ICM ST XML"",
    SDT.DT_XMLICST AS ""ICMS ST XML"",
    SDT.DT_XBASPIS AS ""Base PIS XML"",
    SDT.DT_XMLPIS AS ""Vlr. PIS XML"",
    SDT.DT_XBASCOF AS ""B.COFINS XML"",
    SDT.DT_XMLCOF AS ""Vlr. COF XML"",
    SDT.DT_XBASIPI AS ""Base IPI XML"",
    SDT.DT_XMLIPI AS ""Vlr. IPI XML""
FROM SDT010 SDT
LEFT JOIN SA2010 SA2 ON SA2.D_E_L_E_T_ = '' AND SDT.DT_FORNEC = SA2.A2_COD AND SDT.DT_LOJA = SA2.A2_LOJA
LEFT JOIN SA1010 SA1 ON SA1.D_E_L_E_T_ = '' AND SDT.DT_FORNEC = SA1.A1_COD AND SDT.DT_LOJA = SA1.A1_LOJA
LEFT JOIN SB1010 SB1 ON SB1.D_E_L_E_T_ = '' AND SB1.B1_COD = SDT.DT_COD
WHERE SDT.D_E_L_E_T_ = ''
"
in
    Fonte;

shared fSDT = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlSDT, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlConferenciaNFE = let
    Fonte = "
SELECT
    SD1.D1_FILIAL                        AS Filial,
    SF1.F1_EMISSAO                       AS Emissao,
    SD1.D1_DOC                           AS Documento,
    SD1.D1_SERIE                         AS Serie,       
    SD1.D1_FORNECE                       AS Fornecedor,
    SD1.D1_LOJA                          AS Loja,
    COALESCE(SA2.A2_NOME, SA1.A1_NOME)   AS NomeFornecedor,

    F2B.F2B_TRIB                         AS Tributo,        
    F2D.F2D_TRIB                         AS CodTrib,
    F2B.F2B_DESC                         AS DescricaoTributo,

    --- TOTAL PROTHEUS POR TRIBUTO ---
    SUM(F2D.F2D_BASE)                    AS Base_Protheus,
    SUM(F2D.F2D_VALOR)                   AS Valor_Protheus,

    --- TOTAL XML CORRESPONDENTE AO TRIBUTO ---
    CASE 
        WHEN F2B.F2B_TRIB = 'ICMS'   THEN XML.XML_ICMS
        WHEN F2B.F2B_TRIB = 'ICMSST' THEN XML.XML_ICMSST
        WHEN F2B.F2B_TRIB = 'PIS'    THEN XML.XML_PIS
        WHEN F2B.F2B_TRIB = 'COF'    THEN XML.XML_COF
        WHEN F2B.F2B_TRIB = 'IPI'    THEN XML.XML_IPI
    END AS Valor_XML,

    --- DIFERENÇA ENTRE PROTHEUS E XML ---
    SUM(F2D.F2D_VALOR) -
    CASE 
        WHEN F2B.F2B_TRIB = 'ICMS'   THEN XML.XML_ICMS
        WHEN F2B.F2B_TRIB = 'ICMSST' THEN XML.XML_ICMSST
        WHEN F2B.F2B_TRIB = 'PIS'    THEN XML.XML_PIS
        WHEN F2B.F2B_TRIB = 'COF'    THEN XML.XML_COF
        WHEN F2B.F2B_TRIB = 'IPI'    THEN XML.XML_IPI
    END AS Dif_Protheus_XML,

    --- STATUS COM TOLERÂNCIA ±2,00 ---
    CASE
        WHEN 
            ABS(
                SUM(F2D.F2D_VALOR) -
                CASE 
                    WHEN F2B.F2B_TRIB = 'ICMS'   THEN XML.XML_ICMS
                    WHEN F2B.F2B_TRIB = 'ICMSST' THEN XML.XML_ICMSST
                    WHEN F2B.F2B_TRIB = 'PIS'    THEN XML.XML_PIS
                    WHEN F2B.F2B_TRIB = 'COF'    THEN XML.XML_COF
                    WHEN F2B.F2B_TRIB = 'IPI'    THEN XML.XML_IPI
                END
            ) <= 2
        THEN 'OK'
        ELSE 'DIVERGENTE'
    END AS Status_Conciliacao

FROM SD1010 SD1

--- TABELA DE APURAÇÃO TRIBUTÁRIA
LEFT JOIN F2D010 F2D 
    ON F2D.D_E_L_E_T_ = '' 
    AND SD1.D1_IDTRIB = F2D.F2D_IDREL

LEFT JOIN F2B010 F2B 
    ON F2B.D_E_L_E_T_ = '' 
    AND F2B.F2B_ID = F2D.F2D_IDCAD

--- CADASTRO DE FORNECEDOR
LEFT JOIN SA2010 SA2 
    ON SA2.D_E_L_E_T_ = '' 
    AND SD1.D1_FORNECE = SA2.A2_COD 
    AND SD1.D1_LOJA = SA2.A2_LOJA

LEFT JOIN SA1010 SA1 
    ON SA1.D_E_L_E_T_ = '' 
    AND SD1.D1_FORNECE = SA1.A1_COD 
    AND SD1.D1_LOJA = SA1.A1_LOJA

--- PRODUTO
LEFT JOIN SB1010 SB1 
    ON SB1.D_E_L_E_T_ = '' 
    AND SB1.B1_COD = SD1.D1_COD

--- ==========================================================================================
--- XML AGREGADO POR NOTA (CORREÇÃO FUNDAMENTAL)
--- ==========================================================================================
LEFT JOIN (
    SELECT 
        DT_FILIAL,
        DT_DOC,
        DT_SERIE,
        DT_FORNEC,
        DT_LOJA,
        SUM(DT_XMLICM)  AS XML_ICMS,
        SUM(DT_XMLICST) AS XML_ICMSST,
        SUM(DT_XMLPIS)  AS XML_PIS,
        SUM(DT_XMLCOF)  AS XML_COF,
        SUM(DT_XMLIPI)  AS XML_IPI
    FROM SDT010
    WHERE D_E_L_E_T_ = ''
    GROUP BY DT_FILIAL, DT_DOC, DT_SERIE, DT_FORNEC, DT_LOJA
) XML
    ON XML.DT_FILIAL = SD1.D1_FILIAL
   AND XML.DT_DOC    = SD1.D1_DOC
   AND XML.DT_SERIE  = SD1.D1_SERIE
   AND XML.DT_FORNEC = SD1.D1_FORNECE
   AND XML.DT_LOJA   = SD1.D1_LOJA

--- CABEÇALHO SF1
LEFT JOIN SF1010 SF1
    ON SF1.D_E_L_E_T_ = ''
    AND SF1.F1_FILIAL = SD1.D1_FILIAL
    AND SF1.F1_DOC    = SD1.D1_DOC
    AND SF1.F1_SERIE  = SD1.D1_SERIE
    AND SF1.F1_FORNECE= SD1.D1_FORNECE
    AND SF1.F1_LOJA   = SD1.D1_LOJA

WHERE SD1.D_E_L_E_T_ = ''
  AND SF1.F1_ESPECIE = 'SPED'
  AND SF1.F1_FORMUL <> 'S'

GROUP BY 
    SD1.D1_FILIAL,
    SD1.D1_DOC,
    SD1.D1_SERIE,
    SF1.F1_EMISSAO,
    SD1.D1_FORNECE,
    SD1.D1_LOJA,
    COALESCE(SA2.A2_NOME, SA1.A1_NOME),
    F2B.F2B_TRIB,
    F2D.F2D_TRIB,
    F2B.F2B_DESC,
    XML.XML_ICMS,
    XML.XML_ICMSST,
    XML.XML_PIS,
    XML.XML_COF,
    XML.XML_IPI
"
in
    Fonte;

shared fConferenciaNFE = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlConferenciaNFE, CommandTimeout=#duration(69, 10, 39, 0)]),
    #"Tipo Alterado" = Table.TransformColumnTypes(Fonte,{{"Emissao", type date}})
in
    #"Tipo Alterado";

shared sqlNotasServico = let
    Fonte = "
SELECT
SF1.F1_FILIAL AS ""FILIAL"",
SF1.F1_EMISSAO AS ""EMISSAO"",
SF1.F1_ESPECIE AS ""ESPECIE"", 
SF1.F1_DOC AS ""DOCUMENTO"", 
SF1.F1_SERIE AS ""SERIE"", 
SA2.A2_NOME AS ""FORNECEDOR"",
SF1.F1_VALBRUT AS ""VLR DOC"",
SF1.F1_IRRF AS ""VLR IR"", 
SF1.F1_INSS AS ""VLR INSS"", 
SF1.F1_VALPIS AS ""VLR PIS"", 
SF1.F1_VALCOFI AS ""VLR COFINS"",
SF1.F1_VALCSLL AS ""VLR CSLL"",
SF1.F1_ISS AS ""VLR ISS""
FROM SF1010 SF1
LEFT JOIN SA2010 SA2 
     ON SA2.D_E_L_E_T_ = '' 
    AND SF1.F1_FORNECE = SA2.A2_COD 
    AND SF1.F1_LOJA = SA2.A2_LOJA
WHERE SF1.D_E_L_E_T_ = ''
  AND SF1.F1_ESPECIE = 'NFS'
",
    Consulta = Fonte
in
    Consulta;

shared fNotasServico = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlNotasServico, CommandTimeout=#duration(69, 10, 39, 0)]),
    #"Tipo Alterado" = Table.TransformColumnTypes(Fonte,{{"EMISSAO", type date}})
in
    #"Tipo Alterado";

shared sqlSemClassificar = let
    Fonte = "

SELECT
    SF1.F1_FILIAL   AS FILIAL,
    SF1.F1_DOC      AS NF,
    SF1.F1_SERIE    AS SERIE,
    SD1.D1_ITEM     AS ITEM,
    SD1.D1_COD      AS CODIGO,
    SB1.B1_DESC     AS DESCRICAO,
    SX52.X5_DESCRI  AS TIPO_DESC,
    SBM.BM_DESC     AS DESCRICAO,
    SD1.D1_TOTAL    AS VALOR,
    SF1.F1_FORNECE  AS FORNEC_CLIEN_CODIGO,
    SF1.F1_LOJA     AS FORNEC_CLIEN_LOJA,
    COALESCE(SA2.A2_NOME, SA1.A1_NOME) 
                    AS FORNEC_CLIEN_NOME,
    CAST(SF1.F1_EMISSAO AS DATE)
                    AS EMISSAO,
    SF1.F1_TIPO     AS TIPO,
    SF1.F1_VALBRUT  AS VALOR_BRUTO,
    SF1.F1_ESPECIE  AS ESPEC_CODIGO,
    SX521.X5_DESCRI AS ESPEC_DESC
FROM SF1010 SF1
    INNER JOIN SD1010 SD1 ON SD1.D_E_L_E_T_ = '' 
        AND SF1.F1_DOC      = SD1.D1_DOC 
        AND SF1.F1_SERIE    = SD1.D1_SERIE 
        AND SF1.F1_FORNECE  = SD1.D1_FORNECE 
        AND SF1.F1_LOJA     = SD1.D1_LOJA
    LEFT JOIN SA2010 SA2 ON SA2.D_E_L_E_T_ = '' 
        AND SF1.F1_FORNECE  = SA2.A2_COD 
        AND SF1.F1_LOJA     = SA2.A2_LOJA
    LEFT JOIN SA1010 SA1 ON SA1.D_E_L_E_T_ = '' 
        AND SF1.F1_FORNECE  = SA1.A1_COD 
        AND SF1.F1_LOJA     = SA1.A1_LOJA
    LEFT JOIN SX5010 SX521 ON SX521.D_E_L_E_T_ = '' 
        AND SX521.X5_TABELA = '21' 
        AND SA2.A2_GRPTRIB  = SX521.X5_CHAVE 
    INNER JOIN SB1010 SB1 ON SB1.D_E_L_E_T_ = '' 
        AND SD1.D1_COD      = SB1.B1_COD
    INNER JOIN SX5010 SX52 ON SX52.D_E_L_E_T_ = '' 
        AND SX52.X5_TABELA  = '02' 
        AND SB1.B1_TIPO     = SX52.X5_CHAVE 
    INNER JOIN SBM010 SBM ON SBM.D_E_L_E_T_ = '' 
        AND SB1.B1_GRUPO    = SBM.BM_GRUPO
WHERE SF1.D_E_L_E_T_ = ''
    AND SF1.F1_STATUS = ''
",
    Consulta = Fonte
in
    Consulta;

shared fSemClassificar = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlSemClassificar, CommandTimeout=#duration(69, 10, 39, 0)]),
    #"Tipo Alterado" = Table.TransformColumnTypes(Fonte,{{"EMISSAO", type date}})
in
    #"Tipo Alterado";

shared sqlPedidos = let
    Fonte = "
SELECT
SC7.C7_FILIAL AS ""Filial"",
SC7.C7_NUM AS ""Numero PC"",
SCR.CR_STATUS AS ""Cont. Aprov."",
CAST(SCR.CR_EMISSAO AS DATE) AS ""Data Emissão"",
SC7.C7_PRODUTO AS ""Produto"",
SC7.C7_DESCRI AS ""Descricao"",
SC7.C7_QUANT AS ""Quantidade"",
SC7.C7_TOTAL AS ""Vlr.Total"",
SA2.A2_NOME	AS ""Fornecedor"",
CTT.CTT_DESC01 AS ""Centro Custo"",
SC7.C7_QUJE AS ""Qtd.Entregue"",
SC7.C7_QTDACLA AS ""Qtd.a Classi"",
SAK.AK_NOME AS ""Nome Aprovador"",
CAST(SCR.CR_DATALIB AS DATE) AS ""Data Liber."",
SC7.C7_ENCER AS ""Ped. Encerr."",
SC7.C7_X_NAT AS ""Cod Natureza"",
SC7.C7_X_NATUR AS ""Desc Natureza""
FROM SC7010 SC7
LEFT JOIN SCR010 SCR ON SCR.D_E_L_E_T_ = '' AND SCR.CR_NUM = SC7.C7_NUM
LEFT JOIN SAK010 SAK ON SAK.D_E_L_E_T_ = '' AND SAK.AK_USER = SCR.CR_USER
LEFT JOIN SA2010 SA2 ON SA2.D_E_L_E_T_ = '' AND SC7.C7_FORNECE = SA2.A2_COD AND SC7.C7_LOJA = SA2.A2_LOJA
LEFT JOIN CTT010 CTT ON CTT.D_E_L_E_T_ = '' AND CTT.CTT_CUSTO = SC7.C7_CC
WHERE SC7.D_E_L_E_T_ = ''
AND SC7.C7_RESIDUO = ''
AND CAST(SCR.CR_EMISSAO AS DATE) BETWEEN '2025-10-01' AND '2099-12-31'
AND SC7.C7_NUM BETWEEN '003000' AND '999999'
",
    Consulta = Fonte
in
    Consulta;

shared fPedidos = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlPedidos, CommandTimeout=#duration(69, 10, 39, 0)]),
    #"Duplicatas Removidas" = Table.Distinct(Fonte, {"Numero PC"}),
    #"Tipo Alterado" = Table.TransformColumnTypes(#"Duplicatas Removidas",{{"Data Emissão", type date}, {"Data Liber.", type date}}),
    #"Valor Substituído" = Table.ReplaceValue(#"Tipo Alterado","03","APROVADO",Replacer.ReplaceText,{"Cont. Aprov."}),
    #"Valor Substituído1" = Table.ReplaceValue(#"Valor Substituído","02","PENDENTE",Replacer.ReplaceText,{"Cont. Aprov."}),
    #"Linhas Filtradas" = Table.SelectRows(#"Valor Substituído1", each ([#"Cont. Aprov."] <> "05")),
    #"Colunas Renomeadas" = Table.RenameColumns(#"Linhas Filtradas",{{"Numero PC", "NUM PEDIDO"}, {"Cont. Aprov.", "APROVADOR"}})
in
    #"Colunas Renomeadas";