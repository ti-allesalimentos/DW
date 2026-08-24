section Section1;

shared programacao = let
    Fonte = Excel.Workbook(File.Contents("\\192.168.67.201\Departamentos$\PUBLICA\T.I\01. BASES\config.xlsm"), null, true),
    programacao_Table = Fonte{[Item="programacao",Kind="Table"]}[Data],
    #"Tipo Alterado" = Table.TransformColumnTypes(programacao_Table,{{"arquivo", type text}, {"padraoAtu", type text}, {"atualiza", Int64.Type}, {"lestAtu", type datetime}, {"proxAtu", type datetime}, {"prevista", type datetime}})
in
    #"Tipo Alterado";