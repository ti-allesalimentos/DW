section Section1;

shared sqlVendedores = let
    Fonte = "  
SELECT   
    SA3.A3_COD      AS _CODVEND,
    SA3.A3_NOME     AS _NOMEVEND,
    SA3.A3_GEREN    AS _GERENVEND,
    SA3.A3_COMIS / 100  
                    AS _COMISVEND,
    G.A3_NOME       AS _NOMEGERENTE,
    CASE    
        WHEN SA3.A3_GEREN = '000004' AND SA3.A3_COD <> '000026' THEN 0.01
        ELSE G.A3_COMIS / 100
    END             AS _COMISGERENTE,
    SA3.A3_NREDUZ   AS _ALIAS
FROM SA3010 SA3
LEFT JOIN SA3010 G 
    ON G.D_E_L_E_T_ = '' 
    AND G.A3_COD = SA3.A3_GEREN
WHERE SA3.D_E_L_E_T_ = '' 
    "
in
    Fonte;

shared dVendedores = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlVendedores, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared dMetasVend = let
    Fonte = Excel.Workbook(File.Contents("\\192.168.67.201\Departamentos$\PUBLICA\T.I\01. BASES\fManual.xlsx"), null, true),
    dMetasVend_Table = Fonte{[Item="dMetasVend",Kind="Table"]}[Data],
    #"Texto Aparado" = Table.TransformColumns(dMetasVend_Table,{{"Produto", Text.Trim, type text}, {"VendedorDescrição", Text.Trim, type text}, {"Vendedor", Text.Trim, type text}, {"Gerente", Text.Trim, type text}})
in
    #"Texto Aparado";

shared __STATUS__ = let
    Fonte = if Table.RowCount(Table.Combine({dMetasVend, dVendedores})) > 0 then DateTime.LocalNow() else "Pendente"
in
    Fonte;