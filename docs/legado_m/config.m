section Section1;

shared atualiz = let
    Fonte = atualizador,
    programacao_Table = Fonte{[Item="programacao",Kind="Table"]}[Data],
    #"Tipo Alterado" = Table.TransformColumnTypes(programacao_Table,{{"arquivo", type text}, {"padraoAtu", type text}, {"atualiza", Int64.Type}, {"lestAtu", type datetime}, {"proxAtu", type datetime}})
in
    #"Tipo Alterado";

shared atualizVerific = let
    Fonte = Folder.Files("\\192.168.67.201\Departamentos$\PUBLICA\T.I\01. BASES"),
    #"Linhas Filtradas" = Table.SelectRows(Fonte, each ([Attributes][Hidden] = true)),
    #"ArquivosLimpo" = Table.TransformColumns(#"Linhas Filtradas", {{"Name", each Text.AfterDelimiter(_, "~$"), type text}}),
    #"Outras Colunas Removidas" = Table.SelectColumns(ArquivosLimpo,{"Name"})
in
    #"Outras Colunas Removidas";

shared #"01  BASES" = let
    Fonte = Folder.Files("\\192.168.67.201\Departamentos$\PUBLICA\T.I\01. BASES"),
    #"Linhas Filtradas" = Table.SelectRows(Fonte, each ([Name] = "atualizador.xlsm" or [Name] = "~$atualizador.xlsm"))
in
    #"Linhas Filtradas";

shared log = let
    Fonte = atualizador,
    log_execucao_Sheet = Fonte{[Item="log_execucao",Kind="Sheet"]}[Data],
    #"Cabeçalhos Promovidos" = Table.PromoteHeaders(log_execucao_Sheet, [PromoteAllScalars=true]),
    #"Tipo Alterado" = Table.TransformColumnTypes(#"Cabeçalhos Promovidos",{{"DataHora", type datetime}}),
    // #"Dividir Coluna por Delimitador" = Table.SplitColumn(Table.TransformColumnTypes(#"Tipo Alterado", {{"Msg", type text}}, "pt-BR"), "Msg", Splitter.SplitTextByEachDelimiter({"] "}, QuoteStyle.Csv, false), {"Tipo", "Msg"}),
    // #"Texto Extraído Após o Delimitador" = Table.TransformColumns(#"Dividir Coluna por Delimitador", {{"Tipo", each Text.AfterDelimiter(_, "["), type text}}),
    #"Texto Aparado" = Table.TransformColumns(#"Tipo Alterado",{{"Arquivo", Text.Trim, type text}, {"Tipo", Text.Trim, type text}, {"Msg", Text.Trim, type text}}),
    #"Valor Substituído" = Table.ReplaceValue(#"Texto Aparado","INFO","0",Replacer.ReplaceText,{"Tipo"}),
    #"Valor Substituído1" = Table.ReplaceValue(#"Valor Substituído","ERROR","2",Replacer.ReplaceText,{"Tipo"}),
    #"Valor Substituído2" = Table.ReplaceValue(#"Valor Substituído1","WARNING","1",Replacer.ReplaceText,{"Tipo"}),
    #"Tipo Alterado1" = Table.TransformColumnTypes(#"Valor Substituído2",{{"Tipo", Int64.Type}})
in
    #"Tipo Alterado1";

shared allConsult = let
    Fonte = Folder.Files("\\192.168.67.201\Departamentos$\PUBLICA\T.I\01. BASES"),
    #"Linhas Filtradas" = Table.SelectRows(Fonte, each [Attributes] <> null and not[Attributes][Hidden]),
    #"Linhas Filtradas1" = Table.SelectRows(#"Linhas Filtradas", each ([Name] <> "atualizador.xlsm" and [Name] <> "config.xlsm" and [Name] <> "fManual.xlsx" and not Text.EndsWith([Name],".txt"))),
    #"Outras Colunas Removidas" = Table.SelectColumns(#"Linhas Filtradas1",{"Content", "Name", "Date modified"}),
    #"Personalização Adicionada" = Table.AddColumn(#"Outras Colunas Removidas", "Personalizar", each Excel.Workbook([Content])),
    #"Personalizar Expandido" = Table.ExpandTableColumn(#"Personalização Adicionada", "Personalizar", {"Name", "Data", "Item", "Kind", "Hidden"}, {"Personalizar.Name", "Personalizar.Data", "Personalizar.Item", "Personalizar.Kind", "Personalizar.Hidden"}),
    #"Linhas Filtradas2" = Table.SelectRows(#"Personalizar Expandido", each ([Personalizar.Kind] = "Table")),
    #"Personalização Adicionada1" = Table.AddColumn(#"Linhas Filtradas2", "Colunas", each Table.ColumnNames([Personalizar.Data])),
    #"Coluna Condicional Adicionada" = Table.AddColumn(#"Personalização Adicionada1", "PreStatus", each if [Personalizar.Item] = "__STATUS__" then [Personalizar.Data] else null),
    #"PreStatus Expandido" = Table.ExpandTableColumn(#"Coluna Condicional Adicionada", "PreStatus", {"__STATUS__"}, {"__STATUS__"}),
    #"Colunas Expandido" = Table.ExpandListColumn(#"PreStatus Expandido", "Colunas"),
    #"Outras Colunas Removidas1" = Table.SelectColumns(#"Colunas Expandido",{"Name", "Personalizar.Item", "Colunas", "__STATUS__"}),
    #"Texto Aparado" = Table.TransformColumns(#"Outras Colunas Removidas1",{{"Colunas", Text.Trim, type text}, {"Personalizar.Item", Text.Trim, type text}, {"Name", Text.Trim, type text}}),
    #"Tipo Alterado" = Table.TransformColumnTypes(#"Texto Aparado",{{"__STATUS__", type datetime}})
in
    #"Tipo Alterado";

shared Info = let
    Fonte = atualizador,
    Aux_Table = Fonte{[Item="Aux",Kind="Table"]}[Data],
    #"Tipo Alterado2" = Table.TransformColumnTypes(Aux_Table,{{"Desc", type text}, {"Value", type any}})
in
    #"Tipo Alterado2";

shared InfoSatus = let
    Fonte = Folder.Files("\\192.168.67.201\Departamentos$\PUBLICA\T.I\01. BASES"),
    #"Linhas Filtradas" = Table.SelectRows(Fonte, each [Attributes] <> null and not[Attributes][Hidden]),
    #"Linhas Filtradas1" = Table.SelectRows(#"Linhas Filtradas", each ([Name] <> "atualizador.xlsm" and [Name] <> "config.xlsm" and [Name] <> "fManual.xlsx" and not Text.EndsWith([Name],".txt"))),
    #"Outras Colunas Removidas" = Table.SelectColumns(#"Linhas Filtradas1",{"Content", "Name", "Date modified"}),
    #"Personalização Adicionada" = Table.AddColumn(#"Outras Colunas Removidas", "Personalizar", each Excel.Workbook([Content])),
    #"Personalizar Expandido" = Table.ExpandTableColumn(#"Personalização Adicionada", "Personalizar", {"Name", "Data", "Item", "Kind", "Hidden"}, {"Personalizar.Name", "Personalizar.Data", "Personalizar.Item", "Personalizar.Kind", "Personalizar.Hidden"}),
    #"Linhas Filtradas2" = Table.SelectRows(#"Personalizar Expandido", each ([Personalizar.Kind] = "Table" and [Personalizar.Item] = "__STATUS__")),
    #"Personalizar.Data Expandido" = Table.ExpandTableColumn(#"Linhas Filtradas2", "Personalizar.Data", {"__STATUS__"}, {"__STATUS__"}),
    #"Outras Colunas Removidas1" = Table.SelectColumns(#"Personalizar.Data Expandido",{"Name", "Personalizar.Item", "__STATUS__"})
in
    #"Outras Colunas Removidas1";

shared InfoSQL = let
    Fonte = Folder.Files("\\192.168.67.201\Departamentos$\PUBLICA\T.I\01. BASES"),
    #"Linhas Filtradas" = Table.SelectRows(Fonte, each [Attributes] <> null and not[Attributes][Hidden]),
    #"Linhas Filtradas1" = Table.SelectRows(#"Linhas Filtradas", each ([Name] <> "atualizador.xlsm" and [Name] <> "config.xlsm" and [Name] <> "fManual.xlsx" and not Text.EndsWith([Name],".txt"))),
    #"Outras Colunas Removidas" = Table.SelectColumns(#"Linhas Filtradas1",{"Content", "Name", "Date modified"}),
    #"Personalização Adicionada" = Table.AddColumn(#"Outras Colunas Removidas", "Personalizar", each Excel.Workbook([Content])),
    #"Personalizar Expandido" = Table.ExpandTableColumn(#"Personalização Adicionada", "Personalizar", {"Name", "Data", "Item", "Kind", "Hidden"}, {"Personalizar.Name", "Personalizar.Data", "Personalizar.Item", "Personalizar.Kind", "Personalizar.Hidden"}),
    #"Linhas Filtradas2" = Table.SelectRows(#"Personalizar Expandido", each ([Personalizar.Kind] = "Table" and [Personalizar.Item] = "__SQL__")),
    #"Personalizar.Data Expandido" = Table.ExpandTableColumn(#"Linhas Filtradas2", "Personalizar.Data", {"Name", "Value"}, {"NameConsult", "Value"}),
    #"Outras Colunas Removidas1" = Table.SelectColumns(#"Personalizar.Data Expandido",{"Name", "Personalizar.Item", "NameConsult", "Value"})
in
    #"Outras Colunas Removidas1";

shared atualizador = let
    Fonte = Folder.Files("\\192.168.67.201\Departamentos$\PUBLICA\T.I\01. BASES"),
    #"Linhas Filtradas" = Table.SelectRows(Fonte, each [Attributes] <> null and Text.StartsWith([Name], "atualizador")),
    #"Linhas Classificadas" = Table.Sort(#"Linhas Filtradas",{{"Name", Order.Ascending}}),
    #"Última Linhas Mantidas" = Table.LastN(#"Linhas Classificadas", 1),
    planilha = #"Última Linhas Mantidas"{0}[Content],
    #"Pasta de Trabalho Importada do Excel" = Excel.Workbook(planilha)
in
    #"Pasta de Trabalho Importada do Excel";