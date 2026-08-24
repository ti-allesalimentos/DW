section Section1;

shared sqlSaldoMP = let
    Fonte = "
SELECT 
    SB2.B2_FILIAL   AS FILIAL,
    SB2.B2_COD      AS CODPROD,
    SB2.B2_LOCAL    AS ARMAZEM,
    SB2.B2_QATU     AS QTDATUAL,
    SB2.B2_VATU1    AS VRATUAL,
    SB2.B2_CM1      AS CM
FROM SB2010 SB2
WHERE SB2.D_E_L_E_T_ <> '*' 
	AND SB2.B2_COD LIKE '%MP%'
	AND SB2.B2_QATU > 0
    "
in
    Fonte;

shared fSaldoMP = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlSaldoMP, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlSaldoAtual = let
    Fonte = "
SELECT 
    SB2.B2_FILIAL AS Filial,
    SB1.B1_TIPO AS Tipo,
    SB1.B1_GRUPO AS Grupo,
    SB1.B1_COD AS Codigo,
    SB1.B1_DESC AS Descricao,
    SB1.B1_EMIN AS PontoPedido,
    SB1.B1_ESTSEG AS Seguranca,
    SB1.B1_PE AS Entrega,
    SB1.B1_TIPE AS TipPrazo,
    SB1.B1_LE AS LoteEconom,
    SB1.B1_LM AS LoteMinimo,
	SB2.B2_LOCAL AS armazem,
    SB2.B2_QATU AS Quant
FROM SB1010 AS SB1
INNER JOIN SB2010 AS SB2 ON SB1.B1_COD = SB2.B2_COD
WHERE 
    SB1.D_E_L_E_T_ = '' AND
    SB2.D_E_L_E_T_ = '' AND
	SB1.B1_EMIN <> 0 AND
    SB1.B1_GRUPO <> ''
ORDER BY SB1.B1_COD ASC
    "
in
    Fonte;

shared dSaldoAtual = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlSaldoAtual, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared __STATUS__ = let
    Fonte = if Table.RowCount(Table.Combine({dSaldoAtual, fSaldoMP})) > 0 then DateTime.LocalNow() else "Pendente"
in
    Fonte;