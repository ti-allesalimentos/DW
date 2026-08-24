section Section1;

shared dePara_Classif = let
    Fonte = Excel.Workbook(File.Contents("\\192.168.67.201\Departamentos$\PUBLICA\T.I\01. BASES\fManual.xlsx"), null, true),
    tabela = Fonte{[Item="dePara_Classif_base",Kind="Table"]}[Data],
    #"Tipo Alterado" = Table.TransformColumnTypes(tabela,{{"de", type text}, {"para", type text}}),
    #"Linhas Filtradas" = Table.SelectRows(#"Tipo Alterado", each ([de] <> "ANTECIPACAO - FIDC")),
    #"Duplicatas Removidas" = Table.Distinct(#"Linhas Filtradas", {"de"}),
    #"Texto Aparado" = Table.TransformColumns(#"Duplicatas Removidas",{{"de", Text.Trim, type text}})
in
    #"Texto Aparado";

shared dGrupoNat = let
    Fonte = Excel.Workbook(File.Contents("\\192.168.67.201\Departamentos$\PUBLICA\T.I\01. BASES\fManual.xlsx"), null, true),
    tabela = Fonte{[Item="dGrupoNat",Kind="Table"]}[Data],
    #"Tipo Alterado" = Table.TransformColumnTypes(tabela,{{"Subgrupo", type text}, {"Descr.Natur.", type text}}),
    #"Duplicatas Removidas" = Table.Distinct(#"Tipo Alterado"),
    #"Texto Aparado" = Table.TransformColumns(#"Duplicatas Removidas",{{"Subgrupo", Text.Trim, type text}, {"Descr.Natur.", Text.Trim, type text}})
in
    #"Texto Aparado";

shared #"dGrupoNat (2)" = let
    #"Outras Colunas Removidas1" = Table.SelectColumns(fContasApagar,{"NATUREZA"}),
    NaturezasUsadas = Table.Distinct(#"Outras Colunas Removidas1"),
    dGrupoNat_ = dGrupoNat,
    #"Consultas Mescladas" = Table.NestedJoin(dGrupoNat_, {"Descr.Natur."}, NaturezasUsadas, {"NATUREZA"}, "FContasApagar", JoinKind.RightAnti),
    #"FContasApagar Expandido" = Table.ExpandTableColumn(#"Consultas Mescladas", "FContasApagar", {"NATUREZA"}, {"NATUREZA"}),
    #"Outras Colunas Removidas" = Table.SelectColumns(#"FContasApagar Expandido",{"NATUREZA"})
in
    #"Outras Colunas Removidas";

shared sqlConsulta = let
    Fonte = "-- Saldo mensal das contas
SELECT 
	   SUMA.GRUPO_EMPRESAS
	  ,SUMA.CQ0_FILIAL AS CODIGO_FILIAL
	  ,TRIM(SUMA.CQ0_CONTA) AS CODIGO_CONTA
	  ,CAST(TRIM(SUMA.CQ0_DATA) AS INT) AS SKDATA
	  ,DEBITO
	  ,CREDITO
	  ,CASE WHEN MOVIMENTO < 0 THEN -(MOVIMENTO) ELSE - MOVIMENTO END AS VALOR_REALIZADO
	  ,SUM((SA.CQ0_DEBITO) - (SA.CQ0_CREDIT)) VALOR_SALDO_INICIAL
	  ,SUM((SA.CQ0_DEBITO) - (SA.CQ0_CREDIT)) - (CASE WHEN MOVIMENTO < 0 THEN -(MOVIMENTO) ELSE - MOVIMENTO END) AS VALOR_SALDO_ATUAL
FROM 	(
			SELECT
				 '01' AS GRUPO_EMPRESAS
				 ,TRIM(CQ0_FILIAL) AS CQ0_FILIAL
				 ,CQ0_CONTA
				 ,CQ0_DATA
				 ,SUM(SUM(CQ0_DEBITO) - SUM(CQ0_CREDIT))
				 		OVER(PARTITION BY CQ0_FILIAL
				 						 ,CQ0_CONTA
				 			 ORDER BY CQ0_FILIAL
				 			 		 ,CQ0_CONTA
				 			 		 ,CQ0_DATA
				 			 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
				 			 )  - (SUM(CQ0_DEBITO) - SUM(CQ0_CREDIT)) AS SALDO_ANTERIOR
				 ,SUM(CQ0_DEBITO) DEBITO
				 ,SUM(CQ0_CREDIT) CREDITO
				 ,SUM(CQ0_DEBITO) - SUM(CQ0_CREDIT) MOVIMENTO 
			     ,SUM(SUM(CQ0_DEBITO) - SUM(CQ0_CREDIT))
			     		OVER(PARTITION BY CQ0_FILIAL
			     						 ,CQ0_CONTA
			     			 ORDER BY CQ0_FILIAL
			     			 		 ,CQ0_CONTA
			     			 		 ,CQ0_DATA
			     			 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS SALDO_ATUAL
			FROM CQ0010
			WHERE D_E_L_E_T_ <> '*'
			AND TRIM(CQ0_LP) = 'N'
			GROUP BY CQ0_FILIAL
					,CQ0_CONTA
					,CQ0_DATA
		) SUMA
	LEFT JOIN  (
				SELECT
					 CQSA.CQ0_DEBITO
					,CQ0_CREDIT
					,CQ0_CONTA
					,CQ0_DATA
					,TRIM(CQSA.CQ0_FILIAL) CQ0_FILIAL
				FROM CQ0010 CQSA  
				WHERE CQSA.D_E_L_E_T_ <> '*'
				AND CQSA.CQ0_LP = 'N'
				) SA ON SA.CQ0_FILIAL = SUMA.CQ0_FILIAL
					 AND SA.CQ0_CONTA = SUMA.CQ0_CONTA
					 AND SA.CQ0_DATA < SUMA.CQ0_DATA
GROUP BY   SUMA.GRUPO_EMPRESAS
		  ,SUMA.CQ0_FILIAL
		  ,SUMA.CQ0_CONTA
		  ,SUMA.CQ0_DATA
		  ,DEBITO
		  ,CREDITO
		  ,MOVIMENTO	

-- PLANO DE CONTAS
SELECT DISTINCT 
		 CT1.CT1_CONTA CODIGO_CONTA
		,CONCAT(LTRIM(RTRIM(CT1.CT1_CONTA)), ' - ', CT1.CT1_DESC01)           AS DESCRICAO_CONTA
FROM [CT1010] AS CT1 (NOLOCK)
WHERE CT1.D_E_L_E_T_ = ''
AND LEN(LTRIM(RTRIM(CT1.CT1_CONTA))) = 8  
ORDER BY 1"
in
    Fonte;

shared Consulta = let
  Origem = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [CommandTimeout = #duration(69, 10, 39, 0), Query =sqlConsulta])
in
  Origem;

shared sqlBancos = let
    Fonte = "
    SELECT
    SA6.A6_COD      AS CODIGO,
    SA6.A6_AGENCIA  AS AGENCIA,
    SA6.A6_NUMCON   AS CONTA,
    SA6.A6_NOME     AS NOME,
    SA6.A6_SALATU   AS SALDO_ATUAL,
    SA6.A6_FILIAL AS FILIAL
FROM SA6010 SA6
WHERE
    SA6.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared dBancos = let
  Origem = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [CommandTimeout = #duration(69, 10, 39, 0), Query =sqlBancos])
in
  Origem;

shared sqlMotivosDeBaixa = let
    Fonte = "#(lf)SELECT#(lf)    F7G.F7G_SIGLA,#(lf)    F7G.F7G_DESCRI#(lf)FROM F7G010 F7G#(lf)WHERE F7G.D_E_L_E_T_ = ''#(lf)    "
in
    Fonte;

shared dMotivosDeBaixa = let
  Origem = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query =sqlMotivosDeBaixa])
in
  Origem;

shared sqlCarteiraOrigem = let
    Fonte = "
SELECT
    SE1.E1_FILIAL   AS FILIAL,
    SE1.E1_NUM      AS DOC,
    SE1.E1_SITUACA  AS SITUACA,
    FRV.FRV_DESCRI  AS CARTEIRA,
    CAST(SE1.E1_VENCREA AS DATE)
                    AS VENCIMENTO
FROM SE1010 SE1 
INNER JOIN FRV010 FRV ON FRV.D_E_L_E_T_ = '' 
    AND FRV.FRV_CODIGO = SE1.E1_SITUACA 
WHERE SE1.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared fCarteiraOrigem = let
  Origem = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query =sqlCarteiraOrigem])
in
  Origem;

shared sqlConciliador = let
    Fonte = "#(cr)#(lf)SELECT #(cr)#(lf)    * #(cr)#(lf)FROM SIG010 SIG#(cr)#(lf)WHERE SIG.D_E_L_E_T_ = ''#(cr)#(lf)    "
in
    Fonte;

shared fConciliador = let
  Origem = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query =sqlConciliador])
in
  Origem;

shared sqlContasApagar = let
    Fonte = "
SELECT
    SE2.E2_FILIAL   AS FILIAL,
    SE2.E2_PREFIXO  AS PREFIXO,
    SE2.E2_NUM      AS NF,
    SE2.E2_PARCELA  AS PARCELA,
    SE2.E2_FORNECE  AS CODFORNECE,
    SE2.E2_LOJA     AS LJFORNECE, 
    SE2.E2_NOMFOR   AS FORNECEDOR,
    SE2.E2_TIPO     AS TIPO,
    SE2.E2_NATUREZ  AS NAT,
    SED.ED_DESCRIC  AS NATUREZA,
    CAST(SE2.E2_EMISSAO AS DATE)
                    AS DTEMISSAO,
    CAST(SE2.E2_VENCREA AS DATE)
                    AS VENCIMENTO_REAL,
    SE2.E2_X_RENEG  AS RENEGOCIADO,
    SE2.E2_JUROS    AS JUROS,
    SE2.E2_VALLIQ   AS LIQUIDO,
    CAST(SE2.E2_BAIXA AS DATE)
                    AS BAIXA,
    SE2.E2_VALLIQ   AS VALOR_BAIXA,
    SE2.E2_FORMPAG  AS PAGAMENTO,
    SE2.E2_VALOR    AS VALOR,
    SE2.E2_SALDO    AS SALDO,
    CAST(SE2.E2_VENCREA AS DATE)
                    AS VENCIMENTO,
    E2_FORMPAG      AS ""Cod. Forma Pgto"",
    E2_LINDIG       AS ""lin. Dig. Boleto"",
    E2_CODBAR       AS ""Cod. Barras Boleto"",
    SE2.E2_X_PRIOR AS PRIORIDADE,
    SE2.E2_X_SIT AS SITUACAO,
    SE2.E2_DECRESC AS DECRESCIMO,
    SE2.E2_FATURA AS FATURA,
    SE2.E2_NUMLIQ   AS LIQUIDACAO
FROM SE2010 SE2
    LEFT JOIN SED010 SED ON SED.D_E_L_E_T_ = ''
        AND SED.ED_CODIGO = SE2.E2_NATUREZ
WHERE SE2.D_E_L_E_T_ = ''
    AND SE2.E2_TIPO NOT IN ('FT ', 'NDF', 'PA ', 'PRE')
    "
in
    Fonte;

shared fContasApagar = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlContasApagar, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlbase_pagar = let
    Fonte = "
SELECT
    SE2.E2_FILIAL   AS FILIAL,
    SE2.E2_PREFIXO  AS PREFIXO,
    SE2.E2_NUM      AS NF,
    SE2.E2_PARCELA  AS PARCELA,
    SE2.E2_FORNECE  AS CODFORNECE,
    SE2.E2_LOJA     AS LJFORNECE, 
    SE2.E2_NOMFOR   AS FORNECEDOR,
    SE2.E2_TIPO     AS TIPO,
    SE2.E2_NATUREZ  AS NAT,
    SED.ED_DESCRIC  AS NATUREZA,
    CAST(SE2.E2_EMISSAO AS DATE)
                    AS DTEMISSAO,
    CAST(SE2.E2_VENCREA AS DATE)
                    AS VENCIMENTO_REAL,
    SE2.E2_X_RENEG  AS RENEGOCIADO,
    SE2.E2_JUROS    AS JUROS,
    SE2.E2_VALLIQ   AS LIQUIDO,
    CAST(SE2.E2_BAIXA AS DATE)
                    AS BAIXA,
    SE2.E2_VALLIQ   AS VALOR_BAIXA,
    SE2.E2_FORMPAG  AS PAGAMENTO,
    SE2.E2_VALOR    AS VALOR,
    SE2.E2_SALDO    AS SALDO,
    CAST(SE2.E2_VENCREA AS DATE)
                    AS VENCIMENTO,
    E2_FORMPAG      AS ""Cod. Forma Pgto"",
    E2_LINDIG       AS ""lin. Dig. Boleto"",
    E2_CODBAR       AS ""Cod. Barras Boleto"",
    CASE LEN(LTRIM(SA2.A2_CGC))
        WHEN 11 THEN
            STUFF(STUFF(STUFF(SA2.A2_CGC, 4, 0, '.'), 8, 0, '.'), 12, 0, '-')
        WHEN 14 THEN
            STUFF(STUFF(STUFF(STUFF(SA2.A2_CGC, 3, 0, '.'), 7, 0, '.'), 11, 0, '/'), 16, 0, '-')
        ELSE
            SA2.A2_CGC
    END             AS ""Cnpj/Cpf Fornecedor"",
    SA2.A2_NOME     AS ""Nome Fornecedor"",
    SE2.E2_X_SIT    AS SITUACAO
FROM SE2010 SE2
    LEFT JOIN SED010 SED ON SED.D_E_L_E_T_ = ''
        AND SED.ED_CODIGO   = SE2.E2_NATUREZ
    LEFT JOIN SA2010 SA2 ON SA2.D_E_L_E_T_ = '' 
        AND SA2.A2_COD      = SE2.E2_FORNECE
        AND SA2.A2_LOJA     = SE2.E2_LOJA
WHERE SE2.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared base_pagar = let
    fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlbase_pagar, CommandTimeout=#duration(69, 10, 39, 0)]),
    #"Outras Colunas Removidas" = Table.SelectColumns(fonte,{"FILIAL", "PREFIXO", "NF", "PARCELA", "FORNECEDOR", "TIPO", "NATUREZA", "DTEMISSAO", "VENCIMENTO_REAL", "RENEGOCIADO", "JUROS", "BAIXA", "VALOR_BAIXA", "PAGAMENTO", "VALOR", "SALDO", "VENCIMENTO", "Cnpj/Cpf Fornecedor", "SITUACAO"}),
    #"Colunas Renomeadas" = Table.RenameColumns(#"Outras Colunas Removidas", {{"FILIAL", "Filial"}, {"PREFIXO", "Prefixo"}, {"NF", "No. Titulo"}, {"PARCELA", "Parcela"}, {"TIPO", "Tipo"}, {"FORNECEDOR", "Razao Social"}, {"DTEMISSAO", "DT Emissao"}, {"VENCIMENTO", "Vencimento"}, {"VENCIMENTO_REAL", "Vencto Real"}, {"RENEGOCIADO", "Tit. Reneg?"}, {"VALOR", "Vlr.Titulo"}, {"JUROS", "Juros"}, {"SALDO", "Saldo"}, {"VALOR_BAIXA", "Val Liq Baix"}, {"BAIXA", "DT Baixa"}, {"PAGAMENTO", "Forma Pgto."}, {"NATUREZA", "Descr.Natur."}}),
    #"Texto Aparado" = Table.TransformColumns(#"Colunas Renomeadas",{{"Descr.Natur.", Text.Trim, type text}}),
    #"Consultas Mescladas" = Table.NestedJoin(#"Texto Aparado", {"Descr.Natur."}, dePara_Classif, {"de"}, "dePara_Classif", JoinKind.LeftOuter),
    #"dePara_Classif Expandido" = Table.ExpandTableColumn(#"Consultas Mescladas", "dePara_Classif", {"para"}, {"para"}),
    #"Coluna Condicional Adicionada" = Table.AddColumn(#"dePara_Classif Expandido", "Classificacao", each if [#"Descr.Natur."] = "ANTECIPACAO - FIDC" then Text.BeforeDelimiter([Razao Social], " ") else [para])
in
    #"Coluna Condicional Adicionada";

shared Fazer_dePara = let
    Fonte = base_pagar,
    #"Linhas Filtradas" = Table.SelectRows(Fonte, each ([para] = null)),
    #"Outras Colunas Removidas" = Table.SelectColumns(#"Linhas Filtradas",{"Descr.Natur."}),
    #"Duplicatas Removidas" = Table.Distinct(#"Outras Colunas Removidas")
in
    #"Duplicatas Removidas";

shared sqlContasApagarFrete = let
    Fonte = "
SELECT
    SE2.E2_FILIAL   AS ""Filial"",
    SF1.F1_ESPECIE  AS ""Espécie"",
    SE2.E2_NUM      AS ""No. Titulo"",
    SE2.E2_TIPO     AS ""Tipo"",
    SA2.A2_CGC      AS ""Fornecedor"",
    SE2.E2_NOMFOR   AS ""Razao Social"",
    CAST(SE2.E2_EMISSAO AS DATE)  
                    AS ""DT Emissao"", -- ? SE2.E2_EMISSAO
    CAST(SE2.E2_VENCREA AS DATE) 
                    AS ""Vencto Real"", -- ? SE2.E2_VENCREA
    SE2.E2_SALDO    AS ""Saldo"",
    SE2.E2_VALOR    AS ""Vlr.Titulo"",
    CAST(SE2.E2_BAIXA AS DATE)
                    AS ""DT Baixa"", -- ? SE2.E2_BAIXA
    SED.ED_DESCRIC  AS ""Descr.Natur.""
FROM SE2010 SE2
    LEFT JOIN SF1010 SF1 ON SF1.D_E_L_E_T_ = ''
        AND SF1.F1_FILIAL  = SE2.E2_FILIAL
        AND SF1.F1_DOC     = SE2.E2_NUM
        AND SF1.F1_FORNECE = SE2.E2_FORNECE
        AND SF1.F1_LOJA    = SE2.E2_LOJA
    LEFT JOIN SED010 SED ON SED.D_E_L_E_T_ = ''
        AND SED.ED_CODIGO  = SE2.E2_NATUREZ
    LEFT JOIN SA2010 SA2 ON SA2.D_E_L_E_T_ = ''
        AND SA2.A2_COD     = SE2.E2_FORNECE
        AND SA2.A2_LOJA    = SE2.E2_LOJA
WHERE SE2.D_E_L_E_T_ = ''
    AND SED.ED_DESCRIC LIKE '%FRETE%'
    AND SE2.E2_FATURA <> 'NOTFAT'
    "
in
    Fonte;

shared fContasApagarFrete = let
  Origem = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query =sqlContasApagarFrete]),
  #"Tipo de coluna alterado" = Table.TransformColumnTypes(Origem, {{"DT Emissao", type date}, {"Vencto Real", type date}, {"DT Baixa", type date}}),
  #"Texto aparado" = Table.TransformColumns(#"Tipo de coluna alterado", {{"Filial", each Text.Trim(_), type text}, {"Espécie", each Text.Trim(_), type nullable text}, {"No. Titulo", each Text.Trim(_), type text}, {"Tipo", each Text.Trim(_), type text}, {"Razao Social", each Text.Trim(_), type text}, {"Descr.Natur.", each Text.Trim(_), type nullable text}})
in
  #"Texto aparado";

shared sqlContasAReceber = let
    Fonte = "
SELECT 
    SE1.E1_FILIAL   AS FILIAL,
    SE1.E1_PREFIXO  AS PFX,
    SE1.E1_NUM      AS TITULO,
    SE1.E1_PARCELA  AS PARC,
    SE1.E1_TIPO     AS TIPO,
    SE1.E1_NATUREZ  AS NATUREZA,
    SE1.E1_SITUACA  AS CARTEIRA,
    SE1.E1_CLIENTE  AS CODCLI,
    SE1.E1_LOJA     AS LJCLI,
    SE1.E1_NOMCLI   AS CLIENTE,
    CAST(SE1.E1_EMISSAO AS DATE)
                    AS EMISSAO,
    CAST(SE1.E1_VENCTO AS DATE)
                    AS VENCTO,
    CAST(SE1.E1_VENCREA AS DATE)
                    AS VENCREAL,
    SE1.E1_VALOR    AS VALOR,
    CAST(SE1.E1_BAIXA AS DATE)
                    AS BAIXA,
    SE1.E1_NUMBOR   AS BORDERO,
    CAST(SE1.E1_DATABOR AS DATE)
                    AS DTBORDERO,
    SE1.E1_SALDO    AS SALDO,
    SE1.E1_VLCRUZ   AS VALORRS,
    SE1.E1_DESCFIN  AS DESCFIN,
    SA3.A3_NOME     AS VENDEDOR,
    SE1.E1_HIST     AS HISTORICO,
    SED.ED_DESCRIC  AS DESCRICAO,
    SE1.E1_FLUXO    AS FLUXO,
    SE1.E1_FORMREC  AS ""Form. Receb"",
    FRV.FRV_DESCRI  AS ""Nome Carteira"",
    SE1.E1_X_FREC   AS ""Forma de Recebimento""
FROM SE1010 SE1
    LEFT JOIN SED010 SED ON SED.D_E_L_E_T_ = ''
        AND SED.ED_CODIGO = SE1.E1_NATUREZ
    LEFT JOIN SA3010 SA3 ON SA3.D_E_L_E_T_ = ''
        AND SA3.A3_COD = SE1.E1_VEND1
    LEFT JOIN FRV010 FRV ON FRV.D_E_L_E_T_ = ''
        AND FRV.FRV_CODIGO = SE1.E1_SITUACA
WHERE SE1.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared fContasAReceber = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlContasAReceber, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlbase_receber = let
    Fonte = "

SELECT 
    SE1.E1_FILIAL   AS FILIAL,
    SE1.E1_PREFIXO  AS PFX,
    SE1.E1_NUM      AS TITULO,
    SE1.E1_PARCELA  AS PARC,
    SE1.E1_TIPO     AS TIPO,
    SE1.E1_NATUREZ  AS NATUREZA,
    SE1.E1_SITUACA  AS CARTEIRA,
    SE1.E1_CLIENTE  AS CODCLI,
    SE1.E1_LOJA     AS LJCLI,
    SE1.E1_NOMCLI   AS CLIENTE,
    CAST(SE1.E1_EMISSAO AS DATE)
                    AS EMISSAO,
    CAST(SE1.E1_VENCTO AS DATE)
                    AS VENCTO,
    CAST(SE1.E1_VENCREA AS DATE)
                    AS VENCREAL,
    SE1.E1_VALOR    AS VALOR,
    CAST(SE1.E1_BAIXA AS DATE)
                    AS BAIXA,
    SE1.E1_NUMBOR   AS BORDERO,
    CAST(SE1.E1_DATABOR AS DATE)
                    AS DTBORDERO,
    SE1.E1_SALDO    AS SALDO,
    SE1.E1_VLCRUZ   AS VALORRS,
    SE1.E1_DESCFIN  AS DESCFIN,
    SA3.A3_NOME     AS VENDEDOR,
    SE1.E1_HIST     AS HISTORICO,
    SED.ED_DESCRIC  AS DESCRICAO,
    SE1.E1_FLUXO    AS FLUXO,
    SE1.E1_FORMREC  AS ""Form. Receb"",
    FRV.FRV_DESCRI  AS ""Nome Carteira"",
    SE1.E1_X_FREC   AS ""Forma de Recebimento"",
    CASE LEN(LTRIM(SA1.A1_CGC))
        WHEN 11 THEN
            STUFF(STUFF(STUFF(SA1.A1_CGC, 4, 0, '.'), 8, 0, '.'), 12, 0, '-')
        WHEN 14 THEN
            STUFF(STUFF(STUFF(STUFF(SA1.A1_CGC, 3, 0, '.'), 7, 0, '.'), 11, 0, '/'), 16, 0, '-')
        ELSE
            SA1.A1_CGC
    END             AS ""Cnpj/Cpf Cliente""

FROM SE1010 SE1
    LEFT JOIN SED010 SED ON SED.D_E_L_E_T_ = ''
        AND SED.ED_CODIGO = SE1.E1_NATUREZ
    LEFT JOIN SA3010 SA3 ON SA3.D_E_L_E_T_ = ''
        AND SA3.A3_COD = SE1.E1_VEND1
    LEFT JOIN SA1010 SA1 ON SA1.D_E_L_E_T_ = '' 
        AND SA1.A1_COD      = SE1.E1_CLIENTE
        AND SA1.A1_LOJA     = SE1.E1_LOJA
    LEFT JOIN FRV010 FRV ON FRV.D_E_L_E_T_ = ''
        AND FRV.FRV_CODIGO = SE1.E1_SITUACA
WHERE SE1.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared base_receber = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlbase_receber, CommandTimeout=#duration(69, 10, 39, 0)]),
    #"Outras Colunas Removidas" = Table.SelectColumns(Fonte,{"FILIAL", "PFX", "TITULO", "PARC", "TIPO", "Cnpj/Cpf Cliente", "CLIENTE", "EMISSAO", "VENCTO", "VENCREAL", "VALOR", "BAIXA", "SALDO", "DESCFIN", "VENDEDOR", "HISTORICO", "DESCRICAO", "FLUXO", "Form. Receb", "Nome Carteira"}),
    #"Colunas Renomeadas" = Table.RenameColumns(#"Outras Colunas Removidas",{{"FILIAL", "Filial"}, {"PFX", "Prefixo No."}, {"TITULO", "Titulo"}, {"PARC", "Parcela"}, {"TIPO", "Tipo"}, {"CLIENTE", "Razao Social"}, {"EMISSAO", "DT Emissao"}, {"VENCTO", "Vencimento"}, {"VENCREAL", "Vencto real"}, {"BAIXA", "DT Baixa"}, {"VALOR", "Vlr.Titulo"}, {"DESCFIN", "Desc Financ."}, {"SALDO", "Saldo"}, {"FLUXO", "Fluxo Caixa"}, {"DESCRICAO", "Natureza Fin"}, {"HISTORICO", "Historico"}, {"Nome Carteira", "Carteira"}, {"VENDEDOR", "Nome Vend"}}),
    #"Coluna Mesclada Inserida" = Table.AddColumn(#"Colunas Renomeadas", "Vl Dsc/Abto", each [#"Desc Financ."] * 0.01 * [Vlr.Titulo], type text),
    #"Tipo Alterado" = Table.TransformColumnTypes(#"Coluna Mesclada Inserida",{{"Vl Dsc/Abto", type number}}),
    #"Texto Aparado" = Table.TransformColumns(#"Tipo Alterado",{{"Carteira", Text.Trim, type text}})
in
    #"Texto Aparado";

shared sqlCpEmprestimos = let
    Fonte = "
SELECT 
    E2_FILIAL   AS FILIAL,
    E2_PREFIXO  AS PREFIXO,
    E2_NUM      AS NUMTIT,
    E2_PARCELA  AS PARCELA,
    E2_TIPO     AS TIPO,
    E2_NATUREZ  AS NATUREZA,
    E2_PORTADO  AS PORTADO,
    E2_FORNECE  AS CODFORNECE,
    E2_LOJA     AS LJFORNC,
    E2_NOMFOR   AS NOMFOR,
    CAST(E2_EMISSAO AS DATE)
                AS DTAEMISSAO,
    CAST(E2_VENCREA AS DATE)
                AS DTAVCTOREAL,
    CAST(E2_VENCTO AS DATE)
                AS DTAVCTO,
    CAST(E2_VENCORI AS DATE)
                AS DTAVCTOORIGINAL,
    CAST(E2_EMIS1 AS DATE)
                AS DTAEMISSAO1,
    CAST(E2_BAIXA AS DATE)
                AS DTABAIXA,
    E2_VALOR    AS VALOR,
    E2_DESCONT  AS VALORDESCONTO,
    E2_MULTA    AS VALORMULTA,
    E2_JUROS    AS VALORJUROS,
    E2_CORREC   AS VALORCORRECAO,
    E2_ACRESC   AS VALORACRESC,
    E2_VALLIQ   AS VALORLIQUIDADO,
    E2_SALDO    AS VALORSALDO,
    E2_BCOPAG   AS BCOPAG,
    E2_HIST     AS HISTORICO,
    E2_MOTIVO   AS MOTIVOBAIXA,
    E2_CONTAD   AS CONTACONTABIL
FROM 
    SE2010	
WHERE 
    D_E_L_E_T_ <> '*'
    -- EXCLUINDO AS NATUREZAS DE INVESTIMENTOS
    AND E2_NATUREZ IN ( '    0407','0407001','0407002','0407003','0407004','0407005','0407006','0407007','0407008','0407009','0407010','0407011','0407012','0407013','0407014','0407015','0407016','0407017',
'0407018','0407019','0407020','0407021','0407022','0407023','0407024','0407025','0407026','0407027')
    AND (E2_VALLIQ >= 0 and E2_BCOPAG <> '')
    "
in
    Fonte;

shared fCpEmprestimos = let
  Origem = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query =sqlCpEmprestimos])
in
    Origem;

shared sqlCTASPAGARPRAZO = let
    Fonte = "#(cr)#(lf)SELECT#(cr)#(lf)    SE2.E2_FILIAL       AS FILIAL,#(cr)#(lf)    SE2.E2_NUM          AS NF,#(cr)#(lf)    SE2.E2_PARCELA      AS PARCELA,#(cr)#(lf)    SE2.E2_NOMFOR       AS FORNECEDOR,#(cr)#(lf)    SE2.E2_NATUREZ      AS NAT,#(cr)#(lf)    SED.ED_DESCRIC      AS NATUREZA,#(cr)#(lf)    CAST(SE2.E2_EMISSAO AS DATE)#(cr)#(lf)                        AS DTEMISSAO,#(cr)#(lf)    CAST(SF1.F1_RECBMTO AS DATE)#(cr)#(lf)                        AS DTRECEBIDO,#(cr)#(lf)    SE2.E2_VALOR        AS VALOR,#(cr)#(lf)    SE2.E2_SALDO        AS SALDO,#(cr)#(lf)    DATEDIFF(DAY, SE2.E2_EMISSAO, SE2.E2_VENCREA)   #(cr)#(lf)                        AS DIASDAEMISSAO,#(cr)#(lf)    DATEDIFF(DAY, SF1.F1_RECBMTO, SE2.E2_VENCREA)   #(cr)#(lf)                        AS DIASDORECBMTO,#(cr)#(lf)    DATEDIFF(DAY, SE2.E2_EMISSAO, SE2.E2_VENCREA) - DATEDIFF(DAY, SF1.F1_RECBMTO, SE2.E2_VENCREA) #(cr)#(lf)                        AS DIFPRAZO,#(cr)#(lf)    CAST(SE2.E2_VENCREA AS DATE)#(cr)#(lf)                        AS VENCIMENTO#(cr)#(lf)FROM SE2010 SE2#(cr)#(lf)    INNER JOIN SF1010 SF1 ON SF1.D_E_L_E_T_ = '' #(cr)#(lf)        AND SF1.F1_FILIAL  = SE2.E2_FILIAL #(cr)#(lf)        AND SF1.F1_DOC     = SE2.E2_NUM    #(cr)#(lf)        AND SF1.F1_FORNECE = SE2.E2_FORNECE #(cr)#(lf)        AND SF1.F1_LOJA    = SE2.E2_LOJA#(cr)#(lf)    INNER JOIN SED010 SED ON SED.D_E_L_E_T_ = '' #(cr)#(lf)        AND SED.ED_CODIGO  = SE2.E2_NATUREZ#(cr)#(lf)WHERE SE2.D_E_L_E_T_ = ''#(cr)#(lf)    AND SE2.E2_SALDO <> 0#(cr)#(lf)    "
in
    Fonte;

shared fCTASPAGARPRAZO = let
  Origem = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query =sqlCTASPAGARPRAZO]),
  #"Tipo de coluna alterado" = Table.TransformColumnTypes(Origem, {{"DTEMISSAO", type date}, {"DTRECEBIDO", type date}, {"VENCIMENTO", type date}}),
  #"Colunas reordenadas" = Table.ReorderColumns(#"Tipo de coluna alterado", {"FILIAL", "NF", "PARCELA", "FORNECEDOR", "NATUREZA", "DTEMISSAO", "DIASDAEMISSAO", "DTRECEBIDO", "DIASDORECBMTO", "DIFPRAZO", "VENCIMENTO", "VALOR", "SALDO"}),
  #"Tipo de coluna alterado 1" = Table.TransformColumnTypes(#"Colunas reordenadas", {{"SALDO", Currency.Type}, {"VALOR", Currency.Type}}),
  #"Colunas renomeadas" = Table.RenameColumns(#"Tipo de coluna alterado 1", {{"DIFPRAZO", "DIFERENÇA PRAZO"}, {"DIASDORECBMTO", "N DIAS RCBMTO"}, {"DTRECEBIDO", "DT RECEBIMENTO"}, {"DIASDAEMISSAO", "N DIAS EMISSAO"}, {"DTEMISSAO", "DT EMISSAO"}})
in
  #"Colunas renomeadas";

shared sqlDescComissoes = let
    Fonte = "
SELECT
    SE2.E2_FILIAL       AS FILIAL,
    SE2.E2_PREFIXO      AS PREFIXO,
    SE2.E2_NUM          AS NF,
    SE2.E2_PARCELA      AS PARCELA,
    SE2.E2_FORNECE      AS CODFORNECE,
    SE2.E2_LOJA         AS LJFORNECE, 
    SE2.E2_NOMFOR       AS FORNECEDOR,
    SE2.E2_TIPO         AS TIPO,
    SE2.E2_NATUREZ      AS NAT,
    SED.ED_DESCRIC      AS NATUREZA,
    CAST(SE2.E2_EMISSAO AS DATE)
                        AS DTEMISSAO,
    CAST(SE2.E2_VENCREA AS DATE)
                        AS VENCIMENTO_REAL,
    SE2.E2_X_RENEG      AS RENEGOCIADO,
    SE2.E2_JUROS        AS JUROS,
    SE2.E2_VALLIQ       AS LIQUIDO,
    CAST(SE2.E2_BAIXA AS DATE)
                        AS BAIXA,
    SE2.E2_VALLIQ       AS VALOR_BAIXA,
    SE2.E2_FORMPAG      AS PAGAMENTO,
    SE2.E2_VALOR        AS VALOR,
    SE2.E2_SALDO        AS SALDO,
    CAST(SE2.E2_VENCREA AS DATE)
                        AS VENCIMENTO,
    E2_HIST             AS DECRICAO
FROM SE2010 SE2
    INNER JOIN SED010 SED ON SED.D_E_L_E_T_ = ''
        AND SED.ED_CODIGO = SE2.E2_NATUREZ
WHERE SE2.D_E_L_E_T_ = ''
    AND SE2.E2_FATURA <> 'NOTFAT'
    AND SE2.E2_TIPO = 'NDF'
    AND SE2.E2_NATUREZ = '0302004'
    "
in
    Fonte;

shared fDescComissoes = let
  Origem = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query =sqlDescComissoes]),
  #"Tipo de coluna alterado" = Table.TransformColumnTypes(Origem, {{"DTEMISSAO", type date}, {"VENCIMENTO_REAL", type date}, {"VENCIMENTO", type date}, {"BAIXA", type date}})
in
    #"Tipo de coluna alterado";

shared sqlDevolucoes = let
    Fonte = "SELECT#(cr)#(lf)    SF1.F1_FILIAL AS FILIAL,#(cr)#(lf)    SF1.F1_DOC AS NF,#(cr)#(lf)    SF1.F1_SERIE AS SERIE,#(cr)#(lf)    SD1.D1_ITEM AS ITEM,#(cr)#(lf)    SD1.D1_COD AS CODIGO,#(cr)#(lf)    SD1.D1_TOTAL,#(cr)#(lf)    SF1.F1_FORNECE AS FORNEC_CLIEN_CODIGO,#(cr)#(lf)    SF1.F1_LOJA AS FORNEC_CLIEN_LOJA,#(cr)#(lf)    COALESCE(SA2.A2_NOME, SA1.A1_NOME) AS FORNEC_CLIEN_NOME,#(cr)#(lf)    CONVERT(VARCHAR, CAST(SF1.F1_EMISSAO AS DATE), 103) AS EMISSAO#(cr)#(lf)FROM SF1010 SF1#(cr)#(lf)INNER JOIN SD1010 SD1 ON SD1.D_E_L_E_T_ <> '*' AND SF1.F1_DOC = SD1.D1_DOC AND SF1.F1_SERIE = SD1.D1_SERIE#(cr)#(lf)LEFT JOIN SA2010 SA2 ON SA2.D_E_L_E_T_ <> '*' AND SF1.F1_FORNECE = SA2.A2_COD AND SF1.F1_LOJA = SA2.A2_LOJA#(cr)#(lf)LEFT JOIN SA1010 SA1 ON SA1.D_E_L_E_T_ <> '*' AND SF1.F1_FORNECE = SA1.A1_COD AND SF1.F1_LOJA = SA1.A1_LOJA#(cr)#(lf)WHERE#(cr)#(lf)    SF1.D_E_L_E_T_ <> '*' AND#(cr)#(lf)    SF1.F1_STATUS = '' AND#(cr)#(lf)    SF1.F1_TIPO = 'D'"
in
    Fonte;

shared fDevolucoes = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlDevolucoes, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlMovimentoBancario = let
    Fonte = "
SELECT
    SE5.E5_FILORIG  AS FILIAL,
    CAST(SE5.E5_DATA AS DATE) 
                    AS DTMOVIMENTO,
    SE5.E5_TIPO     AS TIPO,
    SE5.E5_NATUREZ  AS NATFIN,
    SED.ED_DESCRIC  AS NATUREZA,
    SE5.E5_HISTOR   AS OBSERVACAO,
    SE5.E5_TIPODOC  AS TIPODOC,
    SE5.E5_PREFIXO  AS PFX,
    SE5.E5_PARCELA  AS PARCELA,
    SE5.E5_CLIFOR   AS CLIFOR,
    SE5.E5_LOJA     AS LOJA,
    SE5.E5_BENEF    AS FORNECEDOR,
    SE5.E5_NUMERO   AS TITULO,
    SE5.E5_MOTBX    AS MOTIVOBAIXA,
    SE5.E5_VALOR - SE5.E5_VLJUROS - SE5.E5_VLMULTA + SE5.E5_VLDESCO 
                    AS VRTITULO,
    SE5.E5_VALOR    AS VRQUITADO
FROM SE5010 SE5
    INNER JOIN SED010 SED ON SED.D_E_L_E_T_ = ''
        AND SED.ED_CODIGO = SE5.E5_NATUREZ
WHERE SE5.D_E_L_E_T_ = ''
    AND SE5.E5_MOTBX = 'DEB'
    AND (
        SE5.E5_TIPODOC IN ('MT', 'JR') 
        OR (SE5.E5_NATUREZ = '0406001')
    )
    "
in
    Fonte;

shared fMovimentoBancario = let
  Origem = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query =sqlMovimentoBancario]),
  #"Tipo de coluna alterado" = Table.TransformColumnTypes(Origem, {{"DTMOVIMENTO", type date}}),
  #"Ano inserido" = Table.AddColumn(#"Tipo de coluna alterado", "Ano", each Date.Year([DTMOVIMENTO]), type nullable number),
  #"Nome do mês inserido" = Table.AddColumn(#"Ano inserido", "Nome do mês", each Date.MonthName([DTMOVIMENTO]), type nullable text),
  #"Texto aparado" = Table.TransformColumns(#"Nome do mês inserido", {{"NATUREZA", each Text.Trim(_), type text}}),
  #"Consultas mescladas" = Table.NestedJoin(#"Texto aparado", {"NATUREZA"}, dGrupoNat, {"Descr.Natur."}, "dGrupoNat", JoinKind.LeftOuter),
  #"Expandido dGrupoNat" = Table.ExpandTableColumn(#"Consultas mescladas", "dGrupoNat", {"Subgrupo"}, {"Subgrupo"}),
  #"Colunas reordenadas" = Table.ReorderColumns(#"Expandido dGrupoNat", {"FILIAL", "DTMOVIMENTO", "TIPO", "NATFIN", "Subgrupo", "NATUREZA", "OBSERVACAO", "TIPODOC", "PFX", "PARCELA", "CLIFOR", "LOJA", "FORNECEDOR", "TITULO", "MOTIVOBAIXA", "VRTITULO", "VRQUITADO", "Ano", "Nome do mês"}),
  #"Texto aparado 1" = Table.TransformColumns(#"Colunas reordenadas", {{"NATFIN", each Text.Trim(_), type text}}),
  #"Coluna condicional inserida" = Table.AddColumn(#"Texto aparado 1", "TIPO DE JUROS", each if [PFX] = "EPJ" then "JUROS DE EMPRESTIMO" else if [NATFIN] = "0406001" then "JUROS DE ANTECIPAÇÃO" else "JUROS DE MORA")
in
  #"Coluna condicional inserida";

shared sqlNCC = let
    Fonte = "
SELECT
    SE1.E1_FILIAL   AS FILIAL,
    SE1.E1_PREFIXO  AS PFX,
    SE1.E1_NUM      AS TITULO,
    SE1.E1_PARCELA  AS PARC,
    SE1.E1_TIPO     AS TIPO,
    SE1.E1_NATUREZ  AS NATUREZA,
    SE1.E1_CLIENTE  AS CODCLI,
    SE1.E1_LOJA     AS LJCLI,
    SE1.E1_NOMCLI   AS CLIENTE,
    CAST(SE1.E1_EMISSAO AS DATE)
                    AS EMISSAO,
    CAST(SE1.E1_VENCTO AS DATE)
                    AS VENCTO,
    CAST(SE1.E1_VENCREA AS DATE)
                    AS VENCREAL,
    SE1.E1_VALOR    AS VALOR,
    CAST(SE1.E1_BAIXA AS DATE)
                    AS BAIXA,
    SE1.E1_NUMBOR   AS BORDERO,
    CAST(SE1.E1_DATABOR AS DATE)
                    AS DTBORDERO,
    SE1.E1_SALDO    AS SALDO
FROM SE1010 SE1
WHERE SE1.D_E_L_E_T_ = ''
    AND SE1.E1_TIPO = 'NCC'
    "
in
    Fonte;

shared fNCC = let
  Origem = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query =sqlNCC])
in
  Origem;

shared sqlNFORI = let
    Fonte = "
SELECT 
    SF1.F1_FILIAL, 
    SF1.F1_DOC,
    SF1.F1_SERIE,
    SF1.F1_FORNECE,
    SF1.F1_LOJA,
    CAST(SF1.F1_EMISSAO AS DATE) AS DTEMISSAO,
    SD1.D1_NFORI
FROM SF1010 SF1
    INNER JOIN SD1010 SD1 ON SD1.D_E_L_E_T_ = ''
        AND SD1.D1_FILIAL   = SF1.F1_FILIAL
        AND SD1.D1_DOC      = SF1.F1_DOC
        AND SD1.D1_SERIE    = SF1.F1_SERIE
        AND SD1.D1_FORNECE  = SF1.F1_FORNECE
        AND SD1.D1_LOJA     = SF1.F1_LOJA
WHERE SF1.D_E_L_E_T_    = ''
    AND SD1.D1_NFORI <> ''
    AND SF1.F1_DOC <> '000000000'
    "
in
    Fonte;

shared fNFORI = let
  Origem = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query =sqlNFORI]),
    #"Tipo Alterado" = Table.TransformColumnTypes(Origem,{{"DTEMISSAO", type date}})
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
    "
in
    Fonte;

shared fSemClassificar = let
  Origem = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query =sqlSemClassificar]),
    #"Tipo Alterado" = Table.TransformColumnTypes(Origem,{{"EMISSAO", type date}})
in
    #"Tipo Alterado";

shared sqlCCxNat = let
    Fonte = "
SELECT
    SF1.F1_FILIAL                AS FILIAL,
    SF1.F1_DOC                   AS NF,
    SF1.F1_SERIE                 AS SERIE,
    SE2.E2_NOMFOR                AS FORNECEDOR,
    CAST(SF1.F1_EMISSAO AS DATE) AS EMISSAO,
    CAST(SE2.E2_VENCREA AS DATE) AS VENCIMENTO_REAL,
    CAST(SF1.F1_DTDIGIT AS DATE) AS DIGITACAO,
    SE2.E2_PARCELA               AS PARCELA,
    SE2.E2_VALOR                 AS VALOR,
    SED.ED_DESCRIC               AS NATUREZA,
    CTT.CTT_DESC01               AS CENTROCUSTO
FROM SF1010 SF1
    INNER JOIN SE2010 SE2 ON SE2.D_E_L_E_T_ = ''
        AND SF1.F1_FILIAL  = SE2.E2_FILIAL
        AND SF1.F1_DOC     = SE2.E2_NUM
        AND SF1.F1_PREFIXO = SE2.E2_PREFIXO
        AND SF1.F1_FORNECE = SE2.E2_FORNECE
        AND SF1.F1_LOJA    = SE2.E2_LOJA
    INNER JOIN SD1010 SD1 ON SD1.D_E_L_E_T_ = '' 
        AND SF1.F1_FILIAL  = SD1.D1_FILIAL
        AND SF1.F1_DOC     = SD1.D1_DOC
        AND SF1.F1_SERIE   = SD1.D1_SERIE 
        AND SF1.F1_FORNECE = SD1.D1_FORNECE 
        AND SF1.F1_LOJA    = SD1.D1_LOJA
    LEFT JOIN CTT010 CTT ON CTT.D_E_L_E_T_ = '' 
        AND CTT.CTT_CUSTO  = SD1.D1_CC
    INNER JOIN SED010 SED ON SED.D_E_L_E_T_ = ''
        AND SED.ED_CODIGO  = SE2.E2_NATUREZ
WHERE SF1.D_E_L_E_T_ = ''
    AND SE2.E2_TIPO NOT IN ('FT ', 'NDF', 'PA ', 'PR ', 'PRE')
    AND SE2.E2_FATURA <> 'NOTFAT'
    "
in
    Fonte;

shared ffCCxNat = let
  Origem = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query =sqlCCxNat]),
    #"Tipo Alterado" = Table.TransformColumnTypes(Origem,{{"EMISSAO", type date}})
in
    #"Tipo Alterado";

shared sqlFormPgto = let
    Fonte = "
SELECT
    SX5_058.X5_CHAVE,
    SX5_058.X5_DESCRI
FROM SX5010 SX5_058
WHERE SX5_058.D_E_L_E_T_ = ''
    AND SX5_058.X5_TABELA = '58'
    "
in
    Fonte;

shared dFormPgto = let
  Origem = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query =sqlFormPgto]),
    #"Texto Aparado" = Table.TransformColumns(Origem,{{"X5_CHAVE", Text.Trim, type text}, {"X5_DESCRI", Text.Trim, type text}})
in
    #"Texto Aparado";

shared sqlMovBancarioFK5 = let
    Fonte = "
SELECT 
    * 
FROM FK5010 FK5
WHERE FK5.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared dMovBancarioFK5 = let
  Origem = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query =sqlMovBancarioFK5])
in
    Origem;

shared sqlMovBancarioFK7 = let
    Fonte = "#(lf)SELECT #(lf)    * #(lf)FROM FK7010 FK7#(lf)WHERE FK7.D_E_L_E_T_ = ''#(lf)    "
in
    Fonte;

shared dMovBancarioFK7 = let
  Origem = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query =sqlMovBancarioFK7])
in
    Origem;

shared sqlfTarifasBancarias = let
    Fonte = "
    SELECT
    SE5.E5_FILORIG AS FILIAL,
    CAST(SE5.E5_DATA AS DATE) AS DTMOVIMENTO,
    SE5.E5_VALOR AS VRTITULO,
    SE5.E5_HISTOR AS HISTORICO,
    SED.ED_DESCRIC AS NATUREZA,
    TRIM(TRIM(SE5.E5_BANCO) + TRIM(SE5.E5_AGENCIA) + TRIM(SE5.E5_CONTA)) AS CHAVEBANCO
FROM
    SE5010 SE5
INNER JOIN
    SED010 SED ON SE5.E5_NATUREZ = SED.ED_CODIGO
WHERE
    SE5.D_E_L_E_T_ = ''
    AND SE5.E5_SITUACA <> 'C'
    AND SE5.E5_TIPODOC <> 'ES'
    AND SE5.E5_NATUREZ IN ('0502001', '0406004', '0406005', '0406006', '0406007', '0406008', '0406009', '0406010', '0406011', '0406018', '0406003', '0102001')
    AND SED.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared fTarifasBancárias = let
  Origem = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query =sqlfTarifasBancarias]),
    #"Tipo Alterado" = Table.TransformColumnTypes(Origem,{{"DTMOVIMENTO", type date}})
in
    #"Tipo Alterado";

shared sqlfMultiplasNaturezas = let
    Fonte = "SELECT 
SEV.EV_FILIAL AS FILIAL,
SEV.EV_PREFIXO AS PFX,
SEV.EV_NUM AS TITULO,
SEV.EV_PARCELA AS PARC,
SEV.EV_CLIFOR AS CLIFOR,
SEV.EV_LOJA AS LJ, 
SEV.EV_TIPO AS TIPO,
SEV.EV_VALOR AS VALOR,
SEV.EV_NATUREZ AS NATUREZA,
SEV.EV_PERC AS ""%RATEIO""
FROM SEV010 SEV
WHERE SEV.D_E_L_E_T_ = ''"
in
    Fonte;

shared fMultiplasNaturezas = let
  Origem = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query =sqlfMultiplasNaturezas])
in
    Origem;

shared sqlfDescObtidos = let
    Fonte = "
SELECT
    CAST(SE2.E2_EMISSAO AS DATE)
                            AS ""DATA"",
    'DESCONTO OBTIDO'       AS ""OPERAÇÃO"",
    SE2.E2_DESCONT          AS ""VALOR"",
    SE2.E2_NATUREZ          AS ""CODNAT"",
    SED.ED_DESCRIC          AS ""NATUREZA"",
    SE2.E2_FORNECE          AS ""CODFOR"",
    SE2.E2_LOJA             AS ""LJ"",
    SA2.A2_NOME             AS ""FORNECEDOR""
FROM SE2010 SE2
    LEFT JOIN SED010 SED ON SED.D_E_L_E_T_ = ''
        AND SED.ED_CODIGO   = SE2.E2_NATUREZ
    LEFT JOIN SA2010 SA2 ON SA2.D_E_L_E_T_ = ''
        AND SA2.A2_COD      = SE2.E2_FORNECE
        AND SA2.A2_LOJA     = SE2.E2_LOJA
WHERE SE2.D_E_L_E_T_ = ''
    AND SE2.E2_DESCONT <> 0
    "
in
    Fonte;

shared fDescObtidos = let
  Origem = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query =sqlfDescObtidos]),
    #"Tipo Alterado" = Table.TransformColumnTypes(Origem,{{"DATA", type date}, {"VALOR", Currency.Type}}),
    #"Texto Cortado" = Table.TransformColumns(#"Tipo Alterado",{{"OPERAÇÃO", Text.Trim, type text}, {"CODNAT", Text.Trim, type text}, {"NATUREZA", Text.Trim, type text}, {"CODFOR", Text.Trim, type text}, {"LJ", Text.Trim, type text}, {"FORNECEDOR", Text.Trim, type text}})
in
    #"Texto Cortado";

shared sqlfDescConcedidos = let
    Fonte = "
SELECT
    CAST(SE1.E1_EMISSAO AS DATE)
                        AS ""DATA"",
    'DESCONTO CONCEDIDO'   AS ""OPERAÇÃO"",
    SE1.E1_DESCONT      AS ""VALOR"",
    SE1.E1_NATUREZ      AS ""CODNAT"",
    SED.ED_DESCRIC      AS ""NATUREZA"",
    SE1.E1_CLIENTE      AS ""CODCLI"",
    SE1.E1_LOJA         AS ""LJ"",
    SA1.A1_NOME         AS ""CLIENTE""
FROM SE1010 SE1
    LEFT JOIN SED010 SED ON SED.D_E_L_E_T_ = ''
        AND SED.ED_CODIGO   = SE1.E1_NATUREZ
    LEFT JOIN SA1010 SA1 ON SA1.D_E_L_E_T_ = ''
        AND SA1.A1_COD      = SE1.E1_CLIENTE
        AND SA1.A1_LOJA     = SE1.E1_LOJA
WHERE SE1.D_E_L_E_T_ = ''
    AND SE1.E1_DESCONT <> 0
    "
in
    Fonte;

shared fDescConcedidos = let
  Origem = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query =sqlfDescConcedidos]),
    #"Tipo Alterado" = Table.TransformColumnTypes(Origem,{{"DATA", type date}, {"VALOR", Currency.Type}}),
    #"Texto Cortado" = Table.TransformColumns(#"Tipo Alterado",{{"OPERAÇÃO", Text.Trim, type text}, {"CODNAT", Text.Trim, type text}, {"NATUREZA", Text.Trim, type text}, {"CODCLI", Text.Trim, type text}, {"LJ", Text.Trim, type text}, {"CLIENTE", Text.Trim, type text}})
in
    #"Texto Cortado";

shared __STATUS__ = let
    Fonte = if Table.RowCount(Table.Combine({dePara_Classif, dGrupoNat, #"dGrupoNat (2)", Consulta, dBancos, dMotivosDeBaixa, fCarteiraOrigem, fConciliador, fContasApagar, base_pagar, Fazer_dePara, fContasApagarFrete, fContasAReceber, base_receber, fCpEmprestimos, fCTASPAGARPRAZO, fDescComissoes, fDevolucoes, fMovimentoBancario, fNCC, fNFORI, fSemClassificar, ffCCxNat, dFormPgto, dMovBancarioFK5, dMovBancarioFK7, fTarifasBancárias, fMultiplasNaturezas, fDescConcedidos, fDescObtidos})) > 0 then DateTime.LocalNow() else "Pendente"
in
    Fonte;

shared __SQL__ = let
    #"Linhas Filtradas" = Table.SelectRows(Record.ToTable(#shared), each Text.StartsWith([Name], "sql"))
in
    #"Linhas Filtradas";

shared sqlMensurarImpacto = let
    Fonte = "
SELECT
    SE2.E2_FILIAL   AS FILIAL,
    SE2.E2_PREFIXO  AS PREFIXO,
    SE2.E2_NUM      AS NF,
    SE2.E2_PARCELA  AS PARCELA,
    SE2.E2_FORNECE  AS CODFORNECE,
    SE2.E2_LOJA     AS LJFORNECE, 
    SE2.E2_NOMFOR   AS FORNECEDOR,
    SE2.E2_TIPO     AS TIPO,
    SE2.E2_NATUREZ  AS NAT,
    SED.ED_DESCRIC  AS NATUREZA,
    CAST(SE2.E2_EMISSAO AS DATE)
                    AS DTEMISSAO,
    CAST(SE2.E2_VENCREA AS DATE)
                    AS VENCIMENTO_REAL,
    SE2.E2_X_RENEG  AS RENEGOCIADO,
    SE2.E2_JUROS    AS JUROS,
    SE2.E2_VALLIQ   AS LIQUIDO,
    CAST(SE2.E2_BAIXA AS DATE)
                    AS BAIXA,
    SE2.E2_VALLIQ   AS VALOR_BAIXA,
    SE2.E2_FORMPAG  AS PAGAMENTO,
    SE2.E2_VALOR    AS VALOR,
    SE2.E2_SALDO    AS SALDO,
    CAST(SE2.E2_VENCREA AS DATE)
                    AS VENCIMENTO,
    E2_FORMPAG      AS ""Cod. Forma Pgto"",
    E2_LINDIG       AS ""lin. Dig. Boleto"",
    E2_CODBAR       AS ""Cod. Barras Boleto"",
    SE2.E2_X_PRIOR AS PRIORIDADE,
    SE2.E2_X_SIT AS SITUACAO,
    SE2.E2_DECRESC AS DECRESCIMO,
    SE2.E2_FATURA AS FATURA,
    SE5.E5_MOTBX AS BAIXA 
FROM SE2010 SE2
    INNER JOIN SED010 SED ON SED.D_E_L_E_T_ = ''
        AND SED.ED_CODIGO = SE2.E2_NATUREZ
    LEFT JOIN SE5010 SE5 ON SE5.D_E_L_E_T_ = ''
        AND SE5.E5_CLIFOR = SE2.E2_FORNECE
        AND SE5.E5_LOJA = SE2.E2_LOJA
        AND SE5.E5_NUMERO = SE2.E2_NUM
        AND SE5.E5_PARCELA = SE2.E2_PARCELA
        AND SE5.E5_PREFIXO = SE2.E2_PREFIXO
        AND SE5.E5_VALOR = SE2.E2_VALLIQ
WHERE SE2.D_E_L_E_T_ = ''
    AND SE2.E2_TIPO NOT IN ('FT ', 'NDF', 'PA ', 'PRE')
    AND SE2.E2_NUMLIQ = ''
    AND (SE5.E5_MOTBX <> 'DAC' OR SE5.E5_MOTBX IS NULL) 
    "
in
    Fonte;

shared fMensurarImpacto = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlMensurarImpacto, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlMovimentoBancarioNCC = let
    Fonte = "
SELECT
    SE5.E5_FILORIG  AS FILIAL,
    CAST(SE5.E5_DATA AS DATE) 
                    AS DTMOVIMENTO,
    SE5.E5_TIPO     AS TIPO,
    SE5.E5_NATUREZ  AS NATFIN,
    SED.ED_DESCRIC  AS NATUREZA,
    SE5.E5_HISTOR   AS OBSERVACAO,
    SE5.E5_TIPODOC  AS TIPODOC,
    SE5.E5_PREFIXO  AS PFX,
    SE5.E5_PARCELA  AS PARCELA,
    SE5.E5_CLIFOR   AS CLIFOR,
    SE5.E5_LOJA     AS LOJA,
    SE5.E5_BENEF    AS FORNECEDOR,
    SE5.E5_NUMERO   AS TITULO,
    SE5.E5_MOTBX    AS MOTIVOBAIXA,
    SE5.E5_VALOR - SE5.E5_VLJUROS - SE5.E5_VLMULTA + SE5.E5_VLDESCO 
                    AS VRTITULO,
    SE5.E5_VALOR    AS VRQUITADO
FROM SE5010 SE5
    INNER JOIN SED010 SED ON SED.D_E_L_E_T_ = ''
        AND SED.ED_CODIGO = SE5.E5_NATUREZ
WHERE SE5.D_E_L_E_T_ = ''
    AND SE5.E5_TIPO = 'NCC'
    AND SE5.E5_ORIGEM <> 'MATA103'
    "
in
    Fonte;

shared fMovimentoBancarioNCC = let
  Origem = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query =sqlMovimentoBancarioNCC]),
  #"Tipo de coluna alterado" = Table.TransformColumnTypes(Origem, {{"DTMOVIMENTO", type date}}),
  #"Ano inserido" = Table.AddColumn(#"Tipo de coluna alterado", "Ano", each Date.Year([DTMOVIMENTO]), type nullable number),
  #"Nome do mês inserido" = Table.AddColumn(#"Ano inserido", "Nome do mês", each Date.MonthName([DTMOVIMENTO]), type nullable text),
  #"Texto aparado" = Table.TransformColumns(#"Nome do mês inserido", {{"NATUREZA", each Text.Trim(_), type text}}),
  #"Consultas mescladas" = Table.NestedJoin(#"Texto aparado", {"NATUREZA"}, dGrupoNat, {"Descr.Natur."}, "dGrupoNat", JoinKind.LeftOuter),
  #"Expandido dGrupoNat" = Table.ExpandTableColumn(#"Consultas mescladas", "dGrupoNat", {"Subgrupo"}, {"Subgrupo"}),
  #"Colunas reordenadas" = Table.ReorderColumns(#"Expandido dGrupoNat", {"FILIAL", "DTMOVIMENTO", "TIPO", "NATFIN", "Subgrupo", "NATUREZA", "OBSERVACAO", "TIPODOC", "PFX", "PARCELA", "CLIFOR", "LOJA", "FORNECEDOR", "TITULO", "MOTIVOBAIXA", "VRTITULO", "VRQUITADO", "Ano", "Nome do mês"}),
  #"Texto aparado 1" = Table.TransformColumns(#"Colunas reordenadas", {{"NATFIN", each Text.Trim(_), type text}}),
  #"Coluna condicional inserida" = Table.AddColumn(#"Texto aparado 1", "TIPO DE JUROS", each if [PFX] = "EPJ" then "JUROS DE EMPRESTIMO" else if [NATFIN] = "0406001" then "JUROS DE ANTECIPAÇÃO" else "JUROS DE MORA")
in
  #"Coluna condicional inserida";