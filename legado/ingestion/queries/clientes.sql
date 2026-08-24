-- Dimensão CLIENTE — extraída do Protheus (SA1010) -> raw.clientes
-- Fonte: query embutida no Power Query de dClientes.xlsx (sqlClientes).
-- Grão: um cliente+loja (A1_COD + A1_LOJA).
-- Tratativas em M aplicadas DEPOIS do SQL (ver extração):
--   * _CHAVECLIENTE = A1_COD || A1_LOJA (concatenação);
--   * join com dEstados (aba dRegiao do fManual.xlsx) por sigla do estado
--     -> traz _ESTCLIENTEDESCR (UF por extenso) e _REGIAOCLIENTE, em MAIÚSCULAS;
--   * _COMISCLIENTE -> _%COMISCLIENTE ; _DESCCLIENTE -> _%DESCCLIENTE.
SELECT
    SA1.A1_COD      AS _COD,
    SA1.A1_LOJA     AS _LJ,
    SA1.A1_PESSOA   AS _PFJ,
    SA1.A1_NOME     AS _NOMECLIENTE,
    SA1.A1_NREDUZ   AS _NREDUZCLIENTE,
    SA1.A1_GRPVEN   AS _CODRED,
    SA1.A1_END      AS _ENDCLIENTE,
    SA1.A1_BAIRRO   AS _BAIRROCLIENTE,
    SA1.A1_EST      AS _ESTCLIENTE,
    SA1.A1_CGC      AS _CGCCLIENTE,
    SA1.A1_MUN      AS _MUNCLIENTE,
    SA1.A1_X_FREC   AS _FORMAPGTOCLIENTE,
    SA1.A1_COND     AS _CONDPGTO,
    SA1.A1_CONTA    AS _CONTACONTABIL,
    SA1.A1_BCO1     AS _BCOCLIENTE,
    SA1.A1_COMIS    AS _COMISCLIENTE,
    SA1.A1_DESC     AS _DESCCLIENTE,
    SA1.A1_VEND     AS _CODVEND,
    SA1.A1_VEND3    AS _GERENTE,
    CAST(SA1.A1_DTCAD AS DATE)   AS DTCADASTRO,
    CAST(SA1.A1_ULTCOM AS DATE)  AS _DTAULTCOMPRA,
    SA1.A1_CEP      AS CEP,
    SA1.A1_X_TPCLI  AS TPCLI,
    SA1.A1_TIPO     AS TP,
    SA1.A1_MSBLQL   AS _SITUACAO
FROM SA1010 SA1
WHERE SA1.D_E_L_E_T_ = ''
