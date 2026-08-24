section Section1;

shared __STATUS__ = let
    Fonte = if Table.RowCount(Table.Combine({dFuncionarios, fMovimentosHistorico, fMovimentosPeriodicos, dVerbas, fMarcações, fControleAusencias, fApontamentos, fBancodeHoras, fEventosAbonados, fMotivoRescisão, fApontamentosHist})) > 0 then DateTime.LocalNow() else "Pendente"
in
    Fonte;

shared sqldFuncionarios = let
    Fonte = "
SELECT 
SRA.RA_FILIAL AS FILIAL,
SRA.RA_MAT AS MATRICULA,
SRA.RA_NOME AS NOME,
SRA.RA_SEXO AS SEXO,
CAST(SRA.RA_NASC AS DATE) AS DTNASCIMENTO,
CAST(SRA.RA_ADMISSA AS DATE) AS ADMISSAO,
CAST(SRA.RA_DEMISSA AS DATE) AS DEMISSÃO,
SRA.RA_SITFOLH AS SITUAÇÃO,
SRA.RA_CC AS ""CENTRO DE CUSTO"",
SRA.RA_CODFUNC AS FUNÇÃO,
SRA.RA_SALARIO AS SALARIO,
SRA.RA_HRSMES AS HRJORNADA,
CASE
    WHEN SRA.RA_ADCPERI = '2' THEN '0.30'
    ELSE '0.00'
    END PERICULOSIDADE,
CASE 
    WHEN SRA.RA_ADCINS = '1' THEN '0.00'
    WHEN SRA.RA_ADCINS = '2' THEN '0.10'
    WHEN SRA.RA_ADCINS = '3' THEN '0.20'
    WHEN SRA.RA_ADCINS = '4' THEN '0.30'
    ELSE NULL
END AS INSALUBRIDADE
FROM SRA010 SRA
WHERE SRA.D_E_L_E_T_ = '' "
in
    Fonte;

shared dFuncionarios = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqldFuncionarios, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlfMovimentosPeriodicos = let
    Fonte = "
SELECT * FROM SRC010 SRC
WHERE SRC.D_E_L_E_T_ = '' "
in
    Fonte;

shared fMovimentosPeriodicos = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlfMovimentosPeriodicos, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlfMovimentosHistorico = let
    Fonte = "
SELECT * FROM SRD010 SRD
WHERE SRD.D_E_L_E_T_ = '' "
in
    Fonte;

shared fMovimentosHistorico = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlfMovimentosHistorico, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqldVerbas = let
    Fonte = "
SELECT * FROM SRV010 SRV
WHERE SRV.D_E_L_E_T_ = '' "
in
    Fonte;

shared dVerbas = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqldVerbas, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlfMarcações = let
    Fonte = "
SELECT * FROM SP8010 SP8
WHERE SP8.D_E_L_E_T_ = '' "
in
    Fonte;

shared fMarcações = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlfMarcações, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlfControleAusencias = let
    Fonte = "
SELECT * FROM SR8010 SR8
WHERE SR8.D_E_L_E_T_ = '' "
in
    Fonte;

shared fControleAusencias = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlfControleAusencias, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlfApontamentos = let
    Fonte = "
SELECT * FROM SPC010 SPC
WHERE SPC.D_E_L_E_T_ = '' "
in
    Fonte;

shared fApontamentos = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlfApontamentos, CommandTimeout=#duration(69, 10, 39, 0)]),
    #"Tipo Alterado" = Table.TransformColumnTypes(Fonte,{{"PC_DATA", type date}})
in
    #"Tipo Alterado";

shared sqlfBancodeHoras = let
    Fonte = "
SELECT * FROM SPI010 SPI
WHERE SPI.D_E_L_E_T_ = '' "
in
    Fonte;

shared fBancodeHoras = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlfBancodeHoras, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlEventosAbonados = let
    Fonte = "
SELECT * FROM SPK010 SPK
WHERE SPK.D_E_L_E_T_ = ''
 "
in
    Fonte;

shared fEventosAbonados = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlEventosAbonados, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlfMotivoRescisão = let
    Fonte = "
SELECT
SRG.RG_FILIAL AS FILIAL,
SRG.RG_MAT AS MATRICULA,
SRA.RA_NOME AS NOME,
SRG.RG_TIPORES AS MOTRES,
SUBSTRING(RCC.RCC_CONTEU,3,30) AS MOTIVO,
CONVERT(VARCHAR, CONVERT(DATE, SRG.RG_DATADEM, 103), 105) AS DATADEM
FROM SRG010 SRG
INNER JOIN SRA010 SRA ON SRA.D_E_L_E_T_ <> '*' AND SRA.RA_FILIAL = SRG.RG_FILIAL AND SRA.RA_MAT = SRG.RG_MAT
INNER JOIN RCC010 RCC ON RCC.D_E_L_E_T_ <> '*' AND RCC.RCC_CODIGO = 'S043' AND SUBSTRING(RCC.RCC_SEQUEN,2,2) = SRG.RG_TIPORES
WHERE SRG.D_E_L_E_T_ <> '*'
 "
in
    Fonte;

shared fMotivoRescisão = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlfMotivoRescisão, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlfApontamentosHist = let
    Fonte = "
SELECT * FROM SPH010 SPH
WHERE SPH.D_E_L_E_T_ = '' "
in
    Fonte;

shared fApontamentosHist = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlfApontamentosHist, CommandTimeout=#duration(69, 10, 39, 0)]),
    #"Tipo Alterado" = Table.TransformColumnTypes(Fonte,{{"PH_DATA", type date}})
in
    #"Tipo Alterado";

shared sqdDuplaFuncao = let
    Fonte = "
SELECT
RG1.RG1_FILIAL AS FILIAL,
RG1.RG1_MAT AS MATRICULA
FROM RG1010 RG1
WHERE RG1.D_E_L_E_T_ = ''
AND RG1.RG1_PD = '174'
AND RG1.RG1_DFIMPG = '' "
in
    Fonte;

shared dDuplaFuncao = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqdDuplaFuncao, CommandTimeout=#duration(69, 10, 39, 0)]),
    #"Coluna Mesclada Inserida" = Table.AddColumn(Fonte, "CHAVEFILMAT", each Text.Combine({[FILIAL], [MATRICULA]}, "-"), type text)
in
    #"Coluna Mesclada Inserida";

shared sqlHistoricoSalarial = let
    Fonte = "
SELECT
SR3.R3_FILIAL AS FILIAL,
SR3.R3_MAT AS MATRICULA,
SR3.R3_DATA AS DATA_ALT,
SR3.R3_VALOR AS VALOR
FROM SR3010 SR3
WHERE SR3.D_E_L_E_T_ = ''
AND SR3.R3_DATA > '20231201'
AND SR3.R3_DESCPD = 'SALARIO BASE'
"
in
    Fonte;

shared fHistoricoSalarial = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlHistoricoSalarial, CommandTimeout=#duration(69, 10, 39, 0)]),
    #"Coluna Mesclada Inserida" = Table.AddColumn(Fonte, "CHAVEFILMAT", each Text.Combine({[FILIAL], [MATRICULA]}, "-"), type text),
    #"Tipo Alterado" = Table.TransformColumnTypes(#"Coluna Mesclada Inserida",{{"DATA_ALT", type date}})
in
    #"Tipo Alterado";