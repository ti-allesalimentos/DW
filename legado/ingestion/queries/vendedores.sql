-- Dimensão VENDEDOR — extraída do Protheus (SA3010) -> raw.vendedores
-- Fonte: query embutida no Power Query de dVendedores.xlsx (sqlVendedores).
-- Grão: um vendedor (A3_COD).
-- Self-join em SA3010 (alias G) para trazer nome e comissão do gerente.
-- Regra especial de comissão do gerente (mantida do Excel):
--   se o gerente é '000004' e o vendedor não é '000026', comissão = 0.01;
--   caso contrário, usa a comissão real do gerente (G.A3_COMIS / 100).
SELECT
    SA3.A3_COD      AS _CODVEND,
    SA3.A3_NOME     AS _NOMEVEND,
    SA3.A3_GEREN    AS _GERENVEND,
    SA3.A3_COMIS / 100          AS _COMISVEND,
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
