section Section1;

shared sqlProducao = let
    Fonte = "
SELECT DISTINCT
    SH6.H6_FILIAL   AS FILIAL,
    SH6.H6_OP       AS OP,
    SH6.H6_PRODUTO  AS CODPROD,
    SB1.B1_DESC     AS PRODUTO,
    SH6.H6_OPERAC   AS CODOPERAC,
    CASE 
        WHEN SH6.H6_OPERAC = '1' THEN 'PRODUCAO HAMBURGUER'
        WHEN SH6.H6_OPERAC = 'AP' THEN 'PRODUCAO ALMONDEGA'
        ELSE COALESCE(SG2.G2_DESCRI, 'DESCONHECIDO') 
    END             AS OPERACAO,
    SH6.H6_RECURSO  AS REC,
    CAST(SH6.H6_DTPROD AS DATE)
                    AS DTPROD,
    SH6.H6_HORAINI  AS HORAINI,
    SH6.H6_HORAFIN  AS HORAFIM,
    SH6.H6_QTDPROD  AS QTDPRODUZIDA,
    SB1.B1_UM       AS UM,
    SH6.H6_LOTECTL  AS LOTE,
    SH6.H6_QTDPRO2  AS QTDPRODUZIDACX,
    SH6.H6_IDENT    AS IDENTIFICADOR
FROM SH6010 SH6
INNER JOIN SB1010 SB1 ON SB1.D_E_L_E_T_ = '' 
    AND SB1.B1_COD = SH6.H6_PRODUTO
LEFT JOIN SG2010 SG2 ON SG2.D_E_L_E_T_ = '' 
    AND SG2.G2_OPERAC = SH6.H6_OPERAC
WHERE SH6.D_E_L_E_T_ = ''

    "
in
    Fonte;

shared fProducao = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlProducao, CommandTimeout=#duration(69, 10, 39, 0)]),
  #"Tipo de coluna alterado" = Table.TransformColumnTypes(Fonte, {{"DTPROD", type date}, {"HORAFIM", type time}, {"HORAINI", type time}})
in
  #"Tipo de coluna alterado";

shared sqlLancamentos = let
    Fonte = "
SELECT DISTINCT
    SD3.D3_FILIAL   AS FILIAL,
    CAST(SD3.D3_EMISSAO AS DATE)
                    AS EMISSAO,
    SD3.D3_TM       AS TM,
    SD3.D3_COD      AS CODPROD,
    SB1.B1_DESC     AS PRODUTO,
    SD3.D3_LOCAL    AS ARMAZÉM,
    SD3.D3_LOCALIZ  AS ENDEREÇO,
    SD3.D3_HORA     AS HORARIO,
    SD3.D3_UM       AS UM,
    SD3.D3_QUANT    AS QTD,
    SD3.D3_LOTECTL  AS LOTE,
    SD3.D3_OP       AS OP,
    SD3.D3_NUMSEQ   AS ID,
    SD3.D3_TIPO     AS TIPO,
    SD3.D3_USUARIO  AS USUARIO,
    CASE
        WHEN SD3.D3_TIPO IN ('MP', 'SP', 'II') THEN 'MASSA'
        ELSE 'INSUMOS'
    END AS CLASSIFICACAO
FROM SD3010 SD3
    INNER JOIN SB1010 SB1 ON SB1.D_E_L_E_T_ = ''
        AND SB1.B1_COD = SD3.D3_COD
WHERE SD3.D_E_L_E_T_ = ''
    AND SD3.D3_OP <> ''
    AND SD3.D3_OP NOT LIKE '%OS%'
    AND SD3.D3_FILIAL = '01004'
    AND SD3.D3_TIPO <> 'MO'
    AND SD3.D3_TIPO <> 'PA'
    AND SD3.D3_COD <> 'MANUTENCAO'
    AND SD3.D3_TM > 500
    "
in
    Fonte;

shared fLancamentos = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlLancamentos, CommandTimeout=#duration(69, 10, 39, 0)]),
  #"Tipo de coluna alterado" = Table.TransformColumnTypes(Fonte, {{"EMISSAO", type date}, {"HORARIO", type time}})
in
  #"Tipo de coluna alterado";

shared sqlOP = let
    Fonte = "
SELECT
    SC2.C2_FILIAL   AS FILIAL,
    SC2.C2_NUM      AS OP,
    SC2.C2_ITEM     AS ITEM,
    SC2.C2_SEQUEN   AS SEQ,
    SC2.C2_PRODUTO  AS CODPRODU,
    SB1.B1_DESC     AS PRODUTO,
    SC2.C2_QUANT    AS QTD,
    SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN
                    AS Personalizar
FROM SC2010 SC2
    INNER JOIN SB1010 SB1 ON SB1.D_E_L_E_T_ = ''
        AND SB1.B1_COD = SC2.C2_PRODUTO
WHERE SC2.D_E_L_E_T_ = ''
    AND SC2.C2_ITEM <> 'OS'
    AND SC2.C2_FILIAL = '01004'
    "
in
    Fonte;

shared dOP = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlOP, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlIndiretosLanc = let
    Fonte = "
SELECT
    SD3.D3_FILIAL   AS FILIAL,
    SD3.D3_TM       AS TM,
    SD3.D3_COD      AS CODPROD,
    SD3.D3_UM       AS UM,
    SD3.D3_QUANT    AS QTD,
    SD3.D3_CC       AS CCUSTO,
    CAST(SD3.D3_EMISSAO AS DATE)
                    AS EMISSAO
FROM SD3010 SD3
WHERE SD3.D_E_L_E_T_ = ''
    AND SD3.D3_OP = ''
    AND SD3.D3_TM = '505'
    "
in
    Fonte;

shared fIndiretosLanc = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlIndiretosLanc, CommandTimeout=#duration(69, 10, 39, 0)]),
  #"Tipo de coluna alterado" = Table.TransformColumnTypes(Fonte, {{"EMISSAO", type date}})
in
  #"Tipo de coluna alterado";

shared sqlStatusOP = let
    Fonte = "
SELECT
    SC2.C2_FILIAL   AS FILIAL,
    SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN
                    AS OP,
    SC2.C2_PRODUTO  AS CODPROD,
    SB1.B1_DESC     AS PRODUTO,
    SC2.C2_QUANT    AS QTDPREVISTA,
    SC2.C2_UM       AS UM,
    CAST(SC2.C2_DATPRI AS DATE)
                    AS DTPREVISTAINICIO,
    CAST(SC2.C2_DATPRF AS DATE)
                    AS DTPREVISTAFIM,
    CAST(SC2.C2_EMISSAO AS DATE)
                    AS DTEMISSAO,
    SC2.C2_QUJE     AS QTDPRODUZIDA,
    CAST(SC2.C2_DATRF AS DATE)
                    AS DTFECHAMENTO
FROM SC2010 SC2
    INNER JOIN SB1010 SB1 ON SB1.D_E_L_E_T_ = ''
        AND SB1.B1_COD = SC2.C2_PRODUTO
WHERE SC2.D_E_L_E_T_ = ''
    AND SC2.C2_ITEM <> 'OS'
    "
in
    Fonte;

shared dStatusOP = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlStatusOP, CommandTimeout=#duration(69, 10, 39, 0)]),
  #"Tipo de coluna alterado" = Table.TransformColumnTypes(Fonte, {{"DTPREVISTAFIM", type date}, {"DTEMISSAO", type date}, {"DTPREVISTAINICIO", type date}, {"DTFECHAMENTO", type date}})
in
  #"Tipo de coluna alterado";

shared sqlReprocessos = let
    Fonte = "
SELECT DISTINCT
    SD3.D3_FILIAL   AS FILIAL,
    CAST(SD3.D3_EMISSAO AS DATE)
                    AS EMISSAO,
    SD3.D3_TM       AS TM,
    SD3.D3_COD      AS CODPROD,
    SB1.B1_DESC     AS PRODUTO,
    SD3.D3_LOCAL    AS ARMAZÉM,
    SD3.D3_LOCALIZ  AS ENDEREÇO,
    SD3.D3_HORA     AS HORARIO,
    SD3.D3_UM       AS UM,
    SD3.D3_QUANT    AS QTD,
    SD3.D3_LOTECTL  AS LOTE,
    SD3.D3_OP       AS OP,
    SD3.D3_NUMSEQ   AS ID,
    SD3.D3_TIPO     AS TIPO,
    SD3.D3_USUARIO  AS USUARIO
FROM SD3010 SD3
    INNER JOIN SB1010 SB1 ON SB1.D_E_L_E_T_ = ''
        AND SB1.B1_COD = SD3.D3_COD
WHERE SD3.D_E_L_E_T_ = ''
    AND SD3.D3_TM = '200'
    AND SD3.D3_OP <> ''
    "
in
    Fonte;

shared fReprocessos = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlReprocessos, CommandTimeout=#duration(69, 10, 39, 0)]),
  #"Tipo de coluna alterado" = Table.TransformColumnTypes(Fonte, {{"EMISSAO", type date}}),
  #"Texto aparado" = Table.TransformColumns(#"Tipo de coluna alterado", {{"OP", each Text.Trim(_), type text}}),
  #"Consultas mescladas" = Table.NestedJoin(#"Texto aparado", {"OP"}, dOP, {"Personalizar"}, "dOP", JoinKind.LeftOuter),
  #"Expandido dOP" = Table.ExpandTableColumn(#"Consultas mescladas", "dOP", {"PRODUTO"}, {"PRODUTOPAI"}),
  #"Colunas reordenadas" = Table.ReorderColumns(#"Expandido dOP", {"FILIAL", "EMISSAO", "PRODUTOPAI", "TM", "CODPROD", "PRODUTO", "ARMAZÉM", "ENDEREÇO", "HORARIO", "UM", "QTD", "LOTE", "OP", "ID", "TIPO", "USUARIO"}),
  #"Nome do mês inserido" = Table.AddColumn(#"Colunas reordenadas", "Nome do mês", each Date.MonthName([EMISSAO]), type nullable text),
  #"Texto aparado 1" = Table.TransformColumns(#"Nome do mês inserido", {{"PRODUTOPAI", each Text.Trim(_), type nullable text}})
in
  #"Texto aparado 1";

shared __STATUS__ = let
    Fonte = if Table.RowCount(Table.Combine({fReprocessos, fProducao, fLancamentos, dOP, fIndiretosLanc, dStatusOP, fReprocessos})) > 0 then DateTime.LocalNow() else "Pendente"
in
    Fonte;