section Section1;

shared __STATUS__ = let
    Fonte = if Table.RowCount(Table.Combine({dContas, dNatFin, dGrupos})) > 0 then DateTime.LocalNow() else "Pendente"
in
    Fonte;

shared sqlNatFin = let
    Fonte = "
SELECT
    SED.ED_CODIGO,
    SED.ED_DESCRIC
FROM SED010 SED
WHERE SED.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared dNatFin = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlNatFin, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared dGrupos = let
    Fonte = Excel.Workbook(File.Contents("\\192.168.67.201\Departamentos$\PUBLICA\T.I\01. BASES\fManual.xlsx"), null, true),
    dGrupos_Table = Fonte{[Item="dGrupos",Kind="Table"]}[Data],
    #"Tipo Alterado" = Table.TransformColumnTypes(dGrupos_Table,{{"CodGrupo", Int64.Type}, {"Grupo", type text}, {"Subtotal", Int64.Type}, {"ORDEM", Int64.Type}})
in
    #"Tipo Alterado";

shared dContas = let
    Fonte = Excel.Workbook(File.Contents("\\192.168.67.201\Departamentos$\PUBLICA\T.I\01. BASES\fManual.xlsx"), null, true),
    dGrupos_Table = Fonte{[Item="dContas",Kind="Table"]}[Data],
    #"Texto Aparado" = Table.TransformColumns(dGrupos_Table,{{"ED_CODIGO", Text.Trim, type text}, {"CodGrupo", Text.Trim, type text}, {"CodSubgrupo", Text.Trim, type text}, {"Subgrupo", Text.Trim, type text}, {"MOVIMENTO", Text.Trim, type text}, {"CodSintetica", Text.Trim, type text}, {"ContaSintetica", Text.Trim, type text}, {"CodAnalitica", Text.Trim, type text}, {"ContaAnalitica", Text.Trim, type text}, {"TIPO DE CONTA", Text.Trim, type text}, {"TIPO DE LANÇAMENTO", Text.Trim, type text}, {"ORDEM TIPO LANÇAMENTO", Text.Trim, type text}})
in
    #"Texto Aparado";