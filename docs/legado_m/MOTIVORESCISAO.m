section Section1;

shared MOTIVORESCISAO = let
  Origem = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [CommandTimeout=#duration(69, 10, 39, 0), Query="SELECT#(lf)SRG.RG_FILIAL AS FILIAL,#(lf)SRG.RG_MAT AS MATRICULA,#(lf)SRA.RA_NOME AS NOME,#(lf)SRG.RG_TIPORES AS MOTRES,#(lf)SUM(SRR.RR_VALOR) AS VALOR, #(lf)SUBSTRING(RCC.RCC_CONTEU,3,30) AS MOTIVO,#(lf)CONVERT(VARCHAR, CONVERT(DATE, SRG.RG_DATADEM, 103), 105) AS DATADEM#(lf)FROM SRG010 SRG#(lf)INNER JOIN SRA010 SRA ON SRA.D_E_L_E_T_ <> '*' AND SRA.RA_FILIAL = SRG.RG_FILIAL AND SRA.RA_MAT = SRG.RG_MAT#(lf)INNER JOIN RCC010 RCC ON RCC.D_E_L_E_T_ <> '*' AND RCC.RCC_CODIGO = 'S043' AND SUBSTRING(RCC.RCC_SEQUEN,2,2) = SRG.RG_TIPORES#(lf)INNER JOIN SRR010 SRR ON SRR.D_E_L_E_T_ <> '*' AND SRR.RR_FILIAL = SRG.RG_FILIAL AND SRR.RR_MAT = SRG.RG_MAT#(lf)WHERE SRG.D_E_L_E_T_ <> '*'#(lf)AND SRR.RR_ROTEIR = 'RES'#(lf)AND SRR.RR_PD IN ('528', 'A26', 'A28', 'A29', 'A77')#(lf)GROUP BY#(lf)SRG.RG_FILIAL,#(lf)SRG.RG_MAT,#(lf)SRA.RA_NOME,#(lf)SRG.RG_TIPORES,#(lf)RCC.RCC_CONTEU,#(lf)SRG.RG_DATADEM"]),
  #"Tipo de coluna alterado" = Table.TransformColumnTypes(Origem, {{"DATADEM", type date}})
in
  #"Tipo de coluna alterado";

shared __STATUS__ = let
    Fonte = if Table.RowCount(Table.Combine({MOTIVORESCISAO})) > 0 then DateTime.LocalNow() else "Pendente"
in
    Fonte;