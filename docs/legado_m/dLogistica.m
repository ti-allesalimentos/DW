section Section1;

shared sqlSB1 = let
    Fonte = "
SELECT
    SB1.B1_COD,
    SB1.B1_DESC
FROM SB1010 SB1
WHERE SB1.D_E_L_E_T_ = ''
	AND SB1.B1_COD LIKE '%PA%'
    "
in
    Fonte;

shared dSB1 = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlSB1, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared __STATUS__ = let
    Fonte = if Table.RowCount( Table.Combine({dSB1})) > 0 then DateTime.LocalNow() else "Pendente"
in
    Fonte;