-- Dimensão PRODUTO — extraída do Protheus (SB1010) -> raw.produtos
-- Fonte: query embutida no Power Query de dProdutos.xlsx (sqldProdutos).
-- Grão: um produto (B1_COD).
-- Obs.: a descrição do grupo de estoque vem de SBM010 (ver grupos.sql);
--       aqui trazemos apenas o código do grupo (B1_GRUPO), como no Excel.
SELECT
    SB1.B1_COD      AS _CODPRODUTO,
    SB1.B1_DESC     AS _DESCPRODUTO,
    SB1.B1_TIPO     AS _TIPOPRDUTO,
    SB1.B1_UM       AS _UNIDADEMEDIDAPRODUTO,
    SB1.B1_GRUPO    AS _GRUPOESTOQUE,
    SB1.B1_UCOM     AS _DTAULTCOMPRA,
    SB1.B1_CONTA    AS _CONTA,
    SB1.B1_X_AGRUP,
    SB1.B1_UPRC     AS "Ult. Preco Comp."
FROM SB1010 SB1
WHERE SB1.D_E_L_E_T_ = ''
