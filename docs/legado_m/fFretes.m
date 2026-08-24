section Section1;

shared sqlTransportadores = let
    Fonte = "
SELECT 
    GU3_CDEMIT  AS CODTRANSP,
    GU3_NMEMIT  AS TRANSPORTADOR,
    GU3_IDFED   AS CNPJ
FROM GU3010 GU3
WHERE GU3.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared dTransportadores = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlTransportadores, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlCteFinanceiro = let
    Fonte = "
SELECT
    SE2.E2_NUM      AS ""Num CT-e"",
    SE2.E2_FORNECE,
    SE2.E2_LOJA,
    SA2.A2_CGC      AS ""CNPJ Emitente"",
    SE2.E2_VALOR,
    SA2.A2_NOME,
    CAST(SE2.E2_EMISSAO AS DATE) 
                    AS EMISSAO,
    CAST(SE2.E2_BAIXA AS DATE) 
                    AS BAIXA,
    CASE 
        WHEN SE2.E2_BAIXA <> '' THEN 'BAIXADO'
        ELSE 'PENDENTE'
    END             AS STATUS_BAIXA
FROM SE2010 SE2
LEFT JOIN SA2010 SA2 ON SA2.D_E_L_E_T_ = ''
    AND SA2.A2_COD  = SE2.E2_FORNECE
    AND SA2.A2_LOJA = SE2.E2_LOJA
WHERE SE2.D_E_L_E_T_ = ''
    AND SE2.E2_FATURA <> 'NOTFAT'
    AND SE2.E2_NATUREZ  IN (
    '0202001','0202002','0202003',
    '0202004','0202005','0202006',
    '0202007','0202008','0202009',
    '0202010','0202011','0403009','0202')
    "
in
    Fonte;

shared fCteFinanceiro = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlCteFinanceiro, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlCteLogistica = let
    Fonte = "
SELECT 
    GW3_NRDF        AS ""Num CT-e"",
    GW3_SERDF       AS ""Série CT-e"",
    GU3.GU3_IDFED   AS ""CNPJ Emitente"",
    GU3.GU3_NMFAN,
    CAST(GW3_DTEMIS AS DATE)
                    AS ""Dt. Emissao"",
    GW3.GW3_VLDF
FROM GW3010 GW3
    LEFT JOIN GU3010 GU3 ON GU3.D_E_L_E_T_ = '' 
        AND GW3.GW3_EMISDF = GU3.GU3_CDEMIT
WHERE GW3.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared fCteLogistica = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlCteLogistica, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlFaturamentoGeral = let
    Fonte = "
SELECT 
    SD2.D2_FILIAL   AS FILIAL,
    SD2.D2_ITEM     AS ITEM,
     CASE 
        WHEN SD2.D2_COD = 'PA01010001-CX' THEN 'PA01010001' 
		WHEN SD2.D2_COD = 'PA01020010-CX' THEN 'PA01020010'
        WHEN SD2.D2_COD = 'PA01020012-CX' THEN 'PA01020012'
        WHEN SD2.D2_COD = 'PA01020021-CX' THEN 'PA01020021'
        WHEN SD2.D2_COD = 'PA01010005-CX' THEN 'PA01010005'
        WHEN SD2.D2_COD = 'PA01010006-CX' THEN 'PA01010006'
        ELSE SD2.D2_COD 
    END             AS CODPROD,
    CASE 
        WHEN SD2.D2_COD = 'PA01010001-CX' THEN SD2.D2_QUANT * 10 
		WHEN SD2.D2_COD = 'PA01020010-CX' THEN SD2.D2_QUANT * 2.016
        WHEN SD2.D2_COD = 'PA01020012-CX' THEN SD2.D2_QUANT * 4
        WHEN SD2.D2_COD = 'PA01020021-CX' THEN SD2.D2_QUANT * 2.016
        WHEN SD2.D2_COD = 'PA01010005-CX' THEN SD2.D2_QUANT * 10
        WHEN SD2.D2_COD = 'PA01010006-CX' THEN SD2.D2_QUANT * 9.6
        ELSE SD2.D2_QUANT 
    END             AS QTD,
    CASE 
        WHEN SD2.D2_COD = 'PA01010001-CX' THEN 'KG' 
		WHEN SD2.D2_COD = 'PA01020010-CX' THEN 'KG'
        WHEN SD2.D2_COD = 'PA01020012-CX' THEN 'KG'
        WHEN SD2.D2_COD = 'PA01020021-CX' THEN 'KG'
        WHEN SD2.D2_COD = 'PA01010005-CX' THEN 'KG'
        WHEN SD2.D2_COD = 'PA01010006-CX' THEN 'KG'
        ELSE SD2.D2_UM 
    END             AS UM,
    CASE 
        WHEN SD2.D2_COD = 'PA01010001-CX' THEN SD2.D2_PRCVEN / 10 
		WHEN SD2.D2_COD = 'PA01020010-CX' THEN SD2.D2_PRCVEN / 2.016
        WHEN SD2.D2_COD = 'PA01020012-CX' THEN SD2.D2_PRCVEN / 4
        WHEN SD2.D2_COD = 'PA01020021-CX' THEN SD2.D2_PRCVEN / 2.016
        WHEN SD2.D2_COD = 'PA01010005-CX' THEN SD2.D2_PRCVEN / 10
        WHEN SD2.D2_COD = 'PA01010006-CX' THEN SD2.D2_PRCVEN / 9.6
        ELSE SD2.D2_PRCVEN 
    END             AS PRCUNIT,
    SD2.D2_TOTAL    AS TOTAL,
    SD2.D2_CF       AS CFOP,
    SD2.D2_CLIENTE  AS CODCLI,
    SD2.D2_LOJA     AS LJCLI,
    SD2.D2_DOC      AS NFE,
	SD2.D2_SERIE    AS _SERIE,
    SD2.D2_CF       AS CFOP,
    CAST(SD2.D2_EMISSAO AS DATE) 
                    AS _DTEMISSAO,
    CASE 
        WHEN SA1.A1_COND IS NULL OR SA1.A1_COND = '' THEN SF2.F2_COND
        ELSE SA1.A1_COND
    END             AS _CONDPGTO,
	SC5.C5_TABELA   AS TABPRECO,
    SF2.F2_DUPL     AS _DUPLICATA,
    SF2.F2_EST      AS _ESTADO,
    SF2.F2_TIPOCLI  AS _TIPOCLI,
    SA1.A1_VEND     AS _CODVEND,
	SA1.A1_VEND1    AS _CONDESPECIAL,
	SF2.F2_TIPO     AS TIPO,
    SC5.C5_X_REFAT  AS NFORIREFATURA
FROM SD2010 SD2
    LEFT JOIN SF2010 SF2 ON SF2.D_E_L_E_T_ = ''
    	AND SD2.D2_FILIAL   = SF2.F2_FILIAL
        AND SD2.D2_DOC      = SF2.F2_DOC
        AND SD2.D2_CLIENTE  = SF2.F2_CLIENTE
        AND SD2.D2_LOJA     = SF2.F2_LOJA
    INNER JOIN SC5010 SC5 ON SC5.D_E_L_E_T_ = ''
    	AND SC5.C5_FILIAL   = SD2.D2_FILIAL
    	AND SC5.C5_NUM      = SD2.D2_PEDIDO
    LEFT JOIN SA1010 SA1 ON SA1.D_E_L_E_T_ = ''
        AND SA1.A1_COD      = SD2.D2_CLIENTE
        AND SA1.A1_LOJA     = SD2.D2_LOJA
    LEFT JOIN SA2010 SA2 ON SA2.D_E_L_E_T_ = ''
        AND SA2.A2_COD      = SD2.D2_CLIENTE
        AND SA2.A2_LOJA     = SD2.D2_LOJA
WHERE 
    SD2.D_E_L_E_T_ = ''
    AND (
        SF2.D_E_L_E_T_ <> '*'
        OR SF2.D_E_L_E_T_ IS NULL) 
	AND SD2.D2_EMISSAO > '20250131'
	AND (
        SD2.D2_FILIAL <> '01004' 
        OR SD2.D2_DOC NOT IN (
        '000012896', '000012898', '000012899', '000012900', '000012901', 
        '000012908', '000012909', '000012910', '000012911', '000012912', 
        '000015334', '000015335', '000015336', '000015455', '000015456', 
        '000015457', '000016294', '000016295', '000016296', '000016298', 
        '000016299', '000016300', '000016320', '000016321', '000016322', 
        '000016323', '000016324'))
	AND (
        SD2.D2_FILIAL <> '03001' 
        OR SD2.D2_DOC NOT IN  (
        '000002073', '000002082'))
	AND SD2.D2_FILIAL IN (
    '01001', '01003', '01004', 
    '01005', '01006', '01007', 
    '01009', '01010', '01011')
    "
in
    Fonte;

shared fFaturamentoGeral = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlFaturamentoGeral, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared #"sqlGW3-GW4" = let
    Fonte = "
SELECT
    *
FROM GW3010 GW3
    LEFT JOIN GW4010 GW4 ON
        GW4.D_E_L_E_T_ = ''
        AND GW3.GW3_FILIAL = GW4.GW4_FILIAL
        AND GW3.GW3_CDESP = GW4.GW4_CDESP
        AND GW3.GW3_EMISDF = GW4.GW4_EMISDF
        AND GW3.GW3_SERDF = GW4.GW4_SERDF
        AND GW3.GW3_NRDF = GW4.GW4_NRDF
        AND GW3.GW3_DTEMIS	= GW4.GW4_DTEMIS
WHERE GW3.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared #"fGW3-GW4" = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=#"sqlGW3-GW4", CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlRateio = let
    Fonte = "
SELECT
    GWM.GWM_FILIAL  AS FILIAL,
    GWM.GWM_TPDOC   AS TIPO,
    GWM.GWM_CDTRP   AS CODTRANSP,
    GWM.GWM_NRDOC   AS CTE,
    GWM.GWM_CDESP   AS ESPECIE,
    CAST(GWM.GWM_DTEMIS AS DATE)   
                    AS DTEMISSAO,
    GWM.GWM_NRDC    AS NFE,
    GWM.GWM_SEQGW8  AS ITEM,
    GWM.GWM_ITEM    AS PRODUTO,
    GWM.GWM_VLFRET  AS VRFRETE,
    GWM.GWM_PCRAT / 100   AS PERCRATEIO
FROM GWM010 GWM
WHERE GWM.D_E_L_E_T_ = ''
	AND GWM.GWM_DTEMIS > '20250201'
    "
in
    Fonte;

shared fRateio = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlRateio, CommandTimeout=#duration(69, 10, 39, 0)]),
    #"Tipo Alterado" = Table.TransformColumnTypes(Fonte,{{"DTEMISSAO", type date}})
in
    #"Tipo Alterado";

shared fRateioDetalhado = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlfRateioDetalhado, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlfRateioDetalhado = let
    Fonte = "
SELECT
    SD2.D2_FILIAL   AS FILIAL,
    SD2.D2_DOC      AS NFE,
    SD2.D2_SERIE    AS _SERIE,
    CAST(SD2.D2_EMISSAO AS DATE) 
                    AS _DTEMISSAO,
    SUBSTRING(GW1.GW1_NRROM, 1, 6)
                    AS ""Numero Romaneio"",
    SB1.B1_DESC     AS DESCRICAO,
    CASE
        WHEN SD2.D2_COD = 'PA01010001-CX' THEN SD2.D2_QUANT * 10
        WHEN SD2.D2_COD = 'PA01020010-CX' THEN SD2.D2_QUANT * 2.016
        WHEN SD2.D2_COD = 'PA01020012-CX' THEN SD2.D2_QUANT * 4
        WHEN SD2.D2_COD = 'PA01020021-CX' THEN SD2.D2_QUANT * 2.016
        WHEN SD2.D2_COD = 'PA01010005-CX' THEN SD2.D2_QUANT * 10
        WHEN SD2.D2_COD = 'PA01010006-CX' THEN SD2.D2_QUANT * 9.6
        ELSE SD2.D2_QUANT
    END             AS QTD,
    CASE
        WHEN SD2.D2_COD = 'PA01010001-CX' THEN 'KG'
        WHEN SD2.D2_COD = 'PA01020010-CX' THEN 'KG'
        WHEN SD2.D2_COD = 'PA01020012-CX' THEN 'KG'
        WHEN SD2.D2_COD = 'PA01020021-CX' THEN 'KG'
        WHEN SD2.D2_COD = 'PA01010005-CX' THEN 'KG'
        WHEN SD2.D2_COD = 'PA01010006-CX' THEN 'KG'
        ELSE SD2.D2_UM
    END             AS UM,
    CASE
        WHEN SD2.D2_COD = 'PA01010001-CX' THEN (SD2.D2_TOTAL + SD2.D2_DESCZFR) / (SD2.D2_QUANT * 10)
        WHEN SD2.D2_COD = 'PA01020010-CX' THEN (SD2.D2_TOTAL + SD2.D2_DESCZFR) / (SD2.D2_QUANT * 2.016)
        WHEN SD2.D2_COD = 'PA01020012-CX' THEN (SD2.D2_TOTAL + SD2.D2_DESCZFR) / (SD2.D2_QUANT * 4)
        WHEN SD2.D2_COD = 'PA01020021-CX' THEN (SD2.D2_TOTAL + SD2.D2_DESCZFR) / (SD2.D2_QUANT * 2.016)
        WHEN SD2.D2_COD = 'PA01010005-CX' THEN (SD2.D2_TOTAL + SD2.D2_DESCZFR) / (SD2.D2_QUANT * 10)
        WHEN SD2.D2_COD = 'PA01010006-CX' THEN (SD2.D2_TOTAL + SD2.D2_DESCZFR) / (SD2.D2_QUANT * 9.6)
        ELSE (SD2.D2_TOTAL + SD2.D2_DESCZFR) / SD2.D2_QUANT
    END             AS PRCUNIT,
    SD2.D2_TOTAL    AS TOTAL,
    SD2.D2_CLIENTE  AS CODCLI,
    SD2.D2_LOJA     AS LJCLI,
    SA1.A1_NOME     AS _NOMECLI,
    SA1.A1_MUN      AS _MUNICIPIO,
    SF2.F2_EST      AS _ESTADO,
    GWM.GWM_NRDOC   AS CTE,
    GWM.GWM_VLFRET  AS VRFRETE,
    ROUND(GWM.GWM_PCRAT / 100, 4)   
                    AS PERCRATEIO,
    SUM(
        GWM.GWM_VLFRET
    ) OVER (
        PARTITION BY GWM.GWM_NRDOC
    )               AS ""Total cte"",
    -- SA3_SUP.A3_NOME AS SUPERVISOR,
    SF4.F4_FINALID  AS ""Finalidade NFe""

FROM SD2010 SD2
    LEFT JOIN SF2010 SF2 ON SF2.D_E_L_E_T_ = ''
        AND SD2.D2_FILIAL  = SF2.F2_FILIAL
        AND SD2.D2_DOC     = SF2.F2_DOC
        AND SD2.D2_CLIENTE = SF2.F2_CLIENTE
        AND SD2.D2_LOJA    = SF2.F2_LOJA
    INNER JOIN SC5010 SC5 ON SC5.D_E_L_E_T_ = ''
        AND SC5.C5_FILIAL  = SD2.D2_FILIAL
        AND SC5.C5_NUM     = SD2.D2_PEDIDO
    INNER JOIN SA1010 SA1 ON SA1.D_E_L_E_T_ = ''
        AND SA1.A1_COD     = SD2.D2_CLIENTE
        AND SA1.A1_LOJA    = SD2.D2_LOJA

    -- LEFT JOIN SA3010 SA3_VEND ON SA3_VEND.D_E_L_E_T_ = ''
    --     AND SA3_VEND.A3_COD     = SA1.A1_VEND
    -- LEFT JOIN SA3010 SA3_SUP ON SA3_SUP.D_E_L_E_T_ = ''
    --     AND SA3_SUP.A3_COD     = SA3_VEND.A3_SUPER
    
    LEFT JOIN GWM010 GWM ON GWM.D_E_L_E_T_ = ''
        AND GWM.GWM_FILIAL = SD2.D2_FILIAL
        AND GWM.GWM_NRDC   = SD2.D2_DOC
        AND GWM.GWM_SEQGW8 = SD2.D2_ITEM

    LEFT JOIN GW1010 GW1 ON GW1.D_E_L_E_T_ = ''
        AND GW1.GW1_FILIAL = GWM.GWM_FILIAL
        AND GW1.GW1_EMISDC = GWM.GWM_EMISDC
        AND GW1.GW1_SERDC  = GWM.GWM_SERDC
        AND GW1.GW1_NRDC   = GWM.GWM_NRDC

    LEFT JOIN SB1010 SB1 ON SB1.D_E_L_E_T_ = ''
        AND SB1.B1_COD     = SD2.D2_COD

    LEFT JOIN SF4010 SF4 ON SF4.D_E_L_E_T_ = ''
        AND SF4.F4_FILIAL = SD2.D2_FILIAL
        AND SF4.F4_CODIGO = SD2.D2_TES
WHERE SD2.D_E_L_E_T_ = ''
    AND GW1_NRROM IS NOT NULL
    AND GWM.GWM_TPDOC = '2'
    AND SD2.D2_FILIAL IN ('01001', '01003', '01004', '01005', '01006', '01007', '01009', '01010', '01011')
    AND (CAST(SD2.D2_EMISSAO AS DATE) > '2025-07-31')
    "
in
    Fonte;

shared __STATUS__ = let
    Fonte = if Table.RowCount(Table.Combine({fRateioDetalhado, dTransportadores, fCteFinanceiro, fCteLogistica, fFaturamentoGeral, #"fGW3-GW4", fRateio})) > 0 then DateTime.LocalNow() else "Pendente"
in
    Fonte;

shared __SQL__ = let
    #"Linhas Filtradas" = Table.SelectRows(Record.ToTable(#shared), each Text.StartsWith([Name], "sql"))
in
    #"Linhas Filtradas";