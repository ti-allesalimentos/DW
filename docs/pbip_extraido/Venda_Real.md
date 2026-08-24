# Modelo semantico: Venda Real

- Tabelas: 55
- Colunas: 594
- Medidas DAX: 115
- Relacionamentos: 69 (4 inativos, 4 bidirecionais)

## Tabelas

| Tabela | Colunas | Medidas |
|--------|--------:|--------:|
| DCalendario | 114 | 0 |
| DPeriodos | 5 | 0 |
| DTempo | 10 | 0 |
| DateTableTemplate_e881cfdf-6502-4d7f-82dd-2374ea9394af | 7 | 0 |
| FPercentual | 2 | 0 |
| FluxoPEDIDOSDEVENDACONSOLIDADO | 1 | 0 |
| FluxodCalendario | 1 | 0 |
| FluxodClientes | 1 | 0 |
| FluxodProdutos | 1 | 0 |
| FluxodVendedores | 1 | 0 |
| FluxofFaturamento | 1 | 0 |
| LocalDateTable_0b76e245-fa4f-4899-a1b3-d69936d24a62 | 7 | 0 |
| LocalDateTable_35eb8435-ad64-4655-9cda-6d3adc38fac5 | 7 | 0 |
| LocalDateTable_46e729e6-ac5e-4922-bcbe-56048ef5b04e | 7 | 0 |
| LocalDateTable_5b765869-2bf6-4adc-8078-c6e1ea0ba77d | 7 | 0 |
| LocalDateTable_63c209dd-102a-4888-b7f4-10be9a7df072 | 7 | 0 |
| LocalDateTable_742b13f1-ad79-4e5b-81e6-330036a44cc9 | 7 | 0 |
| LocalDateTable_83c5b1e3-05bf-4d5b-a4c7-03b1ad2e6f3b | 7 | 0 |
| LocalDateTable_8e574885-f842-42b1-9871-4e024f3f98d1 | 7 | 0 |
| LocalDateTable_9016f602-21eb-416a-8767-361055160cd6 | 7 | 0 |
| LocalDateTable_a1c7f7a1-64f4-4422-b2f8-60ae6b1e6952 | 7 | 0 |
| LocalDateTable_b0e998c7-73f7-4a8b-ac4a-37c5c0860c52 | 7 | 0 |
| LocalDateTable_c12817b7-3b45-4f47-841c-7dadaf283bfb | 7 | 0 |
| LocalDateTable_c3f8adf7-d0c3-4776-ac96-59f2406fd554 | 7 | 0 |
| LocalDateTable_ebb74f10-fce7-44cc-81c9-18eed92ac07c | 7 | 0 |
| LocalDateTable_ef8f648b-2e22-4a81-a77d-d15f57bf138c | 7 | 0 |
| Percentual | 2 | 0 |
| Percentual2 | 2 | 0 |
| TebelaPrecosConsu | 11 | 0 |
| VLR_PROMOTORES | 1 | 0 |
| _MEDIDAS | 0 | 115 |
| dBaseRedes | 1 | 0 |
| dClientes | 29 | 0 |
| dCondPgt | 4 | 0 |
| dDestino | 2 | 0 |
| dEmpresas | 5 | 0 |
| dEntrega | 2 | 0 |
| dEstados | 3 | 0 |
| dFamilia | 6 | 0 |
| dGerentes | 7 | 0 |
| dMotivoDev | 3 | 0 |
| dProdutos | 9 | 0 |
| dRedes | 3 | 0 |
| dTabelaPreço | 6 | 0 |
| dVendedores | 7 | 0 |
| fAcordoComercial | 15 | 0 |
| fDevoluções (2) | 9 | 0 |
| fDevoluções | 22 | 0 |
| fFaturamento (2) | 7 | 0 |
| fFaturamento | 36 | 0 |
| fFaturamentoBonific | 26 | 0 |
| fPedidosEmbarque | 37 | 0 |
| fPedidosEmbarqueAb | 39 | 0 |
| fPedidosEmbarqueCarga | 39 | 0 |
| fRefaturamento | 12 | 0 |

## Relacionamentos

| De | Para | Cardinalidade | Filtro | Ativo |
|----|------|---------------|--------|-------|
| DPeriodos.Data | LocalDateTable_b0e998c7-73f7-4a8b-ac4a-37c5c0860c52.Date | many->one | singleDirection | sim |
| dClientes._CONDPGTO | dCondPgt.CODCOND | many->one | singleDirection | sim |
| dClientes._CODVEND | dVendedores._CODVEND | many->one | singleDirection | sim |
| dProdutos._CODPRODUTO | dFamilia.COD | one->one | bothDirections | sim |
| fFaturamento._CHAVECLIENTE | dClientes._CHAVECLIENTE | many->one | singleDirection | sim |
| fFaturamento._DTEMISSAO | DCalendario.Data | many->one | singleDirection | sim |
| dClientes._CODRED | dRedes.ACY_GRPVEN | many->one | singleDirection | sim |
| fFaturamento.CODPROD | dProdutos._CODPRODUTO | many->one | singleDirection | sim |
| fFaturamento._ESTADO | dEstados.Sigla | many->one | singleDirection | sim |
| fFaturamento.FILIAL | dEmpresas.NROEMPRESA | many->one | singleDirection | sim |
| fAcordoComercial.CHAVECLIENTE | dClientes._CHAVECLIENTE | many->one | singleDirection | sim |
| fAcordoComercial.CODPROD | dProdutos._CODPRODUTO | many->one | singleDirection | sim |
| fAcordoComercial.FILIAL | dEmpresas.NROEMPRESA | many->one | singleDirection | sim |
| fDevoluções.CHAVECLIENTE | dClientes._CHAVECLIENTE | many->one | singleDirection | sim |
| fDevoluções.EMISSAO | DCalendario.Data | many->one | singleDirection | sim |
| fDevoluções.CODPROD | dProdutos._CODPRODUTO | many->one | singleDirection | sim |
| fDevoluções.FILIAL | dEmpresas.NROEMPRESA | many->one | singleDirection | sim |
| dClientes._DTAULTCOMPRA | LocalDateTable_35eb8435-ad64-4655-9cda-6d3adc38fac5.Date | many->one | singleDirection | sim |
| fPedidosEmbarque.EMISSAOPED | LocalDateTable_0b76e245-fa4f-4899-a1b3-d69936d24a62.Date | many->one | singleDirection | sim |
| fPedidosEmbarque.EMISSAONF | LocalDateTable_a1c7f7a1-64f4-4422-b2f8-60ae6b1e6952.Date | many->one | singleDirection | sim |
| fPedidosEmbarque.CHAVECLIENTE | dClientes._CHAVECLIENTE | many->one | singleDirection | sim |
| fPedidosEmbarque.DTEMBARQUE | DCalendario.Data | many->one | singleDirection | sim |
| fPedidosEmbarque.CODPROD | dProdutos._CODPRODUTO | many->one | singleDirection | sim |
| fPedidosEmbarque.FILIAL | dEmpresas.GRUPOECONOMICO | many->many | singleDirection | sim |
| fFaturamento._CHAVECLIENTE | fPedidosEmbarque.CHAVECLIENTE | many->many | singleDirection | sim |
| dTabelaPreço.CODPROD | dProdutos._CODPRODUTO | many->one | singleDirection | sim |
| fDevoluções.NFORIGEM | fFaturamento.NFE | many->many | singleDirection | sim |
| fDevoluções.MOTIVODEV | dMotivoDev.SIGLA | many->one | singleDirection | sim |
| fDevoluções.LANCAMENTO | LocalDateTable_63c209dd-102a-4888-b7f4-10be9a7df072.Date | many->one | singleDirection | sim |
| dClientes.DTCADASTRO | LocalDateTable_83c5b1e3-05bf-4d5b-a4c7-03b1ad2e6f3b.Date | many->one | singleDirection | sim |
| fDevoluções.DESTINO | dDestino.'Coluna 1' | many->one | singleDirection | sim |
| fRefaturamento._DTEMISSAO | LocalDateTable_ebb74f10-fce7-44cc-81c9-18eed92ac07c.Date | many->one | singleDirection | sim |
| fDevoluções.DTAEMISSNFORI | LocalDateTable_9016f602-21eb-416a-8767-361055160cd6.Date | many->one | singleDirection | sim |
| fAcordoComercial.ITEMORI | fFaturamento.ITEM | many->many | bothDirections | nao |
| fAcordoComercial.FILIAL | fFaturamento.FILIAL | many->many | bothDirections | nao |
| 'fFaturamento (2)'._DTEMISSAO | LocalDateTable_c3f8adf7-d0c3-4776-ac96-59f2406fd554.Date | many->one | singleDirection | sim |
| 'fFaturamento (2)'._CHAVECLIENTE | dClientes._CHAVECLIENTE | many->one | singleDirection | sim |
| fAcordoComercial.EMISSAO | LocalDateTable_5b765869-2bf6-4adc-8078-c6e1ea0ba77d.Date | many->one | singleDirection | sim |
| fAcordoComercial.'fFaturamento (2)._DTEMISSAO' | DCalendario.Data | many->one | singleDirection | sim |
| fPedidosEmbarque.ESTADO | dEstados.Sigla | many->one | singleDirection | sim |
| fPedidosEmbarqueAb.EMISSAONF | LocalDateTable_742b13f1-ad79-4e5b-81e6-330036a44cc9.Date | many->one | singleDirection | sim |
| fPedidosEmbarqueAb.DTEMBARQUE | LocalDateTable_46e729e6-ac5e-4922-bcbe-56048ef5b04e.Date | many->one | singleDirection | sim |
| fPedidosEmbarqueAb.CHAVECLIENTE | dClientes._CHAVECLIENTE | many->one | singleDirection | sim |
| fPedidosEmbarqueAb.ESTADO | dEstados.Sigla | many->one | singleDirection | sim |
| fPedidosEmbarqueAb.CODPROD | dProdutos._CODPRODUTO | many->one | singleDirection | sim |
| TebelaPrecosConsu.Tipo | dEntrega.'Tipo Entrega' | many->one | singleDirection | sim |
| TebelaPrecosConsu.Produto | dProdutos._CODPRODUTO | many->one | singleDirection | sim |
| TebelaPrecosConsu.REGIÃO | dEstados.Região | many->many | bothDirections | sim |
| fPedidosEmbarqueAb.FILIAL | dEmpresas.NROEMPRESA | many->one | singleDirection | sim |
| fPedidosEmbarque.FILIAL | dEmpresas.NROEMPRESA | many->one | singleDirection | nao |
| fPedidosEmbarqueCarga.EMISSAOPED | LocalDateTable_ef8f648b-2e22-4a81-a77d-d15f57bf138c.Date | many->one | singleDirection | sim |
| fPedidosEmbarqueCarga.EMISSAONF | LocalDateTable_c12817b7-3b45-4f47-841c-7dadaf283bfb.Date | many->one | singleDirection | sim |
| fPedidosEmbarqueCarga.CHAVECLIENTE | dClientes._CHAVECLIENTE | many->one | singleDirection | sim |
| fPedidosEmbarqueCarga.FILIAL | dEmpresas.NROEMPRESA | many->one | singleDirection | sim |
| fPedidosEmbarqueCarga.CODPROD | dProdutos._CODPRODUTO | many->one | singleDirection | sim |
| fPedidosEmbarqueCarga.DTEMBARQUE | DCalendario.Data | many->one | singleDirection | sim |
| fPedidosEmbarqueCarga.ESTADO | dEstados.Sigla | many->one | singleDirection | sim |
| fPedidosEmbarqueAb.EMISSAOPED | LocalDateTable_8e574885-f842-42b1-9871-4e024f3f98d1.Date | many->one | singleDirection | sim |
| fPedidosEmbarqueAb.'TIPO DE ENTREGA' | dEntrega.'Tipo Entrega' | many->one | singleDirection | sim |
| fPedidosEmbarqueCarga.'TIPO DE ENTREGA' | dEntrega.'Tipo Entrega' | many->one | singleDirection | sim |
| fFaturamento.'TIPO DE ENTREGA' | dEntrega.'Tipo Entrega' | many->one | singleDirection | sim |
| dRedes.Redes | dBaseRedes.Redes | many->one | singleDirection | sim |
| dClientes._GERENTE | dGerentes._CODVEND | many->one | singleDirection | sim |
| 'fDevoluções (2)'.CHAVECLIENTE | dClientes._CHAVECLIENTE | many->one | singleDirection | sim |
| fFaturamentoBonific.CHAVECLIENTE | dClientes._CHAVECLIENTE | many->one | singleDirection | sim |
| fFaturamentoBonific._DTEMISSAO | DCalendario.Data | many->one | singleDirection | sim |
| fFaturamentoBonific.CODPROD | dProdutos._CODPRODUTO | many->one | singleDirection | sim |
| fFaturamentoBonific._ESTADO | dEstados.Sigla | many->one | singleDirection | sim |
| fFaturamentoBonific.'TIPO DE ENTREGA' | dEntrega.'Coluna 1' | many->one | singleDirection | nao |

## Medidas DAX

### _MEDIDAS

**Total Vendido**

```dax
SUM(fFaturamento[TOTAL])
```

**Preço Médio**

```dax
[Total Vendido] / [Peso Total]
```

**Peso Total**

```dax
SUMX(DISTINCT(fFaturamento), [QTD])
```

**$ TOT DESC_OLD**

```dax
[Total Vendido] * [%DESCTOT_OLD]
```

**VENDA REAL**

```dax
SUMX( fFaturamento, IF( [Total Vendido Líq] = 0, 0, [Total Vendido Líq] - [$ TOT DESC] - [Total de Acordo Comercial] ) )
```

**%DESCTOT_OLD**

```dax
AVERAGEX( fFaturamento, fFaturamento[_%CONDESPECIAL] + fFaturamento[_%DESCFIN] )
```

**Total Devolvido**

```dax
sum('fDevoluções'[VRTOTAL])
```

**Peso Total Devolvido**

```dax
SUMX(DISTINCT('fDevoluções'), [QTD])
```

**Preço Médio Devolvido**

```dax
[Total Devolvido] / [Peso Total Devolvido]
```

**Total de Acordo Comercial**

```dax
``` CALCULATE ( SUM(fAcordoComercial[VRTOTAL]), TREATAS ( VALUES(fFaturamento[NFE]), fAcordoComercial[NFORIGEM] ), TREATAS ( VALUES(fFaturamento[CODPROD]), fAcordoComercial[CODPROD] ), TREATAS ( VALUES(fFaturamento[_CHAVECLIENTE]), fAcordoComercial[CHAVECLIENTE] ), TREATAS ( VALUES(fFaturamento[FILIAL]), fAcordoComercial[FILIAL] ), TREATAS ( VALUES(fFaturamento[ITEM]), fAcordoComercial[ITEMORI] ) ) ```
```

**Venda Real Liquida**

```dax
[Total Vendido] - [Total Devolvido] - [$ TOT DESC] - [Total de Acordo Comercial]
```

**Peso Liquido**

```dax
[Peso Total] - [Peso Total Devolvido]
```

**Preço Médio Liquido**

```dax
DIVIDE( [Venda Real Liquida] , [Peso Liquido])
```

**% Perda S/ Rec Bruta**

```dax
``` VAR vValor = DIVIDE( [Total Vendido], [Venda Real Liquida] ) - 1 VAR VFormat = FORMAT(vValor, "⇩ 0.00%" ) RETURN VFormat ```
```

**% Perda S/ Preço**

```dax
``` VAR vValor = DIVIDE( [Preço Médio] , [Preço Médio Liquido] ) - 1 VAR VFormat = FORMAT(vValor, "⇩ 0.00%" ) RETURN VFormat ```
```

**% Perda S/ Peso**

```dax
``` VAR vValor = DIVIDE( [Peso Total], [Peso Liquido] ) - 1 VAR VFormat = FORMAT(vValor, "⇩ 0.00%" ) RETURN VFormat ```
```

**% Dev S/ Rec Bruta**

```dax
``` VAR vValor = DIVIDE( [Total Vendido] - [Total Devolvido], [Total Vendido] ) -1 VAR VFormat = FORMAT(vValor, "⇩ 0.00%" ) RETURN VFormat ```
```

**% Perda S/ $ Dev**

```dax
``` VAR vValor = DIVIDE( [Total Devolvido], [Total Vendido] ) VAR VFormat = FORMAT(vValor, "⇩ 0.00%" ) RETURN VFormat ```
```

**% Perda S/ Peso Dev**

```dax
``` VAR vValor = DIVIDE( [Peso Total Devolvido], [Peso Total] ) VAR VFormat = FORMAT(vValor, "⇩ 0.00%" ) RETURN VFormat ```
```

**% Perda S/ Preço Dev**

```dax
``` VAR vValor = DIVIDE( [Preço Médio Devolvido], [Preço Médio] ) VAR VFormat = FORMAT(vValor, "0.00%" ) RETURN VFormat ```
```

**% Perda S/ $ Desc**

```dax
``` VAR vValor = DIVIDE( [$ TOT DESC_OLD], [Total Vendido] ) VAR VFormat = FORMAT(vValor, "⇩ 0.00%" ) RETURN VFormat ```
```

**% Perda S/ $ AcordCom**

```dax
``` VAR vValor = DIVIDE( [Total de Acordo Comercial], [Total Vendido] ) VAR VFormat = FORMAT(vValor, "⇩ 0.00%" ) RETURN VFormat ```
```

**Rank > Dev P/ Familia**

```dax
RANKX(ALL(dFamilia[FAMILIA]), [Total Devolvido])
```

**N DE NOTAS DEVOLVIDAS**

```dax
DISTINCTCOUNT('fDevoluções'[NF])
```

**Rank > Dev P/ Cliente**

```dax
RANKX(ALL(dClientes[_NOMECLIENTE]), [Total Devolvido])
```

**Tot Dev All**

```dax
CALCULATE( SUM('fDevoluções'[VRTOTAL]), ALL(DCalendario[Data] ))
```

**preço real 123**

```dax
[VENDA REAL] / [Peso Total]
```

**% de Preço de Tabela**

```dax
``` DIVIDE([preço real 123], SELECTEDVALUE('dTabelaPreço'[PRCUNIT]), 0) ```
```

**Format Preço**

```dax
``` IF( [% de Preço de Tabela] >= 1, "⇧ " & FORMAT([% de Preço de Tabela], "0.00%"), "⇩ " & FORMAT([% de Preço de Tabela], "0.00%") ) ```
```

**PRC MÉDIO P/ TABELA**

```dax
AVERAGEX( SUMMARIZE( 'dTabelaPreço', 'dTabelaPreço'[CODPROD], 'dTabelaPreço'[CODTABELA], "MÉDIAPREUNIT", AVERAGE('dTabelaPreço'[PRCUNIT]) ), [MÉDIAPREUNIT] )
```

**Rank > AC P/ Familia**

```dax
RANKX(ALL(dFamilia[FAMILIA]), [Total de Acordo Comercial])
```

**Rank > AC P/ Cliente**

```dax
RANKX(ALL(dClientes[_NOMECLIENTE]), [Total de Acordo Comercial])
```

**N DE ACORDOS COMERCIAIS**

```dax
DISTINCTCOUNT(fAcordoComercial[NFORIGEM])
```

**_Fixo Selout1**

```dax
"Sell-out "&(SUM(PERCENTUAL[Valores])*100)&" %"
```

**_ValorTotalSelout**

```dax
SUM(fFaturamento[TOTAL])-SUM('fDevoluções'[VRTOTAL])
```

**_Selout_1**

```dax
IF(SUM('PERCENTUAL'[Valores]) = 0.000,"Sem Valor", [Total - Dev] * SUM('PERCENTUAL'[Valores]))
```

**_Selout_2**

```dax
IF(SUM('Percentual2'[Valores2]) = 0.000,"Sem Valor", [Total - Dev] * SUM('Percentual2'[Valores2]))
```

**_Fixo Selout2**

```dax
"Sell-out "&(SUM(Percentual2[Valores2])*100)&" %"
```

**Venda ( - ) Devolução**

```dax
[Total Vendido] - [Total Devolvido]
```

**COMISSÃO SUPERVISOR**

```dax
SUMX( fFaturamento, [VENDA REAL] * RELATED(dVendedores[_COMISGERENTE]) )
```

**COMISSÃO VENDEDOR**

```dax
SUMX( fFaturamento, [VENDA REAL] * RELATED(dVendedores[_COMISVEND]) )
```

**_Fixo Promotores**

```dax
"Promotores R$"&(SUM(VLR_PROMOTORES[VALOR]))
```

**_Promotores**

```dax
IF(SUM(VLR_PROMOTORES[VALOR]) = 0.000,"Sem Valor", SUM(fFaturamento[QTD]) * SUM(VLR_PROMOTORES[VALOR]))
```

**RealceNF**

```dax
IF ( SELECTEDVALUE(fFaturamento[NFE]) IN VALUES('fDevoluções'[NFORIGEM]), 1, 0 )
```

**Rank Dev P/ Setor**

```dax
RANKX(ALL(dMotivoDev[SIGLA]), [Qtd Devoluções por Motivo])
```

**Qtd Devoluções por Motivo**

```dax
COUNTROWS('fDevoluções')
```

**Total Refaturado**

```dax
SUM('fDevoluções'[Refat.TOTAL])
```

**% Refat S/ $ Dev**

```dax
``` VAR vValor = DIVIDE( [Total Refaturado], [Total Devolvido] ) VAR VFormat = FORMAT(vValor, "0.00%" ) RETURN VFormat ```
```

**Devolução ( - ) Refaturado**

```dax
[Total Devolvido] - [Rateio Refat.TOTAL Proporcional]
```

**% Dev Liq S/ $ Vendido**

```dax
``` VAR vValor = DIVIDE( [Devolução ( - ) Refaturado], [Total Vendido] ) VAR VFormat = FORMAT(vValor, "⇩ 0.00%" ) RETURN VFormat ```
```

**%DESCTOT**

```dax
DIVIDE( SUMX( fFaturamento, (fFaturamento[_%CONDESPECIAL] + fFaturamento[_%DESCFIN]) * [Total Vendido Líq] ), [Total Vendido Líq] )
```

**$ TOT DESC**

```dax
[Total Vendido Líq] * [%DESCTOT]
```

**CorLinha**

```dax
``` SWITCH( TRUE(), CONTAINSSTRING(SELECTEDVALUE('fFaturamento'[Devolução?]), "DT"), "#F6D4D6", CONTAINSSTRING(SELECTEDVALUE('fFaturamento'[Devolução?]), "DP"), "#FFFFCC", BLANK() ) ```
```

**Total Vendido Líq**

```dax
SUM(fFaturamento[Total - Dev])
```

**Total de Acordo Comercial (Contextualizado)**

```dax
CALCULATE ( SUM(fAcordoComercial[VRTOTAL]), TREATAS ( VALUES(fFaturamento[NFE]), fAcordoComercial[NFORIGEM] ), TREATAS ( VALUES(fFaturamento[CODPROD]), fAcordoComercial[CODPROD] ), TREATAS ( VALUES(fFaturamento[_CHAVECLIENTE]), fAcordoComercial[CHAVECLIENTE] ), TREATAS ( VALUES(fFaturamento[FILIAL]), fAcordoComercial[FILIAL] ), TREATAS ( VALUES(fFaturamento[ITEM]), fAcordoComercial[ITEMORI] ) )
```

**TOTAL - DESC**

```dax
``` [Total Vendido Líq] - [$ TOT DESC] - [Total de Acordo Comercial (Contextualizado)] ```
```

**Total R$ Pedido**

```dax
SUM(fPedidosEmbarqueCarga[TOTAL]) - SUM(fPedidosEmbarqueCarga[R$DESCFIN])
```

**Total QTD Pedido**

```dax
SUM(fPedidosEmbarqueCarga[QTD])
```

**Preço Médio Pedido**

```dax
[Total R$ Pedido] / [Total QTD Pedido]
```

**Total QTD PedidoAB**

```dax
SUM(fPedidosEmbarqueAb[QTD])
```

**Total R$ PedidoAB**

```dax
SUM(fPedidosEmbarqueAb[TOTAL]) - SUM(fPedidosEmbarqueAb[R$DESCFIN])
```

**Preço Médio PedidoAB**

```dax
[Total R$ PedidoAB] / [Total QTD PedidoAB]
```

**Preço Médio Tabelado**

```dax
AVERAGE(TebelaPrecosConsu[precoDeVenda])
```

**% PMF x PMT**

```dax
VAR vValor = DIVIDE( [Preço Médio Tabelado] - [Preço Médio Liquido], [Preço Médio Tabelado] ) VAR VFormat = FORMAT( ABS(vValor), "0.00%" ) RETURN IF( [Preço Médio Liquido] < [Preço Médio Tabelado], "⇩ " & VFormat, "⇧ " & VFormat )
```

**% PM s/ Tab**

```dax
``` VAR vValor = DIVIDE( [Preço Médio Liquido], [Preço Médio Tabelado] ) -1 VAR VFormat = FORMAT(vValor, "⇩ 0.00%" ) RETURN VFormat ```
```

**% PMPC x PMT**

```dax
VAR vValor = DIVIDE( [Preço Médio Tabelado] - [Preço Médio Pedido], [Preço Médio Tabelado] ) VAR VFormat = FORMAT( ABS(vValor), "0.00%" ) RETURN IF( [Preço Médio Pedido] < [Preço Médio Tabelado], "⇩ " & VFormat, "⇧ " & VFormat )
```

**% PMPA x PMT**

```dax
VAR vValor = DIVIDE( [Preço Médio Tabelado] - [Preço Médio PedidoAB], [Preço Médio Tabelado] ) VAR VFormat = FORMAT( ABS(vValor), "0.00%" ) RETURN IF( [Preço Médio PedidoAB] < [Preço Médio Tabelado], "⇩ " & VFormat, "⇧ " & VFormat )
```

**PMM Ponderado**

```dax
( [Preço Médio Liquido] * [Peso Liquido] + [Preço Médio Pedido] * [Total QTD Pedido] + [Preço Médio PedidoAB] * [Total QTD PedidoAB] ) / ( [Peso Liquido] + [Total QTD Pedido] + [Total QTD PedidoAB])
```

**% PMG x PMT**

```dax
VAR vValor = DIVIDE( [Preço Médio Tabelado] - [PMM Ponderado], [Preço Médio Tabelado] ) VAR VFormat = FORMAT( ABS(vValor), "0.00%" ) RETURN IF( [PMM Ponderado] < [Preço Médio Tabelado], "⇩ " & VFormat, "⇧ " & VFormat )
```

**Faturamento Total Geral**

```dax
CALCULATE([Venda Real Liquida], ALL(dRedes[Redes]))
```

**% Faturamento**

```dax
DIVIDE([Venda Real Liquida], [Faturamento Total Geral])
```

**Rank Faturamento**

```dax
RANKX(ALL(dRedes[Redes]), [Venda Real Liquida], , DESC, Dense)
```

**Faturamento Acumulado**

```dax
VAR RankingAtual = [Rank Faturamento] RETURN CALCULATE( [Venda Real Liquida], FILTER( ALL(dRedes[Redes]), [Rank Faturamento] <= RankingAtual ) )
```

**% Acumulado**

```dax
DIVIDE([Faturamento Acumulado], [Faturamento Total Geral])
```

**Curva ABC**

```dax
IF([% Acumulado] <= 0.8, "A", IF([% Acumulado] <= 0.95, "B", "C") )
```

**Custo Total**

```dax
AVERAGE(TebelaPrecosConsu[CustoUnitario])
```

**ICMS**

```dax
AVERAGE(fFaturamento[ICMS]) / 100
```

**Pis**

```dax
AVERAGE(fFaturamento[PIS]) / 100
```

**Cofins**

```dax
AVERAGE(fFaturamento[COFINS]) / 100
```

**GGF**

```dax
0.04
```

**Fin**

```dax
0.045
```

**Mk-UP**

```dax
DIVIDE([Custo Total],[Preço Médio Liquido])
```

**Margem**

```dax
-(1 - [Mk-UP] - [% COMISS] - [GGF] - [ICMS] - [Pis] - [Cofins] - [Fin])
```

**% COMISS**

```dax
AVERAGE(fFaturamento[_%COMISVEND])
```

**Volume Período Anterior**

```dax
VAR PeriodoSelecionado = MAX('DCalendario'[Data]) - MIN('DCalendario'[Data]) + 1 RETURN CALCULATE( [Peso Liquido], DATEADD('DCalendario'[Data], -PeriodoSelecionado, DAY) )
```

**Faturamento Período Anterior**

```dax
VAR PeriodoSelecionado = MAX('DCalendario'[Data]) - MIN('DCalendario'[Data]) + 1 RETURN CALCULATE( [Venda Real Liquida], DATEADD('DCalendario'[Data], -PeriodoSelecionado, DAY) )
```

**Preço Líq Período Anterior**

```dax
VAR PeriodoSelecionado = MAX('DCalendario'[Data]) - MIN('DCalendario'[Data]) + 1 RETURN CALCULATE( [Preço Médio Liquido], DATEADD('DCalendario'[Data], -PeriodoSelecionado, DAY) )
```

**Diferença Período Anterior**

```dax
[Peso Liquido] - [Volume Período Anterior]
```

**% Variação Período Anterior**

```dax
DIVIDE( [Diferença Período Anterior], [Volume Período Anterior] )
```

**Diferença PM Período Anterior**

```dax
[Preço Médio Liquido] - [Preço Líq Período Anterior]
```

**% Variação PM Período Anterior**

```dax
DIVIDE( [Diferença PM Período Anterior], [Preço Líq Período Anterior] )
```

**Diferença FAT Período Anterior**

```dax
[Venda Real Liquida] - [Faturamento Período Anterior]
```

**% Variação FAT Período Anterior**

```dax
DIVIDE( [Diferença FAT Período Anterior], [Faturamento Período Anterior] )
```

**Cor da Variação**

```dax
VAR Valor = [% Variação Período Anterior] RETURN IF( Valor < 0, "#EFB5B9", -- Vermelho para valores negativos IF( Valor > 0, "#CFEFB5", -- Verde para valores positivos "#FFFFFF" -- Preto para zero ) )
```

**Variação com Símbolo**

```dax
VAR Valor = [% Variação Período Anterior] VAR Simbolo = IF( Valor < 0, "▼ ", -- Seta para baixo e espaço IF( Valor > 0, "▲ ", -- Seta para cima e espaço "" ) ) RETURN Simbolo & FORMAT(Valor, "0.00%")
```

**Cor da Variação PM**

```dax
VAR Valor = [% Variação PM Período Anterior] RETURN IF( Valor < 0, "#EFB5B9", -- Vermelho para valores negativos IF( Valor > 0, "#CFEFB5", -- Verde para valores positivos "#FFFFFF" -- Preto para zero ) )
```

**Cor da Variação FAT**

```dax
VAR Valor = [% Variação FAT Período Anterior] RETURN IF( Valor < 0, "#EFB5B9", -- Vermelho para valores negativos IF( Valor > 0, "#CFEFB5", -- Verde para valores positivos "#FFFFFF" -- Preto para zero ) )
```

**Dica de Ferramenta Detalhada**

```dax
VAR ValorAtual = [Preço Médio Liquido] VAR ValorAnterior = [Preço Líq Período Anterior] VAR PercentualVariacaoVolume = [% Variação PM Período Anterior] VAR DataInicioSelecionada = MIN('DCalendario'[Data]) VAR DataFimSelecionada = MAX('DCalendario'[Data]) VAR PesoLiquidoAtual = [Peso Liquido] VAR PesoLiquidoAnterior = [Volume Período Anterior] VAR PercentualVariacaoPeso = [% Variação Período Anterior] VAR PeriodoSelecionadoEmDias = DataFimSelecionada - DataInicioSelecionada + 1 VAR DataInicioAnterior = DataInicioSelecionada - PeriodoSelecionadoEmDias VAR DataFimAnterior = DataFimSelecionada - PeriodoSelecionadoEmDias RETURN "--- Análise do Período ---" & UNICHAR(10) & "Período Atual: " & FORMAT(DataInicioSelecionada, "dd/mm/yyyy") & " a " & FORMAT(DataFimSelecionada, "dd/mm/yyyy") & UNICHAR(10) & "Período Anterior: " & FORMAT(DataInicioAnterior, "dd/mm/yyyy") & " a " & FORMAT(DataFimAnterior, "dd/mm/yyyy") & UNICHAR(10) & "---" & UNICHAR(10) & "Preço Médio Líquido" & UNICHAR(10) & "   Atual: " & FORMAT(ValorAtual, "#,##0.00") & UNICHAR(10) & "   Anterior: " & FORMAT(ValorAnterior, "#,##0.00") & UNICHAR(10) & "   Variação %: " & FORMAT(PercentualVariacaoVolume, "0.00%") & UNICHAR(10) & "---" & UNICHAR(10) & "Peso Líquido Total" & UNICHAR(10) & "   Atual: " & FORMAT(PesoLiquidoAtual, "#,##0.00") & UNICHAR(10) & "   Anterior: " & FORMAT(PesoLiquidoAnterior, "#,##0.00") & UNICHAR(10) & "   Variação %: " & FORMAT(PercentualVariacaoPeso, "0.00%")
```

**Dica de Ferramenta Completa**

```dax
``` VAR ValorAtualPM = [Preço Médio Liquido] VAR ValorAnteriorPM = [Preço Líq Período Anterior] VAR VariacaoPM = [% Variação PM Período Anterior] VAR PesoLiquidoAtual = [Peso Liquido] VAR PesoLiquidoAnterior = CALCULATE ( [Peso Liquido], DATEADD('DCalendario'[Data], MIN('DCalendario'[Data]) - MAX('DCalendario'[Data]) - 1, DAY) ) VAR PercentualVariacaoPeso = DIVIDE([Peso Liquido] - PesoLiquidoAnterior, PesoLiquidoAnterior) VAR DataInicioSelecionada = MIN('DCalendario'[Data]) VAR DataFimSelecionada = MAX('DCalendario'[Data]) VAR PeriodoSelecionadoEmDias = DataFimSelecionada - DataInicioSelecionada + 1 VAR DataInicioAnterior = DataInicioSelecionada - PeriodoSelecionadoEmDias VAR DataFimAnterior = DataFimSelecionada - PeriodoSelecionadoEmDias -- Análise de Contribuição de VOLUME para o Preço Médio -- VAR TabelaContribuicaoVolume = SUMMARIZE( 'dFamilia', 'dFamilia'[FAMILIA], "Variação Volume", [Diferença Período Anterior], "Variação Volume %", [% Variação Período Anterior] ) VAR TopGanhadorVolume = TOPN(1, TabelaContribuicaoVolume, [Variação Volume], DESC) VAR TopPerdedorVolume = TOPN(1, TabelaContribuicaoVolume, [Variação Volume], ASC) VAR NomeTopGanhadorVolume = MAXX(TopGanhadorVolume, [FAMILIA]) VAR PercentualTopGanhadorVolume = MAXX(TopGanhadorVolume, [Variação Volume %]) VAR NomeTopPerdedorVolume = MAXX(TopPerdedorVolume, [FAMILIA]) VAR PercentualTopPerdedorVolume = MAXX(TopPerdedorVolume, [Variação Volume %]) -- Análise de Contribuição de FATURAMENTO para o Faturamento -- VAR FaturamentoAtual = [Venda Real Liquida] VAR FaturamentoAnterior = [Faturamento Período Anterior] VAR VariacaoFaturamento = DIVIDE(FaturamentoAtual - FaturamentoAnterior, FaturamentoAnterior) VAR TabelaContribuicaoFaturamento = SUMMARIZE( 'dFamilia', 'dFamilia'[FAMILIA], "Variacao Faturamento", [Venda Real Liquida] - [Faturamento Período Anterior], "Contribuição %", DIVIDE([Venda Real Liquida] - [Faturamento Período Anterior], FaturamentoAtual - FaturamentoAnterior) ) VAR TopGanhadorFaturamento = TOPN(1, TabelaContribuicaoFaturamento, [Variacao Faturamento], DESC) VAR TopPerdedorFaturamento = TOPN(1, TabelaContribuicaoFaturamento, [Variacao Faturamento], ASC) VAR NomeTopGanhadorFaturamento = MAXX(TopGanhadorFaturamento, [FAMILIA]) VAR ContribuicaoTopGanhador = MAXX(TopGanhadorFaturamento, [Contribuição %]) VAR NomeTopPerdedorFaturamento = MAXX(TopPerdedorFaturamento, [FAMILIA]) VAR ContribuicaoTopPerdedor = MAXX(TopPerdedorFaturamento, [Contribuição %]) -- Variáveis de Análise Final -- VAR AnalisePM = IF(VariacaoPM > 0.02, "O ticket médio cresceu em relação ao período anterior, o que pode indicar um aumento na venda do mix de produtos de maior valor agregado.", IF(VariacaoPM < -0.02, "O ticket médio caiu em relação ao período anterior. Uma possível causa pode ser descontos demaziados, sazonalidades ou mudanças na composição do mix de venda, com itens mais de menor valor agregado.", "O ticket médio líquido se manteve estável em relação ao período anterior.")) VAR AnalisePeso = IF(PercentualVariacaoPeso > 0.02, "O volume líquido aumentou, sugerindo um crescimento nas vendas ou a utilização de produtos com peso maior no mix.", IF(PercentualVariacaoPeso < -0.02, "O volume líquido diminuiu, o que pode indicar uma queda nas vendas ou a utilização de produtos com peso menor no mix.", "O mix de produtos vendidos se manteve consistente em peso.")) VAR AnaliseCausaTM = IF(VariacaoPM > 0, "Essa alta no TM foi influenciada principalmente pelo aumento de " & FORMAT(PercentualTopGanhadorVolume, "0.00%") & " no volume de vendas da família " & NomeTopGanhadorVolume & ".", IF(VariacaoPM < 0, "Essa queda no TM foi influenciada principalmente pela queda de " & FORMAT(ABS(PercentualTopPerdedorVolume), "0.00%") & " no volume de vendas da família " & NomeTopPerdedorVolume & ", que geralmente tem um preço maior.", "Não houve um fator predominante do mix de volume que tenha impactado o TM.")) VAR AnaliseCausaFaturamento = IF(VariacaoFaturamento > 0, "O faturamento cresceu devido ao forte desempenho da família " & NomeTopGanhadorFaturamento & ", que foi a principal responsável por " & FORMAT(ContribuicaoTopGanhador, "0.00%") & " do aumento de receita.", IF(VariacaoFaturamento < 0, "O faturamento caiu, puxado pela queda na receita da família " & NomeTopPerdedorFaturamento & ", que teve o maior impacto negativo, representando " & FORMAT(ContribuicaoTopPerdedor, "0.00%") & " da variação total.", "Apesar da estabilidade, é importante analisar os fatores que mantiveram o faturamento.")) RETURN "--- Análise do Período ---" & UNICHAR(10) & "Período Atual: " & FORMAT(DataInicioSelecionada, "dd/mm/yyyy") & " a " & FORMAT(DataFimSelecionada, "dd/mm/yyyy") & UNICHAR(10) & "Período Anterior: " & FORMAT(DataInicioAnterior, "dd/mm/yyyy") & " a " & FORMAT(DataFimAnterior, "dd/mm/yyyy") & UNICHAR(10) & UNICHAR(9472) & UNICHAR(10) & "Análise Geral:" & UNICHAR(10) & "Faturamento: " & FORMAT(VariacaoFaturamento, "0.00%") & " em relação ao período anterior." & UNICHAR(10) & "Preço Médio: " & FORMAT(VariacaoPM, "0.00%") & " em relação ao período anterior." & UNICHAR(10) & "Peso Líquido: " & FORMAT(PercentualVariacaoPeso, "0.00%") & " em relação ao período anterior." & UNICHAR(10) & UNICHAR(9472) & UNICHAR(10) & "Análise de Causa:" & UNICHAR(10) & AnalisePM & UNICHAR(10) & AnaliseCausaTM & UNICHAR(10) & UNICHAR(9472) & UNICHAR(10) & "Impacto no Faturamento:" & UNICHAR(10) & AnaliseCausaFaturamento ```
```

**Dias Desde Última Compra**

```dax
VAR _UltimaCompra = CALCULATE( MAXX(dClientes, dClientes[_DTAULTCOMPRA]), ALL(dVendedores[_NOMEVEND]), ALL(dVendedores[_NOMEGERENTE]) ) VAR _Hoje = TODAY() RETURN IF( NOT ISBLANK(_UltimaCompra), DATEDIFF(_UltimaCompra, _Hoje, DAY), BLANK() )
```

**Status Cliente**

```dax
IF( [Dias Desde Última Compra] > 90, "Inativo (Mais de 90 dias)", IF( [Dias Desde Última Compra] > 60, "Alerta (61-90 dias)", IF( [Dias Desde Última Compra] > 30, "Monitorado (31-60 dias)", "Ativo" ) ) )
```

**Qtd Clientes Inativos**

```dax
COUNTROWS(dClientes)
```

**Ticket Médio Real**

```dax
DIVIDE( [Venda Real Liquida], DISTINCTCOUNT(fFaturamento[NFE]) )
```

**Potencial de Receita**

```dax
[Qtd Clientes Inativos] * [Ticket Médio Real]
```

**Valor Histórico**

```dax
CALCULATE([Venda Real Liquida], ALLEXCEPT(dClientes, dClientes[_CGCCLIENTE]))
```

**Teste_Ultima_Compra_Global**

```dax
CALCULATE( MAXX(dClientes, dClientes[_DTAULTCOMPRA]), ALL(dClientes[_CODVEND]), ALL(dClientes[_GERENTE]) )
```

**ICMS ST**

```dax
SUM(fFaturamento[ICMSST])
```

**Total Vendido c/ ST**

```dax
[Total Vendido] + [ICMS ST]
```

**Rateio Refat.TOTAL Proporcional**

```dax
``` SUMX( -- 1. A tabela para iterar: Todas as linhas de devolução visíveis no contexto atual. 'fDevoluções', -- 2. A expressão para somar (a sua lógica de rateio original, adaptada para o contexto de linha): VAR TotalRefatGrupo = CALCULATE( MAX('fDevoluções'[Refat.TOTAL]), ALLEXCEPT( 'fDevoluções', 'fDevoluções'[EMISSAO], 'fDevoluções'[NFORIGEM], 'fDevoluções'[NF], 'fDevoluções'[Refat.NFE] ) ) VAR TotalQTDGrupo = CALCULATE( SUM('fDevoluções'[QTD]), ALLEXCEPT( 'fDevoluções', 'fDevoluções'[EMISSAO], 'fDevoluções'[NFORIGEM], 'fDevoluções'[NF], 'fDevoluções'[Refat.NFE] ) ) VAR NumeroDeItens = CALCULATE( COUNTROWS('fDevoluções'), ALLEXCEPT( 'fDevoluções', 'fDevoluções'[EMISSAO], 'fDevoluções'[NFORIGEM], 'fDevoluções'[NF], 'fDevoluções'[Refat.NFE] ) ) -- As variáveis de linha agora são referências diretas no contexto de linha do SUMX. VAR QTD_Atual = 'fDevoluções'[QTD] VAR TotalRefat_Atual = 'fDevoluções'[Refat.TOTAL] VAR ResultadoRateio = IF( -- NOTA: O critério de >= 2 será sempre verdade para o grupo em si. -- No contexto de linha do SUMX, ele vai avaliar a linha individualmente, -- mas os totais de grupo se manterão fixos. NumeroDeItens >= 2, DIVIDE(QTD_Atual, TotalQTDGrupo) * TotalRefatGrupo, TotalRefat_Atual ) RETURN ResultadoRateio ) ```
```

**Total Bonificação**

```dax
SUM(fFaturamentoBonific[TOTAL])
```

**Peso Total Bonif**

```dax
SUMX(DISTINCT(fFaturamentoBonific), [QTD])
```

**Preço Médio Bonif**

```dax
[Total Bonificação] / [Peso Total Bonif]
```

**Rank > Bonif P/ Cliente**

```dax
RANKX(ALL(dClientes[_NOMECLIENTE]), [Total Bonificação])
```

**Total - Dev**

```dax
SUM(fFaturamento[Total - Dev])
```

**Total - Dev KG**

```dax
SUM(fFaturamento[Total - Dev KG])
```
