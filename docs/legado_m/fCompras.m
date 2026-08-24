section Section1;

shared sqlSaldoFisico = let
    Fonte = "
SELECT 
    SB2.B2_FILIAL, 
    SUM(SB2.B2_QATU) AS B2_QATU, 
    SB2.B2_COD
FROM 
    SB2010 SB2
WHERE 
    SB2.D_E_L_E_T_ = '' 
    AND SB2.B2_LOCAL IN ('EP', 'ES', 'MP', 'TE', '03', 'MN', 'ST')
GROUP BY
    SB2.B2_FILIAL, 
    SB2.B2_COD
    "
in
    Fonte;

shared fSaldoFisico = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlSaldoFisico, CommandTimeout=#duration(69, 10, 39, 0)]),
    #"Linhas Filtradas" = Table.SelectRows(Fonte, each [B2_QATU] <> 0)
in
    #"Linhas Filtradas";

shared sqlPedCompra = let
    Fonte = "

SELECT
    CASE
        /* X Vermelho - Rejeitado */
        WHEN SC7.C7_CONAPRO = 'R'
            THEN 'Rejeitado'
 
        /* Azul - Bloqueado / aguardando aprovacao */
        WHEN SC7.C7_CONAPRO = 'B'
             AND SC7.C7_QUJE < SC7.C7_QUANT
            THEN 'Em aprovacao'
 
        /* Vermelho - Entregue totalmente */
        WHEN SC7.C7_QUJE >= SC7.C7_QUANT
            THEN 'Recebido'
 
        /* Branco - Pedido de Contrato (contrato + residuo preenchidos) */
        WHEN LTRIM(RTRIM(ISNULL(SC7.C7_CONTRA, ''))) <> ''
             AND LTRIM(RTRIM(ISNULL(SC7.C7_RESIDUO, ''))) <> ''
            THEN 'Pedido de Contrato'
 
        /* Cinza - Residuo eliminado */
        WHEN LTRIM(RTRIM(ISNULL(SC7.C7_RESIDUO, ''))) <> ''
            THEN 'PC Eliminado por Residuo'
 
        /* Laranja - Nota de entrada pendente de classificacao */
        WHEN SC7.C7_QTDACLA > 0
            THEN 'Em recebimento'
 
        /* Amarelo - Entrega parcial */
        WHEN SC7.C7_QUJE <> 0
             AND SC7.C7_QUJE < SC7.C7_QUANT
            THEN 'Recebido parcial'
 
        /* Preto - Autorizacao de Entrega (tipo diferente de Pedido) */
        WHEN SC7.C7_TIPO <> '1'
            THEN 'Autorizacao de Entrega'
 
        /* Verde - Pedido em aberto / aprovado, sem nenhuma entrega */
        WHEN SC7.C7_QUJE    = 0
             AND SC7.C7_QTDACLA = 0
             AND SC7.C7_CONAPRO <> 'B'
             AND SC7.C7_TIPO     = '1'
             AND LTRIM(RTRIM(ISNULL(SC7.C7_RESIDUO, ''))) = ''
            THEN 'Aprovado'
 
        ELSE 'Status Indefinido'
END AS ""STATUS PEDIDO"",
    SC7.C7_FILIAL AS FILIAL,
    SC7.C7_FORNECE AS FORNECEDOR, 
    SC7.C7_LOJA AS LOJA,
    SC7.C7_COND AS ""CONDICAO PAGAMENTO"",
    SE4.E4_DESCRI AS ""DESCRICAO CONDICAO"",
    SC7.C7_NUM AS PEDIDO,
    SC7.C7_ITEM AS ITEM,
    SC7.C7_PRODUTO AS PRODUTO,
    SC7.C7_DESCRI AS DESCRICAO,
    SC7.C7_UM AS UNIDADE,
    SC7.C7_QUANT AS QUANTIDADE,
    SC7.C7_QUJE AS QUANT_ENTREGUE,
    SC7.C7_PRECO AS ""VALOR UNI"",
    SC7.C7_TOTAL AS ""VALOR TOTAL"",
    SC7.C7_ENCER AS STATUS,
    USR7.USR_NOME AS COMPRADOR,
    SC1.C1_NUM AS ""SOLICITAÇÃO"",
    USR1.USR_NOME AS SOLICITANTE,
    CONVERT(VARCHAR, CAST(SC7.C7_EMISSAO AS DATE), 103) AS EMISSAO,
    CAST(SC7.C7_DINICOM AS DATE) AS ""INICIO DA COMPRA"",
    CAST(SC7.C7_DINITRA AS DATE) AS ""INICIO DE TRANSITO"",
    CAST(SC7.C7_DATPRF AS DATE) AS 	""DATA ENTREGUE"",
    SC7.C7_RESIDUO,
    SC7.C7_CONAPRO,
    SC7.C7_CLVL AS ""Centro de Resultado""
FROM SC7010 SC7
    LEFT JOIN SC1010 SC1 ON SC1.D_E_L_E_T_ = ''
        AND SC7.C7_FILIAL   = SC1.C1_FILIAL 
        AND SC7.C7_NUMSC    = SC1.C1_NUM 
        AND SC7.C7_ITEMSC   = SC1.C1_ITEM
    LEFT JOIN SYS_USR USR7 ON USR7.D_E_L_E_T_ = '' 
        AND SC7.C7_USER     = USR7.USR_ID
    LEFT JOIN SYS_USR USR1 ON USR1.D_E_L_E_T_ = '' 
        AND SC1.C1_USER     = USR1.USR_ID
    LEFT JOIN SE4010 SE4 ON SE4.D_E_L_E_T_ = '' 
        AND SE4.E4_CODIGO   = SC7.C7_COND
WHERE
    SC7.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared fPedCompra = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlPedCompra, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlDevolucoes = let
    Fonte = "SELECT#(cr)#(lf)    SF1.F1_FILIAL AS FILIAL,#(cr)#(lf)    SF1.F1_DOC AS NF,#(cr)#(lf)    SF1.F1_SERIE AS SERIE,#(cr)#(lf)    SD1.D1_ITEM AS ITEM,#(cr)#(lf)    SD1.D1_COD AS CODIGO,#(cr)#(lf)    SD1.D1_TOTAL,#(cr)#(lf)    SF1.F1_FORNECE AS FORNEC_CLIEN_CODIGO,#(cr)#(lf)    SF1.F1_LOJA AS FORNEC_CLIEN_LOJA,#(cr)#(lf)    COALESCE(SA2.A2_NOME, SA1.A1_NOME) AS FORNEC_CLIEN_NOME,#(cr)#(lf)    CONVERT(VARCHAR, CAST(SF1.F1_EMISSAO AS DATE), 103) AS EMISSAO#(cr)#(lf)FROM SF1010 SF1#(cr)#(lf)INNER JOIN SD1010 SD1 ON SD1.D_E_L_E_T_ <> '*' AND SF1.F1_DOC = SD1.D1_DOC AND SF1.F1_SERIE = SD1.D1_SERIE#(cr)#(lf)LEFT JOIN SA2010 SA2 ON SA2.D_E_L_E_T_ <> '*' AND SF1.F1_FORNECE = SA2.A2_COD AND SF1.F1_LOJA = SA2.A2_LOJA#(cr)#(lf)LEFT JOIN SA1010 SA1 ON SA1.D_E_L_E_T_ <> '*' AND SF1.F1_FORNECE = SA1.A1_COD AND SF1.F1_LOJA = SA1.A1_LOJA#(cr)#(lf)WHERE#(cr)#(lf)    SF1.D_E_L_E_T_ <> '*' AND#(cr)#(lf)    SF1.F1_STATUS = '' AND#(cr)#(lf)    SF1.F1_TIPO = 'D'"
in
    Fonte;

shared fDevolucoes = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlDevolucoes, CommandTimeout=#duration(69, 10, 39, 0)])
in
    Fonte;

shared sqlCompras = let
    Fonte = "
SELECT
    SF1.F1_FILIAL, 
    SF1.F1_DOC, 
    SF1.F1_SERIE, 
    SF1.F1_FORNECE, 
    SF1.F1_LOJA, 
    SF1.F1_COND, 
    SF1.F1_DUPL, 
    SF1.F1_EMISSAO, 
    SF1.F1_TIPO, 
    SF1.F1_DTDIGIT, 
    SF1.F1_DTLANC, 
    SF1.F1_FORMUL, 
    SF1.F1_NFORIG, 
    SF1.F1_SERORIG, 
    SF1.F1_ESPECIE, 
    SF1.F1_TIPO_NF, 
    SF1.F1_VALBRUT,
    SF1.F1_PREFIXO, 
    SF1.F1_STATUS, 
    SF1.F1_TIPODOC, 
    SF1.F1_ORIGEM, 
    SF1.F1_MOTIVO, 
    SF1.D_E_L_E_T_, 
    SF1.R_E_C_N_O_, 
    SF1.R_E_C_D_E_L_, 
    SF1.F1_MSUIDT, 
    SF1.S_T_A_M_P_, 
    SF1.I_N_S_D_T_, 
    SF1.F1_OBSFISC, 
    SF1.F1_OBSFTIT, 
    SF1.F1_USERLGI, 
    SF1.F1_USERLGA, 
    SF1.F1_X_MOTIV, 
    SD1.D1_FILIAL, 
    SD1.D1_ITEM, 
    SD1.D1_COD, 
    SD1.D1_UM, 
    SD1.D1_SEGUM, 
    SD1.D1_QUANT,
    SD1.D1_VUNIT,
    SD1.D1_TOTAL,
    SD1.D1_TES,
    SD1.D1_CF,
    SD1.D1_DESC,
    SD1.D1_CONTA,
    SD1.D1_ITEMCTA,
    SD1.D1_CC,
    SD1.D1_OP,
    SD1.D1_PEDIDO,
    SD1.D1_ITEMPC,
    SD1.D1_FORNECE,
    SD1.D1_LOJA,
    SD1.D1_DOC,
    SD1.D1_EMISSAO,
    SD1.D1_DTDIGIT,
    SD1.D1_GRUPO,
    SD1.D1_TIPO,
    SD1.D1_SERIE,
    SD1.D1_TP,
    SD1.D1_NFORI,
    SD1.D1_SERIORI,
    SD1.D1_ITEMORI,
    SD1.D1_DATORI,
    SD1.D1_VALDESC,
    SD1.D1_LOTEFOR,
    SD1.D1_LOTECTL,
    SD1.D1_NUMLOTE,
    SD1.D1_IDTRIB,
    SD1.D_E_L_E_T_,
    SD1.R_E_C_N_O_,
    SD1.R_E_C_D_E_L_,
    SD1.D1_MSUIDT,
    SD1.S_T_A_M_P_,
    SD1.I_N_S_D_T_,
    SD1.D1_USERLGI,
    SD1.D1_USERLGA,
    SD1.D1_PEDIDO,
    SD1.D1_ITEMPC
FROM SF1010 SF1
    INNER JOIN SD1010 SD1 ON SD1.D_E_L_E_T_ = '' 
        AND SF1.F1_DOC      = SD1.D1_DOC 
        AND SF1.F1_SERIE    = SD1.D1_SERIE 
        AND SF1.F1_FORNECE  = SD1.D1_FORNECE 
        AND SF1.F1_LOJA     = SD1.D1_LOJA
WHERE
    SF1.D_E_L_E_T_ = ''
    "
in
    Fonte;

shared fCompras = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlCompras, CommandTimeout=#duration(69, 10, 39, 0)]),
    #"From Value" = Table.FromValue(Fonte),
    #"Remove Columns" = Table.RemoveColumns(#"From Value", Table.ColumnsOfType(#"From Value", {type table, type record, type list, type nullable binary, type binary, type function}))
in
  #"Remove Columns";

shared sqlHistCompra = let
    Fonte = "
WITH PC AS (
    SELECT
        SC7.C7_FILIAL, SC7.C7_NUM, SC7.C7_ITEM, SC7.C7_EMISSAO,
        SC7.C7_PRODUTO, SC7.C7_DESCRI, SC7.C7_UM,
        SC7.C7_QUANT, SC7.C7_QUJE, SC7.C7_QTDACLA,
        SC7.C7_PRECO, SC7.C7_TOTAL, SC7.C7_MOEDA,
        SC7.C7_FORNECE, SC7.C7_LOJA, SC7.C7_COND, SC7.C7_USER,
        SC7.C7_NUMSC, SC7.C7_ITEMSC,
        SC7.C7_CONAPRO, SC7.C7_RESIDUO, SC7.C7_ENCER,
        SC7.C7_DATPRF, SC7.C7_DINICOM, SC7.C7_DINITRA
    FROM SC7010 SC7 WITH (NOLOCK)
    WHERE SC7.D_E_L_E_T_ = ' '
      -- AND SC7.C7_FILIAL = @Filial
    --   AND SC7.C7_EMISSAO >= '20260101'   -- recomendado: limite a janela de análise
      AND SC7.C7_PRODUTO NOT LIKE 'SV%'
),
CALC AS (
    SELECT
        PC.*,
        /* preço da compra anterior DO MESMO PRODUTO */
        LAG(PC.C7_PRECO) OVER (
            PARTITION BY PC.C7_PRODUTO
            ORDER BY PC.C7_EMISSAO, PC.C7_NUM, PC.C7_ITEM
        ) AS PRECO_ANTERIOR,
        /* média histórica DO MESMO PRODUTO */
        AVG(PC.C7_PRECO) OVER (PARTITION BY PC.C7_PRODUTO) AS PRECO_MEDIO_HIST,
        COUNT(*)        OVER (PARTITION BY PC.C7_PRODUTO) AS QTD_COMPRAS_PROD
    FROM PC
)
SELECT
    /* --- identificação --- */
    CALC.C7_FILIAL                                      AS FILIAL,
    CALC.C7_NUM                                         AS PEDIDO,
    CALC.C7_ITEM                                        AS ITEM,
    CAST(CALC.C7_EMISSAO AS DATE) AS EMISSAO,

    /* --- status --- */
    CASE
        WHEN CALC.C7_CONAPRO = 'R'                      THEN 'Rejeitado'
        WHEN CALC.C7_CONAPRO = 'B'                      THEN 'Em aprovação'
        WHEN CALC.C7_RESIDUO <> ' '                     THEN 'Eliminado por resíduo'
        WHEN CALC.C7_ENCER   = 'E'                      THEN 'Encerrado'
        WHEN CALC.C7_QUANT > 0
         AND CALC.C7_QUJE  >= CALC.C7_QUANT             THEN 'Recebido'
        WHEN CALC.C7_QUJE  > 0                          THEN 'Recebido parcial'
        WHEN CALC.C7_QTDACLA > 0                        THEN 'Em recebimento'
        ELSE 'Aprovado / em aberto'
    END                                                 AS STATUS_PEDIDO,

    /* --- fornecedor --- */
    CALC.C7_FORNECE                                     AS COD_FORNECEDOR,
    CALC.C7_LOJA                                        AS LOJA,
    SA2.A2_NREDUZ                                       AS FORNECEDOR,
    SA2.A2_CGC                                          AS CNPJ,
    SA2.A2_EST                                          AS UF,

    /* --- produto e quantidades --- */
    CALC.C7_PRODUTO                                     AS PRODUTO,
    CALC.C7_DESCRI                                      AS DESCRICAO,
    CALC.C7_UM                                          AS UNIDADE,
    CALC.C7_QUANT                                       AS QTD_PEDIDA,
    CALC.C7_QUJE                                        AS QTD_ENTREGUE,
    CALC.QTD_COMPRAS_PROD                               AS QTD_COMPRAS_DO_PRODUTO,

    /* --- preço --- */
    CALC.C7_MOEDA                                       AS MOEDA,
    CALC.C7_PRECO                                       AS PRECO_UNIT,
    CALC.C7_TOTAL                                       AS VALOR_TOTAL,
    TRY_CAST(CALC.C7_TOTAL / NULLIF(CALC.C7_QUANT, 0) AS DECIMAL(20,6))
                                                        AS PRECO_UNIT_CALC,

    /* variação vs. compra anterior do mesmo produto */
    TRY_CAST(CALC.PRECO_ANTERIOR AS DECIMAL(20,6))      AS PRECO_ANTERIOR,
    TRY_CAST(
        (CALC.C7_PRECO - CALC.PRECO_ANTERIOR) * 100.0
        / NULLIF(CALC.PRECO_ANTERIOR, 0)
    AS DECIMAL(20,2))                                   AS VAR_PCT_VS_ANTERIOR,

    /* desvio contra a média histórica do mesmo produto */
    TRY_CAST(CALC.PRECO_MEDIO_HIST AS DECIMAL(20,6))    AS PRECO_MEDIO_HIST,
    TRY_CAST(
        (CALC.C7_PRECO - CALC.PRECO_MEDIO_HIST) * 100.0
        / NULLIF(CALC.PRECO_MEDIO_HIST, 0)
    AS DECIMAL(20,2))                                   AS DESVIO_PCT_VS_MEDIA,

    /* --- pessoas e condição --- */
    USR7.USR_NOME                                       AS COMPRADOR,
    CALC.C7_NUMSC                                       AS SOLICITACAO,
    CALC.C7_ITEMSC                                      AS ITEM_SC,
    USR1.USR_NOME                                       AS SOLICITANTE,
    CALC.C7_COND                                        AS COND_PAGTO,
    SE4.E4_DESCRI                                       AS DESC_COND_PAGTO,

    /* --- datas de ciclo --- */
    TRY_CAST(NULLIF(CALC.C7_DINICOM, '') AS DATE)       AS INICIO_COMPRA,
    TRY_CAST(NULLIF(CALC.C7_DINITRA, '') AS DATE)       AS INICIO_TRANSITO,
    TRY_CAST(NULLIF(CALC.C7_DATPRF,  '') AS DATE)       AS DATA_PREVISTA,
    TRY_CAST(NULLIF(NF.DATA_REALIZADA,  '') AS DATE)    AS DATA_REALIZADA,

    /* --- realizado na entrada (agregado, sem duplicar linha) --- */
    NF.QTD_RECEBIDA_NF,
    NF.VALOR_RECEBIDO_NF,
    TRY_CAST(NF.VALOR_RECEBIDO_NF / NULLIF(NF.QTD_RECEBIDA_NF, 0) AS DECIMAL(20,6))
                                                        AS PRECO_UNIT_NF,
    NF.QTDE_NOTAS,
    NF.ULTIMA_ENTRADA

FROM CALC
    LEFT JOIN SA2010 SA2 WITH (NOLOCK)
           ON SA2.D_E_L_E_T_ = ' '
          AND SA2.A2_COD     = CALC.C7_FORNECE
          AND SA2.A2_LOJA    = CALC.C7_LOJA
    LEFT JOIN SC1010 SC1 WITH (NOLOCK)
           ON SC1.D_E_L_E_T_ = ' '
          AND SC1.C1_FILIAL  = CALC.C7_FILIAL
          AND SC1.C1_NUM     = CALC.C7_NUMSC
          AND SC1.C1_ITEM    = CALC.C7_ITEMSC
    LEFT JOIN SYS_USR USR7 WITH (NOLOCK)
           ON USR7.D_E_L_E_T_ = ' '
          AND USR7.USR_ID     = CALC.C7_USER
    LEFT JOIN SYS_USR USR1 WITH (NOLOCK)
           ON USR1.D_E_L_E_T_ = ' '
          AND USR1.USR_ID     = SC1.C1_USER
    LEFT JOIN SE4010 SE4 WITH (NOLOCK)
           ON SE4.D_E_L_E_T_ = ' '
          AND SE4.E4_FILIAL  = CALC.C7_FILIAL
          AND SE4.E4_CODIGO  = CALC.C7_COND
    OUTER APPLY (
        SELECT
            SUM(SD1.D1_QUANT)                   AS QTD_RECEBIDA_NF,
            SUM(SD1.D1_TOTAL)                   AS VALOR_RECEBIDO_NF,
            COUNT(DISTINCT SD1.D1_DOC)          AS QTDE_NOTAS,
            MAX(TRY_CAST(SD1.D1_DTDIGIT AS DATE)) AS ULTIMA_ENTRADA,
            MAX(TRY_CAST(SD1.D1_DTDIGIT AS DATE)) AS DATA_REALIZADA
        FROM SD1010 SD1 WITH (NOLOCK)
        WHERE SD1.D_E_L_E_T_ = ' '
          AND SD1.D1_FILIAL  = CALC.C7_FILIAL
          AND SD1.D1_PEDIDO  = CALC.C7_NUM
          AND SD1.D1_ITEMPC  = CALC.C7_ITEM
    ) NF
ORDER BY CALC.C7_PRODUTO, CALC.C7_EMISSAO DESC, CALC.C7_NUM DESC, CALC.C7_ITEM;
"
in
    Fonte;

shared fHistCompra = let
    Fonte = Sql.Database("201.157.243.99,1725", "CJ9SWK_168962_PR_PD", [Query=sqlHistCompra, CommandTimeout=#duration(69, 10, 39, 0)]),
    #"Texto Aparado" = Table.TransformColumns(Fonte,{{"FILIAL", Text.Trim, type text}, {"PEDIDO", Text.Trim, type text}, {"ITEM", Text.Trim, type text}, {"STATUS_PEDIDO", Text.Trim, type text}, {"COD_FORNECEDOR", Text.Trim, type text}, {"LOJA", Text.Trim, type text}, {"FORNECEDOR", Text.Trim, type text}, {"CNPJ", Text.Trim, type text}, {"UF", Text.Trim, type text}, {"PRODUTO", Text.Trim, type text}, {"DESCRICAO", Text.Trim, type text}, {"UNIDADE", Text.Trim, type text}, {"COMPRADOR", Text.Trim, type text}, {"SOLICITACAO", Text.Trim, type text}, {"ITEM_SC", Text.Trim, type text}, {"SOLICITANTE", Text.Trim, type text}, {"COND_PAGTO", Text.Trim, type text}}),
    #"Tipo Alterado" = Table.TransformColumnTypes(#"Texto Aparado",{{"PRECO_UNIT", Currency.Type}, {"VALOR_TOTAL", Currency.Type}, {"PRECO_UNIT_CALC", Currency.Type}, {"PRECO_ANTERIOR", Currency.Type},  {"PRECO_MEDIO_HIST", Currency.Type}})
in
    #"Tipo Alterado";

shared __STATUS__ = let
    Fonte = if Table.RowCount(Table.Combine({fDevolucoes, fPedCompra, fSaldoFisico, fCompras, fHistCompra})) > 0 then DateTime.LocalNow() else "Pendente"
in
    Fonte;

shared __SQL__ = let
    #"Linhas Filtradas" = Table.SelectRows(Record.ToTable(#shared), each Text.StartsWith([Name], "sql"))
in
    #"Linhas Filtradas";