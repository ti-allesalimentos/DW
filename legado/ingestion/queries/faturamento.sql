-- Extração de faturamento (itens de NF de saída) do Protheus -> raw.faturamento
-- Grão: item de nota fiscal.
-- IMPORTANTE: aqui NÃO aplicamos a conversão caixa->quilo (-CX).
-- Ela acontece uma única vez no fato, via dw.map_produto_cx.
SELECT
    SD2.D2_FILIAL   AS filial,
    SD2.D2_DOC      AS nfe,
    SD2.D2_SERIE    AS serie,
    SD2.D2_ITEM     AS item_nf,
    SD2.D2_COD      AS cod_protheus,   -- pode terminar em '-CX'
    SD2.D2_QUANT    AS quant,
    SD2.D2_UM       AS um,
    SD2.D2_TOTAL    AS total,
    SD2.D2_DESCZFR  AS desc_zfr,
    SD2.D2_CF       AS cfop,
    SD2.D2_CLIENTE  AS cod_cliente,
    SD2.D2_LOJA     AS loja_cliente,
    CAST(SD2.D2_EMISSAO AS DATE) AS dt_emissao,
    CASE WHEN SA1.A1_COND = '' THEN SF2.F2_COND ELSE SA1.A1_COND END AS cond_pgto,
    SC5.C5_TABELA   AS tab_preco,
    SF2.F2_DUPL     AS duplicata,
    SF2.F2_EST      AS estado,
    SF2.F2_TIPOCLI  AS tipo_cli,
    SA1.A1_VEND     AS cod_vendedor,
    SA1.A1_VEND1    AS cond_especial,
    SF2.F2_TIPO     AS tipo,
    SC5.C5_X_REFAT  AS nfori_refatura,
    SC5.C5_X_TPENT  AS tipo_entrega,
    SD2.D2_PICM     AS aliq_icms,
    SD2.D2_ALQPIS   AS aliq_pis,
    SD2.D2_ALQCOF   AS aliq_cofins,
    SD2.D2_ICMSRET  AS aliq_icmsst
FROM SD2010 SD2
LEFT JOIN SF2010 SF2
    ON SF2.D_E_L_E_T_ = ''
   AND SD2.D2_FILIAL  = SF2.F2_FILIAL
   AND SD2.D2_DOC     = SF2.F2_DOC
   AND SD2.D2_CLIENTE = SF2.F2_CLIENTE
   AND SD2.D2_LOJA    = SF2.F2_LOJA
INNER JOIN SC5010 SC5
    ON SC5.D_E_L_E_T_ = ''
   AND SC5.C5_FILIAL  = SD2.D2_FILIAL
   AND SC5.C5_NUM     = SD2.D2_PEDIDO
INNER JOIN SA1010 SA1
    ON SA1.D_E_L_E_T_ = ''
   AND SA1.A1_COD     = SD2.D2_CLIENTE
   AND SA1.A1_LOJA    = SD2.D2_LOJA
WHERE SD2.D_E_L_E_T_ <> '*'
  AND (SF2.D_E_L_E_T_ <> '*' OR SF2.D_E_L_E_T_ IS NULL)
  AND SD2.D2_EMISSAO > '20250131'
  AND SD2.D2_CLIENTE <> '97316293'
  AND SF2.F2_TIPO <> 'B'
  AND SD2.D2_CF IN ('6101','5102','6118','5101','5403','6110','6401',
                    '6107','6102','5401','6403','6108','6109','5109','6501')
  AND SD2.D2_FILIAL IN ('01001','01003','01004','01005','01006',
                        '01007','01009','01010','01011')
  -- Exclusões pontuais de NF (mesmas da planilha fFaturamento), para bater 100%.
  -- Filial 01004: NFs específicas descartadas do faturamento.
  AND (SD2.D2_FILIAL <> '01004' OR SD2.D2_DOC NOT IN (
        '000029000','000012896','000012898','000012899','000012900','000012901',
        '000012908','000012909','000012910','000012911','000012912','000015334',
        '000015335','000015336','000015455','000015456','000015457','000016294',
        '000016295','000016296','000016298','000016299','000016300','000016320',
        '000016321','000016322','000016323','000016324','000018493','000023971',
        '000025043','000030015','000030016','000030017','000030018','000030019'))
  -- Filial 03001: (fora da lista de filiais acima, mantida por fidelidade à planilha).
  AND (SD2.D2_FILIAL <> '03001' OR SD2.D2_DOC NOT IN ('000002073','000002082'))
