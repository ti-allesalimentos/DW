# Modelo semantico: Comercial

- Tabelas: 49
- Colunas: 490
- Medidas DAX: 254
- Relacionamentos: 42 (0 inativos, 1 bidirecionais)

## Tabelas

| Tabela | Colunas | Medidas |
|--------|--------:|--------:|
| Consulta1 | 6 | 0 |
| DateTableTemplate_a08fe442-a827-4200-a749-76ada83c5c58 | 7 | 0 |
| FCustosMédios | 3 | 0 |
| FPromotores | 9 | 0 |
| FluxoPedidosVenda | 1 | 0 |
| FluxodClientes | 1 | 0 |
| FluxodProdutos | 1 | 0 |
| FluxodVendedores | 1 | 0 |
| FluxofFaturamento | 1 | 0 |
| LocalDateTable_039de807-ad26-4957-bf39-741a04a18dec | 7 | 0 |
| LocalDateTable_09401253-75db-4ebd-867b-6f191e069050 | 7 | 0 |
| LocalDateTable_414a0f5e-c236-4c98-8312-f38251c8b035 | 7 | 0 |
| LocalDateTable_68bc8c23-a273-47cc-9ba6-0b6b1fb53e35 | 7 | 0 |
| LocalDateTable_72a2682f-f2a2-470b-b63e-d23dece2b3a1 | 7 | 0 |
| LocalDateTable_76011d6c-c820-4035-bbfe-5356033060e4 | 7 | 0 |
| LocalDateTable_7752f8c2-dbd5-419d-a2fb-2c28ad0e281e | 7 | 0 |
| LocalDateTable_95ffbda9-e4b8-462d-9d89-a6dc80b20de4 | 7 | 0 |
| LocalDateTable_98d2f619-d571-4c3d-a2b3-9b29ab2b42d1 | 7 | 0 |
| LocalDateTable_b365a8a8-ca31-45bb-b92d-7f29fcc5261a | 7 | 0 |
| LocalDateTable_c404b773-3e33-4be5-96dd-65e1e6aaf67a | 7 | 0 |
| LocalDateTable_fcce0471-f6cc-4368-a719-4a8ea5b621c0 | 7 | 0 |
| Tabela14 | 3 | 0 |
| _MEDIDAS | 0 | 254 |
| auxClasse | 3 | 0 |
| auxFrequencia | 4 | 0 |
| auxPVM | 2 | 0 |
| auxRecencia | 4 | 0 |
| auxValor | 4 | 0 |
| dBaseRedes | 1 | 0 |
| dCalendario | 115 | 0 |
| dClientes | 27 | 0 |
| dCondPgt | 4 | 0 |
| dFamilia | 6 | 0 |
| dFamiliaConsolidada | 1 | 0 |
| dGerentes | 4 | 0 |
| dProdutos | 14 | 0 |
| dRedes | 3 | 0 |
| dVendedores | 7 | 0 |
| dVendedoresExlcluidos | 6 | 0 |
| fAcordoComercial | 18 | 0 |
| fDevoluções | 21 | 0 |
| fFaturamento | 26 | 0 |
| fFaturamentoConsolidado | 24 | 0 |
| fFaturamentoDataVale | 12 | 0 |
| fFaturamentoDtaVale | 10 | 0 |
| fMetasdevendas | 6 | 0 |
| fMetasdevendas26 | 6 | 0 |
| fPedidosdeEmbarque | 31 | 0 |
| fProspects | 14 | 0 |

## Relacionamentos

| De | Para | Cardinalidade | Filtro | Ativo |
|----|------|---------------|--------|-------|
| fFaturamento._CHAVECLIENTE | dClientes._CHAVECLIENTE | many->one | singleDirection | sim |
| dClientes._CODRED | dRedes.ACY_GRPVEN | many->one | singleDirection | sim |
| fFaturamento._CODPRODVEND | dProdutos._CODPRODUTO | many->one | singleDirection | sim |
| fFaturamentoDtaVale._DTEMISSAO | LocalDateTable_76011d6c-c820-4035-bbfe-5356033060e4.Date | many->one | singleDirection | sim |
| fFaturamentoConsolidado._CHAVECLIENTE | dClientes._CHAVECLIENTE | many->one | singleDirection | sim |
| fFaturamentoConsolidado._CODPRODVEND | dProdutos._CODPRODUTO | many->one | singleDirection | sim |
| fPedidosdeEmbarque.EMISSAONF | LocalDateTable_68bc8c23-a273-47cc-9ba6-0b6b1fb53e35.Date | many->one | singleDirection | sim |
| fPedidosdeEmbarque.CODPROD | dProdutos._CODPRODUTO | many->one | singleDirection | sim |
| fPedidosdeEmbarque.CHAVECLIENTE | dClientes._CHAVECLIENTE | many->one | singleDirection | sim |
| fPedidosdeEmbarque.DTEMBARQUE | LocalDateTable_b365a8a8-ca31-45bb-b92d-7f29fcc5261a.Date | many->one | singleDirection | sim |
| dClientes._DTAULTCOMPRA | LocalDateTable_09401253-75db-4ebd-867b-6f191e069050.Date | many->one | singleDirection | sim |
| fDevoluções.CHAVECLI | dClientes._CHAVECLIENTE | many->one | singleDirection | sim |
| fDevoluções.CODPROD | dProdutos._CODPRODUTO | many->one | singleDirection | sim |
| fAcordoComercial.CHAVECLI | dClientes._CHAVECLIENTE | many->one | singleDirection | sim |
| fAcordoComercial.CODPROD | dProdutos._CODPRODUTO | many->one | singleDirection | sim |
| fDevoluções.LANCAMENTO | LocalDateTable_7752f8c2-dbd5-419d-a2fb-2c28ad0e281e.Date | many->one | singleDirection | sim |
| fDevoluções.NFORIGEM | fFaturamentoConsolidado._NFEVENDA | many->many | singleDirection | sim |
| dClientes.DTCADASTRO | LocalDateTable_414a0f5e-c236-4c98-8312-f38251c8b035.Date | many->one | singleDirection | sim |
| FCustosMédios.Data | LocalDateTable_98d2f619-d571-4c3d-a2b3-9b29ab2b42d1.Date | many->one | singleDirection | sim |
| fDevoluções.DTAEMISSNFORI | LocalDateTable_c404b773-3e33-4be5-96dd-65e1e6aaf67a.Date | many->one | singleDirection | sim |
| FPromotores.CHAVE | dClientes._CHAVECLIENTE | many->one | singleDirection | sim |
| FPromotores.Data | dCalendario.Data | many->one | singleDirection | sim |
| fFaturamentoConsolidado._DTEMISSAO | dCalendario.Data | many->one | singleDirection | sim |
| fPedidosdeEmbarque.EMISSAOPED | dCalendario.Data | many->one | singleDirection | sim |
| fDevoluções.EMISSAO | dCalendario.Data | many->one | singleDirection | sim |
| fMetasdevendas.Data | dCalendario.Data | many->one | singleDirection | sim |
| fFaturamento._DTEMISSAO | dCalendario.Data | many->one | singleDirection | sim |
| dProdutos._DTAULTCOMPRA | LocalDateTable_72a2682f-f2a2-470b-b63e-d23dece2b3a1.Date | many->one | singleDirection | sim |
| dProdutos._FAMILIAPROD | dFamiliaConsolidada._FAMILIAPROD | many->one | singleDirection | sim |
| fMetasdevendas.Produto | dFamiliaConsolidada._FAMILIAPROD | many->one | singleDirection | sim |
| fFaturamentoDataVale.'Coluna 10' | LocalDateTable_039de807-ad26-4957-bf39-741a04a18dec.Date | many->one | singleDirection | sim |
| fMetasdevendas.Vendedor | dVendedores._CODVEND | many->one | singleDirection | sim |
| fAcordoComercial.EMISSAO | LocalDateTable_95ffbda9-e4b8-462d-9d89-a6dc80b20de4.Date | many->one | singleDirection | sim |
| fAcordoComercial.'fFaturamento._DTEMISSAO' | dCalendario.Data | many->one | singleDirection | sim |
| dClientes._CODVEND | dVendedores._CODVEND | many->one | singleDirection | sim |
| dClientes._GERENTE | dGerentes._CODVEND | many->one | singleDirection | sim |
| fMetasdevendas.Gerente | dGerentes._CODVEND | many->one | singleDirection | sim |
| Tabela14._CODVEND | dGerentes._CODVEND | one->one | bothDirections | sim |
| fProspects.DTCADASTRO | dCalendario.Data | many->one | singleDirection | sim |
| dRedes.Redes | dBaseRedes.Redes | many->one | singleDirection | sim |
| fMetasdevendas26.Data | LocalDateTable_fcce0471-f6cc-4368-a719-4a8ea5b621c0.Date | many->one | singleDirection | sim |
| fProspects.US_VEND | dVendedores._CODVEND | many->one | singleDirection | sim |

## Medidas DAX

### _MEDIDAS

**Faturamento (Atual)**

```dax
SUM(fFaturamentoConsolidado[_TOTALVENDA])
```

**Notas Emitidas**

```dax
DISTINCTCOUNT(fFaturamentoConsolidado[_NFEVENDA])
```

**Preço Médio (Atual)**

```dax
DIVIDE([Faturamento (Atual)], [Peso Total (Atual)])
```

**Peso Total (Atual)**

```dax
SUM(fFaturamentoConsolidado[_QTDVENDA])
```

**Rank Vendedor $**

```dax
RANKX( ALLSELECTED(dVendedores), [Faturamento (Atual)] )
```

**Notas Emitidas LY**

```dax
CALCULATE( [Notas Emitidas], SAMEPERIODLASTYEAR(dCalendario[Data]) )
```

**Fat. Ano Anterior**

```dax
CALCULATE( [Faturamento (Atual)], DATEADD(dCalendario[Data], -1, YEAR) )
```

**% Notas Emitidas YoY**

```dax
DIVIDE([Notas Emitidas] - [Notas Emitidas LY], [Notas Emitidas LY])
```

**% Faturamento YoY**

```dax
DIVIDE([Faturamento (Atual)] - [Fat. Ano Anterior], [Fat. Ano Anterior])
```

**Preço Médio LY**

```dax
CALCULATE( [Preço Médio (Atual)], SAMEPERIODLASTYEAR(dCalendario[Data]) )
```

**Peso Total LY**

```dax
CALCULATE( [Peso Total (Atual)], DATEADD(dCalendario[Data], -1, YEAR) )
```

**% Preço YoY**

```dax
DIVIDE([Preço Médio (Atual)] - [Preço Médio LY], [Preço Médio LY])
```

**% Peso YoY**

```dax
DIVIDE([Peso Total (Atual)] - [Peso Total LY], [Peso Total LY])
```

**KG Meta**

```dax
sum(fMetasdevendas[MetaDiaria])
```

**% Ating Meta (KG)**

```dax
DIVIDE([Peso Total (Atual)], [KG Meta], 0)
```

**Fator Vendedor**

```dax
``` VAR vCountVendedores = COUNTROWS(dVendedores) VAR VCountVendedoresPorGerente = CALCULATE( COUNTROWS(dVendedores), ALL(dVendedores), VALUES(dGerentes[_NOMEVEND]) ) VAR VFator = DIVIDE(vCountVendedores, VCountVendedoresPorGerente) RETURN VFator ```
```

**Total Meta Gerente**

```dax
SUMX(FILTER(fMetasdevendas, NOT(ISBLANK(fMetasdevendas[Gerente]))), fMetasdevendas[MetaDiaria])
```

**Fator Familia de Produto**

```dax
``` VAR vFatPY = CALCULATE( [Faturamento Liquido], PREVIOUSQUARTER(dCalendario[Data]) ) VAR vFatPYTotal = CALCULATE( [Faturamento Liquido], PREVIOUSQUARTER(dCalendario[Data]), ALL(dFamiliaConsolidada[_FAMILIAPROD]) ) VAR VFator = DIVIDE(vFatPY, vFatPYTotal) RETURN VFator ```
```

**Meta Diluída**

```dax
``` sumx( CROSSJOIN( VALUES(dFamiliaConsolidada[_FAMILIAPROD]), VALUES(dGerentes[_NOMEVEND]) ), [Meta Total] ) ```
```

**Meta Total**

```dax
sum(fMetasdevendas[MetaDiaria])
```

**% Ating**

```dax
- ( DIVIDE([Meta Total] - [Peso Liquido Vendido], [Meta Total]) ) + 1
```

**% Faturamento vs Meta Cartão**

```dax
VAR vValor = DIVIDE ( [Peso Liquido Vendido], [Meta Diluída]) VAR vFormat = FORMAT(vValor, "⇧ 0% acima da meta; ⇩ 0% abaixo da meta") RETURN vFormat
```

**Rótulo Barras**

```dax
``` VAR vFat = [Peso Liquido Vendido] VAR vFatFormat = FORMAT(vFat, "#,##0 KG") VAR vMetaFormat = FORMAT([% Ating], "⇧ 0.0%; ⇩ 0.0%") RETURN vFatFormat & " | " & vMetaFormat ```
```

**Rank Vendedor KG**

```dax
RANKX(ALL(dVendedores[_NOMEVEND]), [Peso Liquido Vendido])
```

**Meta KG MTD**

```dax
CALCULATE( [Meta Diluída], DATESMTD(dCalendario[Data]) )
```

**Fat KG MTD**

```dax
CALCULATE( [Peso Total (Atual)], DATESMTD(dCalendario[Data]) )
```

**Fat KG MTD Até Hoje**

```dax
CALCULATE( [Fat KG MTD], dCalendario[Passado] = TRUE() )
```

**KG Forecast**

```dax
VAR VMetaRestante = CALCULATE( [Meta Diluída], dCalendario[Passado] = FALSE() ) RETURN [Fat. KG (Atual)] + VMetaRestante
```

**Fat. KG (Atual)**

```dax
SUM(fFaturamentoConsolidado[_QTDVENDA])
```

**KG Forecast MTD**

```dax
CALCULATE( [KG Forecast], DATESMTD(dCalendario[Data]) )
```

**KG Fat vs Meta**

```dax
[Peso Liquido Vendido] - [Meta Diluída]
```

**% Fat KG vs Meta KG**

```dax
DIVIDE ( [KG Fat vs Meta], [Meta Diluída])
```

**% Fat (kg) vs Meta (kg) Cartão**

```dax
VAR vValor = DIVIDE ( [KG Fat vs Meta], [Meta Diluída]) VAR vFormat = FORMAT(vValor, "⇧ 0.00% acima da meta KG; ⇩ 0.00 abaixo da meta KG%") RETURN vFormat
```

**Meta Diária Original**

```dax
``` VAR vMetaDia = DIVIDE( [KG Forecast MTD], [Dias Úteis] ) VAR vResult = FORMAT(vMetaDia, "KG #,0") RETURN "Meta Diária Original: " & vResult ```
```

**Dias Úteis**

```dax
CALCULATE( COUNTROWS(dCalendario), NOT(dCalendario[DiaDaSemanaNumero] IN {0,6}) )
```

**Última Venda de Produto**

```dax
CALCULATE( MAX(fFaturamentoConsolidado[_DTEMISSAO]), dCalendario[Data] < MAX(dCalendario[Data]) )
```

**Dias Realizados**

```dax
CALCULATE( COUNTROWS(dCalendario), NOT(dCalendario[DiaDaSemanaNumero] IN {0,6}), dCalendario[Passado] = TRUE() )
```

**Meta (KG) MTD**

```dax
CALCULATE( [Meta Total], DATESMTD(dCalendario[Data]) )
```

**Meta (KG) MTD Até Hoje**

```dax
``` VAR vMetaAtual = CALCULATE( [Meta KG MTD], dCalendario[Passado] = TRUE() ) RETURN vMetaAtual ```
```

**Meta Diária Nova**

```dax
``` VAR vDiferencaValor = [Meta (KG) MTD Até Hoje] - [Fat KG MTD Até Hoje] VAR vDiasRestantes = [Dias Úteis] - [Dias Realizados] VAR vAjusteMeta = DIVIDE( vDiferencaValor, vDiasRestantes ) VAR vMetaDiariaOriginal = DIVIDE( [Meta (KG) MTD], [Dias Úteis] ) VAR vNovaMeta = vMetaDiariaOriginal + vAjusteMeta VAR vNovaMetaCorrigida = IF( vNovaMeta > 0, vNovaMeta, 0 ) VAR vResult = FORMAT(vNovaMetaCorrigida, "KG #,0") RETURN "Para Atingimento da Meta do mês é necessario um faturamento diário de: " & vResult ```
```

**Max Gauge MTD**

```dax
MAX([Meta (KG) MTD], [KG Forecast MTD]) * 1.2
```

**test**

```dax
``` VAR vDiferencaValor = [Meta (KG) MTD Até Hoje] - [Fat KG MTD Até Hoje] VAR vDiasRestantes = [Dias Úteis] - [Dias Realizados] VAR vAjusteMeta = DIVIDE( vDiferencaValor, vDiasRestantes ) VAR vMetaDiariaOriginal = DIVIDE( [Meta (KG) MTD], [Dias Úteis] ) VAR vNovaMeta = vMetaDiariaOriginal + vAjusteMeta VAR vNovaMetaCorrigida = IF( vNovaMeta > 0, vNovaMeta, 0 ) VAR vResult = FORMAT(vNovaMetaCorrigida, "R$ #,0") RETURN [Fat KG MTD Até Hoje] + (vResult * vDiasRestantes) ```
```

**% Fat (kg) vs Meta (kg) Cartão 2**

```dax
VAR vValor = DIVIDE ([KG Forecast MTD], [Meta (KG) MTD]) - 1 VAR vFormat = FORMAT(vValor, "⇧ 0.00% acima da meta; ⇩ 0.00% abaixo da meta KG") RETURN vFormat
```

**Peso (kG) Vendido MONTH (-1)**

```dax
CALCULATE( [Peso Total (Atual)], PARALLELPERIOD(dCalendario[Data], -1, MONTH) )
```

**Peso (kG) Vendido MONTH (-2)**

```dax
CALCULATE( [Peso Total (Atual)], PARALLELPERIOD(dCalendario[Data], -2, MONTH) )
```

**Peso (kG) Vendido MONTH (-3)**

```dax
CALCULATE( [Peso Total (Atual)], PARALLELPERIOD(dCalendario[Data], -3, MONTH) )
```

**Peso (kG) Vendido MONTH (-6)**

```dax
CALCULATE( [Peso Total (Atual)], PARALLELPERIOD(dCalendario[Data], -6, MONTH) )
```

**Peso (kG) Vendido MONTH (-12)**

```dax
CALCULATE( [Peso Total (Atual)], PARALLELPERIOD(dCalendario[Data], -12, MONTH) )
```

**Ticket Médio (Atual)**

```dax
DIVIDE([Faturamento (Atual)], [Notas Emitidas])
```

**Ticket Médio LY**

```dax
DIVIDE([Fat. Ano Anterior], [Notas Emitidas LY])
```

**% TM YoY**

```dax
DIVIDE([Ticket Médio (Atual)] - [Ticket Médio LY], [Ticket Médio LY])
```

**Clientes sem Faturamento há +60 dias**

```dax
``` VAR DataReferencia = MAX(dCalendario[Data]) -- Data selecionada no contexto VAR UltimaVendaCliente = CALCULATE( MAX(fFaturamentoConsolidado[_DTEMISSAO]), ALLEXCEPT(fFaturamentoConsolidado, fFaturamentoConsolidado[_CHAVECLIENTE]), fFaturamentoConsolidado[_DTEMISSAO] <= DataReferencia ) RETURN IF( ISBLANK(UltimaVendaCliente) || UltimaVendaCliente <= DataReferencia - 60, UltimaVendaCliente, BLANK() ) ```
```

**Pedidos sem Data de Embarque (KG)**

```dax
CALCULATE( SUM(fPedidosdeEmbarque[QTD]), ISBLANK(fPedidosdeEmbarque[DTEMBARQUE]), REMOVEFILTERS(dCalendario[Data] ))
```

**Dif Meta vs Realizado**

```dax
[Meta (KG) MTD] - [Fat. KG (Atual)]
```

**Fator Produto a Produto**

```dax
``` VAR vFatPY = CALCULATE( [Peso Liquido Vendido], PREVIOUSQUARTER(dCalendario[Data]) ) VAR vFatPYTotal = CALCULATE( [Peso Liquido Vendido], PREVIOUSQUARTER(dCalendario[Data]), ALL(dFamilia[_DESCRICAOPROD]) ) VAR VFator = DIVIDE(vFatPY, vFatPYTotal) RETURN VFator ```
```

**Meta Diluída 2**

```dax
``` sumx( CROSSJOIN( VALUES(dVendedores[_NOMEGERENTE]), VALUES(dFamilia[_DESCRICAOPROD]) ), [Meta Total] * [Fator Produto a Produto] ) ```
```

**Tot Devolvido**

```dax
SUM('fDevoluções'[VRTOTAL])
```

**Peso Total Devolvido**

```dax
CALCULATE( SUM('fDevoluções'[QTD]), TREATAS(VALUES('dCalendario'[Data]), 'fDevoluções'[EMISSAO]) )
```

**Preço Médio Devolvido**

```dax
[Tot Devolvido] / [Peso Total Devolvido]
```

**Faturamento Liquido**

```dax
[Faturamento (Atual)] - [Tot Devolvido] - [Total de Acordo Comercial] - [$ TOT DESC]
```

**Peso Liquido Vendido**

```dax
``` [Peso Total (Atual)] - [Peso Total Devolvido] ```
```

**Preço Médio Líquido**

```dax
[Faturamento Liquido] / [Peso Liquido Vendido]
```

**Total de Acordo Comercial**

```dax
``` CALCULATE ( SUM(fAcordoComercial[VRTOTAL]), TREATAS ( VALUES(fFaturamento[_NFEVENDA]), fAcordoComercial[NFORIGEM] ), TREATAS ( VALUES(fFaturamento[_CODPRODVEND]), fAcordoComercial[CODPROD] ), TREATAS ( VALUES(fFaturamento[_CHAVECLIENTE]), fAcordoComercial[CHAVECLI] ), TREATAS ( VALUES(fFaturamento[_FILIALVENDA]), fAcordoComercial[FILIAL] ), TREATAS ( VALUES(fFaturamento[_ITEMVENDA]), fAcordoComercial[ITEMORI] ) ) ```
```

**%DESCTOT**

```dax
AVERAGEX( fFaturamentoConsolidado, fFaturamentoConsolidado[_%CONDESPECIAL] + fFaturamentoConsolidado[_%DESCFIN] )
```

**$ TOT DESC**

```dax
[Faturamento (Atual)] * [%DESCTOT2]
```

**% Peso MoM**

```dax
DIVIDE([Peso Total (Atual)] - [Peso (kG) Vendido MONTH (-1)], [Peso (kG) Vendido MONTH (-1)])
```

**Fat (R$) Liq. MONTH (-1)**

```dax
CALCULATE( [Faturamento Liquido 2], PARALLELPERIOD(dCalendario[Data], -1, MONTH) )
```

**% Faturamento MoM**

```dax
DIVIDE([Faturamento (Atual)] - [Fat (R$) Liq. MONTH (-1)], [Fat (R$) Liq. MONTH (-1)])
```

**Preço Médio MONTH (-1)**

```dax
CALCULATE( [Preço Médio (Atual)], PARALLELPERIOD(dCalendario[Data], -1, MONTH) )
```

**Ticket Médio MONTH (-1)**

```dax
CALCULATE( [Ticket Médio (Atual)], PARALLELPERIOD(dCalendario[Data], -1, MONTH) )
```

**% Ticket Médio MoM**

```dax
DIVIDE([Ticket Médio (Atual)] - [Ticket Médio MONTH (-1)], [Ticket Médio MONTH (-1)])
```

**% Preço MoM**

```dax
DIVIDE([Preço Médio Líquido] - [Preço Médio MONTH (-1)], [Preço Médio MONTH (-1)])
```

**NF p/ Clientes**

```dax
CALCULATE( DISTINCTCOUNT(fFaturamentoConsolidado[_CHAVECLIENTE]), DATESBETWEEN( fFaturamentoConsolidado[_DTEMISSAO], MIN(dCalendario[Data]), MAX(dCalendario[Data]) ) )
```

**NFe Mês Anterior**

```dax
CALCULATE( [Notas Emitidas], PARALLELPERIOD(dCalendario[Data], -1, MONTH) )
```

**Faturamento Liquido 2**

```dax
CALCULATE([Faturamento (Atual)]) - CALCULATE([Tot Devolvido]) - CALCULATE([Total de Acordo Comercial]) - CALCULATE([$ TOT DESC])
```

**Clientes Cadastrados**

```dax
CALCULATE( DISTINCTCOUNT(dClientes[_CHAVECLIENTE]), TREATAS(VALUES(dVendedores[_CODVEND]), dClientes[_CODVEND]) )
```

**% de Clientes Atendidos**

```dax
DIVIDE([NF p/ Clientes], [Clientes Cadastrados])
```

**Qdt de Clientes**

```dax
DISTINCTCOUNT(fFaturamentoConsolidado[_CHAVECLIENTE])
```

**Qdt Clientes Novos Trad**

```dax
``` VAR _Contexto = VALUES( fFaturamentoConsolidado[_CHAVECLIENTE] ) VAR _DataContexto = MIN (dCalendario[Data] ) VAR _Anteriores = CALCULATETABLE( VALUES( fFaturamentoConsolidado[_CHAVECLIENTE] ), dCalendario[Data] < _DataContexto ) VAR _Fonte = EXCEPT( _Contexto, _Anteriores ) RETURN COUNTROWS( _Fonte ) ```
```

**Faturamento Clientes Novos Trad**

```dax
``` VAR _Contexto = VALUES( fFaturamentoConsolidado[_CHAVECLIENTE] ) VAR _DataContexto = MIN (dCalendario[Data] ) VAR _Anteriores = CALCULATETABLE( VALUES( fFaturamentoConsolidado[_CHAVECLIENTE] ), dCalendario[Data] < _DataContexto ) VAR _Fonte = EXCEPT( _Contexto, _Anteriores ) RETURN CALCULATE( [Faturamento (Atual)], _Fonte ) ```
```

**GROSS SALES**

```dax
``` CALCULATE( SUMX(fFaturamentoConsolidado, fFaturamentoConsolidado[_QTDVENDA] * fFaturamentoConsolidado[_PRCUNITVENDA] ) ) ```
```

**QTY SOLD**

```dax
SUM (fFaturamento[_QTDVENDA])
```

**AVG PRICE ($/UNID)**

```dax
DIVIDE([GROSS SALES], [QTY SOLD])
```

**DISCOUNT**

```dax
SUM( fFaturamentoConsolidado[$DESCFIN])
```

**RETURNS**

```dax
CALCULATE( SUMX('fDevoluções', 'fDevoluções'[VRUNIT] * 'fDevoluções'[QTD] ) )
```

**TOTAL COST**

```dax
CALCULATE( SUMX(fFaturamentoConsolidado, fFaturamentoConsolidado[_QTDVENDA] * fFaturamentoConsolidado[Custo] ) )
```

**UNIT COST**

```dax
DIVIDE( [TOTAL COST], [QTY SOLD])
```

**GROSS MARGIN**

```dax
[GROSS SALES]-[DISCOUNT]-[RETURNS]-[TOTAL COST]
```

**NB OF MONTHS COMPARISON**

```dax
1
```

**GROSS SALES COMPARED**

```dax
CALCULATE( [GROSS SALES], DATEADD(dCalendario[Data], - [NB OF MONTHS COMPARISON], MONTH) )
```

**QTY SOLD COMPARED**

```dax
CALCULATE( [QTY SOLD], DATEADD(dCalendario[Data], - [NB OF MONTHS COMPARISON], MONTH) )
```

**AVG PRICE ($/UNID) COMPARED**

```dax
CALCULATE( [AVG PRICE ($/UNID)], DATEADD(dCalendario[Data], - [NB OF MONTHS COMPARISON], MONTH) )
```

**DISCOUNT COMPARED**

```dax
CALCULATE( [DISCOUNT], DATEADD(dCalendario[Data], - [NB OF MONTHS COMPARISON], MONTH) )
```

**RETURNS COMPARED**

```dax
CALCULATE( [RETURNS], DATEADD(dCalendario[Data], - [NB OF MONTHS COMPARISON], MONTH) )
```

**TOTAL COST COMPARED**

```dax
CALCULATE( [TOTAL COST], DATEADD(dCalendario[Data], - [NB OF MONTHS COMPARISON], MONTH) )
```

**UNIT COST COMPARED**

```dax
CALCULATE( [UNIT COST], DATEADD(dCalendario[Data], - [NB OF MONTHS COMPARISON], MONTH) )
```

**GROSS MARGIN COMPARED**

```dax
CALCULATE( [GROSS MARGIN], DATEADD(dCalendario[Data], - [NB OF MONTHS COMPARISON], MONTH) )
```

**VOLUME EFFECT ON SALES**

```dax
SUMX(dClientes, VAR QTY = [QTY SOLD] VAR QTY_COMP = [QTY SOLD COMPARED] RETURN IF(AND(QTY>0,QTY_COMP>0), SUMX(VALUES(dCalendario[MesAnoNome]), ([QTY SOLD] - [QTY SOLD COMPARED]) * [AVG PRICE ($/UNID) COMPARED]),0))
```

**VOLUME EFFECT ON COST**

```dax
SUMX(dClientes, VAR QTY = [QTY SOLD] VAR QTY_COMP = [QTY SOLD COMPARED] RETURN IF(AND(QTY>0,QTY_COMP>0), SUMX(VALUES(dCalendario[MesAnoNome]), -  ([QTY SOLD] - [QTY SOLD COMPARED]) * [UNIT COST COMPARED]),0))
```

**PRICE EFFECT ON SALES**

```dax
SUMX(dClientes, VAR QTY = [QTY SOLD] VAR QTY_COMP = [QTY SOLD COMPARED] RETURN IF(AND(QTY>0,QTY_COMP>0), SUMX(VALUES(dCalendario[MesAnoNome]), ([AVG PRICE ($/UNID)] - [AVG PRICE ($/UNID) COMPARED]) * [QTY SOLD COMPARED]),0))
```

**PRICE EFFECT ON COST**

```dax
SUMX(dClientes, VAR QTY = [QTY SOLD] VAR QTY_COMP = [QTY SOLD COMPARED] RETURN IF(AND(QTY>0,QTY_COMP>0), SUMX(VALUES(dCalendario[MesAnoNome]), - ([UNIT COST] - [UNIT COST COMPARED]) * [QTY SOLD COMPARED]),0))
```

**MIX EFFECT ON COST**

```dax
SUMX(dClientes, VAR QTY = [QTY SOLD] VAR QTY_COMP = [QTY SOLD COMPARED] RETURN IF(AND(QTY>0,QTY_COMP>0), SUMX(VALUES(dCalendario[MesAnoNome]), -  ([QTY SOLD] - [QTY SOLD COMPARED]) * ([UNIT COST] - [UNIT COST COMPARED])),0))
```

**MIX EFFECT ON SALES**

```dax
SUMX(dClientes, VAR QTY = [QTY SOLD] VAR QTY_COMP = [QTY SOLD COMPARED] RETURN IF(AND(QTY>0,QTY_COMP>0), SUMX(VALUES(dCalendario[MesAnoNome]), ([QTY SOLD] - [QTY SOLD COMPARED]) * ([AVG PRICE ($/UNID)] - [AVG PRICE ($/UNID) COMPARED])),0))
```

**DISCOUNT EFFECY ON MARGIN**

```dax
- ( [DISCOUNT] - [DISCOUNT COMPARED] )
```

**RETURNS EFFECY ON MARGIN**

```dax
- ( [RETURNS] - [RETURNS COMPARED] )
```

**NEW CUSTOMERS IMPACT**

```dax
SUMX(dClientes, VAR QTY = [QTY SOLD] VAR QTY_COMP = [QTY SOLD COMPARED] RETURN IF(AND(QTY>0,QTY_COMP=0), [GROSS SALES] - [TOTAL COST],0))
```

**LOST CUSTOMERS IMPACT**

```dax
SUMX(dClientes, VAR QTY = [QTY SOLD] VAR QTY_COMP = [QTY SOLD COMPARED] RETURN IF(AND(QTY=0,QTY_COMP>0), -([GROSS SALES COMPARED] - [TOTAL COST COMPARED]),0))
```

**VOLUME EFFECT ON MARGIN**

```dax
[VOLUME EFFECT ON SALES] + [VOLUME EFFECT ON COST]
```

**PRICE EFFECT ON MARGIN**

```dax
[PRICE EFFECT ON SALES] + [PRICE EFFECT ON COST]
```

**MIX EFFECT ON MARGIN**

```dax
[MIX EFFECT ON SALES] + [MIX EFFECT ON COST]
```

**$ Faturamento ultimos 12 meses**

```dax
``` CALCULATE ( [$ Faturamento], DATESINPERIOD ( dCalendario[Data], MAX ( dCalendario[Data] ), -12, MONTH ) ) ```
```

**$ Faturamento**

```dax
SUMX( fFaturamentoConsolidado, fFaturamentoConsolidado[_QTDVENDA] * fFaturamentoConsolidado[_PRCUNITVENDA] )
```

**# Clientes**

```dax
COUNTROWS( dClientes )
```

**Última compra**

```dax
CALCULATE ( MAX ( fFaturamentoConsolidado[_DTEMISSAO] ), FILTER( ALL( dCalendario ), dCalendario[Data] <= MAX(dCalendario[Data]) ) )
```

**# Notas emitidas**

```dax
DISTINCTCOUNT ( fFaturamentoConsolidado[_NFEVENDA] )
```

**# Notas emitidas ultimos 12 meses**

```dax
``` CALCULATE ( [# Notas emitidas], DATESINPERIOD ( fFaturamentoConsolidado[_DTEMISSAO], MAX ( dCalendario[Data] ), -12, MONTH ) ) ```
```

**Segmentacao selecionada**

```dax
"Clique aqui para detalhar " & SELECTEDVALUE ( auxClasse[Segmentação] )
```

**# Clientes RFV**

```dax
``` VAR varClientes = FILTER ( dClientes, MAX(dCalendario[Data]) - [Última compra] >= MIN(auxRecencia[min]) && MAX(dCalendario[Data]) - [Última compra] <  MAX(auxRecencia[max]) && [# Notas emitidas ultimos 12 meses] >= MIN(auxFrequencia[min]) && [# Notas emitidas ultimos 12 meses] <  MAX(auxFrequencia[max]) && [$ Faturamento ultimos 12 meses] >= MIN(auxValor[min]) && [$ Faturamento ultimos 12 meses] <  MAX(auxValor[max]) ) VAR varResultado = COUNTROWS( varClientes ) RETURN varResultado + 0 ```
```

**RFV (F)**

```dax
CALCULATE ( SELECTEDVALUE(auxFrequencia[frequencia_id]), FILTER ( auxFrequencia, [# Notas emitidas ultimos 12 meses] >= auxFrequencia[min] && [# Notas emitidas ultimos 12 meses] < auxFrequencia[max] ) )
```

**RFV (R)**

```dax
CALCULATE( SELECTEDVALUE(auxRecencia[recencia_id]), FILTER( auxRecencia, MAX(dCalendario[Data]) - [Última compra] >= auxRecencia[min] && MAX(dCalendario[Data]) - [Última compra] <  auxRecencia[max] ) )
```

**RFV (V)**

```dax
CALCULATE ( SELECTEDVALUE(auxValor[valor_id]), FILTER ( auxValor, [$ Faturamento ultimos 12 meses] >= auxValor[min] && [$ Faturamento ultimos 12 meses] < auxValor[max] ) )
```

**RFV (F + V)**

```dax
``` DIVIDE ( [RFV (F)] + [RFV (V)], 2 ) ```
```

**$ 01. Clientes campeões**

```dax
``` VAR vResult = CALCULATE( [$ Faturamento ultimos 12 meses], FILTER ( VALUES ( dClientes[_CHAVECLIENTE] ), [RFV (R)] > 4 && [RFV (R)] <= 999 && [RFV (F + V)] > 4 && [RFV (F + V)] <= 5 ) ) RETURN vResult+0 ```
```

**$ 02. Clientes fiéis**

```dax
``` VAR vLoyalCustomersChampions = CALCULATE( [$ Faturamento ultimos 12 meses], FILTER ( VALUES ( dClientes[_CHAVECLIENTE] ), [RFV (R)] > 2 && [RFV (R)] <= 999 && [RFV (F + V)] > 3 && [RFV (F + V)] <= 5 ) ) VAR varResultado = vLoyalCustomersChampions - [$ 01. Clientes campeões] RETURN varResultado + 0 ```
```

**$ 03. Clientes potenciais fiéis**

```dax
``` VAR varResultado = CALCULATE ( [$ Faturamento ultimos 12 meses], FILTER ( VALUES ( dClientes[_CHAVECLIENTE] ), [RFV (R)] > 3 && [RFV (R)] <= 999 && [RFV (F + V)] > 1 && [RFV (F + V)] <= 3 ) ) RETURN varResultado + 0 ```
```

**$ 04. Clientes recentes**

```dax
``` VAR varResultado = CALCULATE ( [$ Faturamento ultimos 12 meses], FILTER ( VALUES ( dClientes[_CHAVECLIENTE] ) , [RFV (R)] > 4 && [RFV (R)] <= 999 && [RFV (F + V)] > 0 && [RFV (F + V)] <= 1 ) ) RETURN varResultado + 0 ```
```

**$ 05. Clientes hibernando**

```dax
``` VAR varResultado = CALCULATE ( [$ Faturamento ultimos 12 meses], FILTER ( VALUES ( dClientes[_CHAVECLIENTE] ) , [RFV (R)] = 2 && [RFV (F + V)] = 2 ) ) RETURN varResultado + 0 ```
```

**$ 06. Clientes promissores**

```dax
``` VAR varResultado = CALCULATE ( [$ Faturamento ultimos 12 meses], FILTER ( VALUES ( dClientes[_CHAVECLIENTE] ) , [RFV (R)] > 3 && [RFV (R)] <= 4 && [RFV (F + V)] > 0 && [RFV (F + V)] <= 1 ) ) RETURN varResultado + 0 ```
```

**$ 07. Clientes precisam de atenção**

```dax
``` VAR varResultado = CALCULATE ( [$ Faturamento ultimos 12 meses], FILTER ( VALUES ( dClientes[_CHAVECLIENTE] ) , [RFV (R)] > 2 && [RFV (R)] <= 3 && [RFV (F + V)] > 2 && [RFV (F + V)] <= 3 ) ) RETURN varResultado + 0 ```
```

**$ 08. Clientes prestes a "hibernar"**

```dax
``` VAR varResultado = CALCULATE ( [$ Faturamento ultimos 12 meses], FILTER ( VALUES ( dClientes[_CHAVECLIENTE] ) , [RFV (R)] > 2 && [RFV (R)] <= 3 && [RFV (F + V)] > 0 && [RFV (F + V)] <= 2 ) ) RETURN varResultado + 0 ```
```

**$ 09. Clientes não podemos perdê-los**

```dax
``` VAR varResultado = CALCULATE ( [$ Faturamento ultimos 12 meses], FILTER ( VALUES ( dClientes[_CHAVECLIENTE] ) , [RFV (R)] > 0 && [RFV (R)] <= 1 && [RFV (F + V)] > 4 && [RFV (F + V)] <= 5 ) ) RETURN varResultado + 0 ```
```

**$ 10. Clientes em risco**

```dax
``` VAR varRiscoPerder = CALCULATE ( [$ Faturamento ultimos 12 meses], FILTER ( VALUES ( dClientes[_CHAVECLIENTE] ) , [RFV (R)] > 0 && [RFV (R)] <= 2 && [RFV (F + V)] > 2 && [RFV (F + V)] <= 5 ) ) VAR varResultado = varRiscoPerder - [$ 09. Clientes não podemos perdê-los] RETURN varResultado + 0 ```
```

**$ 11. Clientes perdidos**

```dax
``` VAR varHibernatingLost = CALCULATE ( [$ Faturamento ultimos 12 meses], FILTER ( VALUES ( dClientes[_CHAVECLIENTE] ) , [RFV (R)] <= 2 && [RFV (F + V)] <= 2 ) ) VAR varResultado = varHibernatingLost - [$ 05. Clientes hibernando] RETURN varResultado + 0 ```
```

**$ Faturamento por segmentacao**

```dax
VAR varClasseRFV = SELECTEDVALUE ( auxClasse[Segmentação] ) RETURN SWITCH( TRUE(), varClasseRFV  = "Campeões", [$ 01. Clientes campeões], varClasseRFV  = "Clientes fiéis", [$ 02. Clientes fiéis], varClasseRFV  = "Potenciais fiéis", [$ 03. Clientes potenciais fiéis], varClasseRFV  = "Clientes recentes", [$ 04. Clientes recentes], varClasseRFV  = "Hibernando", [$ 05. Clientes hibernando], varClasseRFV  = "Promissores", [$ 06. Clientes promissores], varClasseRFV  = "Precisam de atenção", [$ 07. Clientes precisam de atenção], varClasseRFV  = "Prestes a hibernar", [$ 08. Clientes prestes a "hibernar"], varClasseRFV  = "Não posso perder", [$ 09. Clientes não podemos perdê-los], varClasseRFV  = "Em risco", [$ 10. Clientes em risco], varClasseRFV  = "Perdidos", [$ 11. Clientes perdidos], BLANK() )
```

**# 01. Clientes campões**

```dax
``` VAR vResult = CALCULATE( [# Clientes], FILTER( VALUES ( dClientes[_NOMECLIENTE] ), [RFV (R)] > 4 && [RFV (R)] <= 999 && [RFV (F + V)] > 4 && [RFV (F + V)] <= 5 ) ) RETURN vResult+0 ```
```

**# 02. Clientes fiéis**

```dax
``` VAR vLoyalCustomersChampions = CALCULATE( [# Clientes], FILTER ( VALUES ( dClientes[_CHAVECLIENTE]  ), [RFV (R)] > 2 && [RFV (R)] <= 999 && [RFV (F + V)] > 3 && [RFV (F + V)] <= 5 ) ) VAR varResultado = vLoyalCustomersChampions - [# 01. Clientes campões] RETURN varResultado + 0 ```
```

**# 03. Clientes potenciais fiéis**

```dax
``` VAR varResultado = CALCULATE( [# Clientes], FILTER ( VALUES ( dClientes[_CHAVECLIENTE] ), [RFV (R)] > 3 && [RFV (R)] <= 999 && [RFV (F + V)] > 1 && [RFV (F + V)] <= 3 ) ) RETURN varResultado + 0 ```
```

**# 04. Clientes recentes**

```dax
``` VAR varResultado = CALCULATE( [# Clientes], FILTER ( VALUES ( dClientes[_CHAVECLIENTE] ) , [RFV (R)] > 4 && [RFV (R)] <= 999 && [RFV (F + V)] > 0 && [RFV (F + V)] <= 1 ) ) RETURN varResultado + 0 ```
```

**# 05. Clientes hibernando**

```dax
``` VAR varResultado = CALCULATE( [# Clientes], FILTER ( VALUES ( dClientes[_CHAVECLIENTE] ) , [RFV (R)] = 2 && [RFV (F + V)] = 2 ) ) RETURN varResultado + 0 ```
```

**# 06. Clientes promissores**

```dax
``` VAR varResultado = CALCULATE( [# Clientes], FILTER ( VALUES ( dClientes[_CHAVECLIENTE] ) , [RFV (R)] > 3 && [RFV (R)] <= 4 && [RFV (F + V)] > 0 && [RFV (F + V)] <= 1 ) ) RETURN varResultado + 0 ```
```

**# 07. Clientes precisam de atenção**

```dax
``` VAR varResultado = CALCULATE( [# Clientes], FILTER ( VALUES ( dClientes[_CHAVECLIENTE] ) , [RFV (R)] > 2 && [RFV (R)] <= 3 && [RFV (F + V)] > 2 && [RFV (F + V)] <= 3 ) ) RETURN varResultado + 0 ```
```

**# 08. Clientes prestes a "hibernar"**

```dax
``` VAR varResultado = CALCULATE( [# Clientes], FILTER ( VALUES ( dClientes[_CHAVECLIENTE] ) , [RFV (R)] > 2 && [RFV (R)] <= 3 && [RFV (F + V)] > 0 && [RFV (F + V)] <= 2 ) ) RETURN varResultado + 0 ```
```

**# 09. Clientes não podemos perdê-los**

```dax
``` VAR varResultado = CALCULATE( [# Clientes], FILTER ( VALUES ( dClientes[_CHAVECLIENTE] ) , [RFV (R)] > 0 && [RFV (R)] <= 1 && [RFV (F + V)] > 4 && [RFV (F + V)] <= 5 ) ) RETURN varResultado + 0 ```
```

**# 10. Clientes em risco**

```dax
``` VAR varRiscoPerder = CALCULATE( [# Clientes], FILTER ( VALUES ( dClientes[_CHAVECLIENTE] ) , [RFV (R)] > 0 && [RFV (R)] <= 2 && [RFV (F + V)] > 2 && [RFV (F + V)] <= 5 ) ) VAR varResultado = varRiscoPerder - [# 09. Clientes não podemos perdê-los] RETURN varResultado + 0 ```
```

**# 11. Clientes perdidos**

```dax
``` VAR varHibernatingLost = CALCULATE( [# Clientes], FILTER ( VALUES ( dClientes[_CHAVECLIENTE] ) , [RFV (R)] <= 2 && [RFV (F + V)] <= 2 ) ) VAR varResultado = varHibernatingLost - [# 05. Clientes hibernando] RETURN varResultado + 0 ```
```

**# Clientes por segmentacao**

```dax
VAR varClasseRFV = SELECTEDVALUE ( auxClasse[Segmentação] ) RETURN SWITCH( TRUE(), varClasseRFV  = "Campeões", [# 01. Clientes campões], varClasseRFV  = "Clientes fiéis", [# 02. Clientes fiéis], varClasseRFV  = "Potenciais fiéis", [# 03. Clientes potenciais fiéis], varClasseRFV  = "Clientes recentes", [# 04. Clientes recentes], varClasseRFV  = "Hibernando", [# 05. Clientes hibernando], varClasseRFV  = "Promissores", [# 06. Clientes promissores], varClasseRFV  = "Precisam de atenção", [# 07. Clientes precisam de atenção], varClasseRFV  = "Prestes a hibernar", [# 08. Clientes prestes a "hibernar"], varClasseRFV  = "Não posso perder", [# 09. Clientes não podemos perdê-los], varClasseRFV  = "Em risco", [# 10. Clientes em risco], varClasseRFV  = "Perdidos", [# 11. Clientes perdidos], BLANK() )
```

**% 01. Clientes campeões**

```dax
DIVIDE ( [# 01. Clientes campões], [# Clientes] )
```

**% 02. Clientes fiéis**

```dax
DIVIDE ( [# 02. Clientes fiéis], [# Clientes] )
```

**% 03. Clientes potenciais fiéis**

```dax
DIVIDE ( [# 03. Clientes potenciais fiéis], [# Clientes] )
```

**% 04. Clientes recentes**

```dax
DIVIDE ( [# 04. Clientes recentes], [# Clientes] )
```

**% 05. Clientes hibernando**

```dax
DIVIDE ( [# 05. Clientes hibernando], [# Clientes] )
```

**% 06. Clientes promissores**

```dax
DIVIDE ( [# 06. Clientes promissores], [# Clientes] )
```

**% 07. Clientes precisam de atenção**

```dax
DIVIDE ( [# 07. Clientes precisam de atenção], [# Clientes] )
```

**% 08. Clientes prestes a "hibernar"**

```dax
DIVIDE ( [# 08. Clientes prestes a "hibernar"], [# Clientes] )
```

**% 09. Clientes não posso perdê-los**

```dax
DIVIDE ( [# 09. Clientes não podemos perdê-los], [# Clientes] )
```

**% 10. Clientes em risco**

```dax
DIVIDE ( [# 10. Clientes em risco], [# Clientes] )
```

**% 11. Clientes perdidos**

```dax
``` DIVIDE ( [# 11. Clientes perdidos], [# Clientes] ) ```
```

**% de +/-  FATURAMENTO**

```dax
DIVIDE( [GROSS SALES], [GROSS SALES COMPARED]) - 1
```

**% de +/- PESO**

```dax
DIVIDE( [QTY SOLD], [QTY SOLD COMPARED]) - 1
```

**% de +/-  PREÇO**

```dax
DIVIDE( [AVG PRICE ($/UNID)], [AVG PRICE ($/UNID) COMPARED]) - 1
```

**% de +/- CUSTO**

```dax
DIVIDE( [TOTAL COST], [TOTAL COST COMPARED]) - 1
```

**% de +/-  CUSTO UNITÁRIO**

```dax
DIVIDE( [UNIT COST], [UNIT COST COMPARED]) - 1
```

**% de +/- DEVOLUÇÃO**

```dax
DIVIDE( [RETURNS], [RETURNS COMPARED]) - 1
```

**% de +/-  MARGEM BRUTA**

```dax
DIVIDE( [GROSS MARGIN], [GROSS MARGIN COMPARED]) - 1
```

**Detalhe % Fat**

```dax
FORMAT( [% Faturamento YoY], " ⇧ 0%; ⇩ 0%")
```

**Detalhe % Preço**

```dax
FORMAT( [% Preço YoY], " ⇧ 0%; ⇩ 0%")
```

**Detalhe % Peso**

```dax
FORMAT( [% Peso YoY], " ⇧ 0%; ⇩ 0%")
```

**Detalhe % TM**

```dax
FORMAT( [% TM YoY], " ⇧ 0%; ⇩ 0%")
```

**% de +/- TM**

```dax
DIVIDE( [Ticket Médio (Atual)], [Ticket Médio LY]) - 1
```

**Fat. Mês Anterior**

```dax
CALCULATE( [Faturamento (Atual)], PARALLELPERIOD(dCalendario[Data], -1, MONTH) )
```

**Detalhe % Fat M**

```dax
FORMAT( [% Faturamento MoM], " ⇧ 0%; ⇩ 0%")
```

**Fat Ano Anterior (Mesmo Periodo Selecionado)**

```dax
VAR DataInicialSelecionada = MIN(dCalendario[Data]) VAR DataFinalSelecionada = MAX(dCalendario[Data]) VAR DataInicialAnoAnterior = EDATE(DataInicialSelecionada, -12) VAR DataFinalAnoAnterior = EDATE(DataFinalSelecionada, -12) RETURN CALCULATE( [Faturamento (Atual)], dCalendario[Data] >= DataInicialAnoAnterior && dCalendario[Data] <= DataFinalAnoAnterior )
```

**Rank Fat Produto**

```dax
RANKX( ALL(dProdutos[_DESCPRODUTO]), [Faturamento (Atual)], , DESC, Dense )
```

**Fat. Acum. Anl. Pareto**

```dax
VAR RankDoContexto = [Rank Fat Produto] VAR Resultado = CALCULATE( [Faturamento (Atual)], FILTER( ALL(dProdutos[_DESCPRODUTO]), [Rank Fat Produto] <= RankDoContexto) ) RETURN Resultado
```

**Fat. Bruto S/ Filtro Prod**

```dax
CALCULATE( [Faturamento (Atual)], ALL(dProdutos[_DESCPRODUTO]) )
```

**% do Pareto**

```dax
DIVIDE( [Fat. Acum. Anl. Pareto], [Fat. Bruto S/ Filtro Prod] )
```

**Vlr % pro Pareto**

```dax
0.8
```

**Compl. do Vlr do % pareto**

```dax
1 - [Vlr % pro Pareto]
```

**Qtd de Prod**

```dax
DISTINCTCOUNT(dProdutos[_DESCPRODUTO])
```

**Qdt de Prod de Anal Pareto**

```dax
``` CALCULATE( DISTINCTCOUNT(dProdutos[_DESCPRODUTO]), FILTER( ALL(dProdutos[_DESCPRODUTO]), [% do Pareto] <= [Vlr % pro Pareto] ) ) ```
```

**% dos Produtos do Pareto**

```dax
``` DIVIDE( [Qdt de Prod de Anal Pareto],[Qtd de Prod]) ```
```

**Dif de Produto Total**

```dax
[Qtd de Prod] - [Qdt de Prod de Anal Pareto]
```

**Ranking Pareto Mês Anterior**

```dax
RANKX( ALL(dProdutos[_DESCPRODUTO]), [Fat. Mês Anterior], , DESC, Dense )
```

**% Dif Prd Pareto**

```dax
DIVIDE([Qdt de Prod de Anal Pareto], [Qtd de Prod] )
```

**Faturamento 80% Pareto**

```dax
VAR FaturamentoTotal = CALCULATE(SUM(fFaturamentoConsolidado[_TOTALVENDA]), ALL(dProdutos)) VAR ProdutosFiltrados = FILTER( ALL(dProdutos), DIVIDE( SUMX( FILTER( ALL(dProdutos), dProdutos[_DESCPRODUTO] <= MAX(dProdutos[_DESCPRODUTO]) ), SUM(fFaturamentoConsolidado[_TOTALVENDA]) -- Agregação explícita ), FaturamentoTotal ) <= [Vlr % pro Pareto] ) RETURN CALCULATE( SUM(fFaturamentoConsolidado[_TOTALVENDA]), -- Agregação explícita ProdutosFiltrados )
```

**Rank Acum Fat Prod**

```dax
CALCULATE( [Faturamento (Atual)], TOPN( [Rank Fat Produto], ALLSELECTED(dProdutos), [Faturamento (Atual)], DESC ) )
```

**Rank Pct Fat Prod**

```dax
VAR vValorTotal = CALCULATE([Faturamento (Atual)], ALLSELECTED(dProdutos)) VAR vRankAcum = [Rank Acum Fat Prod] VAR vResultado = DIVIDE(vRankAcum,vValorTotal) RETURN vResultado
```

**Qtd Prod Pareto**

```dax
VAR vPct_Pareto = 0.8 VAR vResultado= MAXX( FILTER( ADDCOLUMNS( ALLSELECTED(dProdutos[_DESCPRODUTO]), "@RANK", [Rank Fat Produto], "@VALOR", [Rank Acum Fat Prod], "@PCT", [Rank Pct Fat Prod] ), [@PCT]<= vPct_Pareto ), [@RANK] ) RETURN vResultado
```

**Pct Pareto**

```dax
DIVIDE([Qtd Prod Pareto], [Qtd de Prod])
```

**Vlr Prod Pareto**

```dax
VAR vPct_Pareto = 0.8 VAR vResultado= MAXX( FILTER( ADDCOLUMNS( ALLSELECTED(dProdutos[_DESCPRODUTO]), "@RANK", [Rank Acum Fat Prod], "@VALOR", [Rank Acum Fat Prod], "@PCT", [Rank Pct Fat Prod] ), [@PCT]<= vPct_Pareto ), [@RANK] ) RETURN vResultado
```

**%DESCTOT2**

```dax
ROUND( DIVIDE( SUMX( fFaturamentoConsolidado, (fFaturamentoConsolidado[_%CONDESPECIAL] + fFaturamentoConsolidado[_%DESCFIN]) * fFaturamentoConsolidado[_TOTALVENDA] ), SUM(fFaturamentoConsolidado[_TOTALVENDA]) ), 4 )
```

**Fat (R$) Liq. MONTH (-3)**

```dax
CALCULATE( [Faturamento Liquido 2], PARALLELPERIOD(dCalendario[Data], -3, MONTH) )
```

**Custo total Agencias Promotores**

```dax
sum(FPromotores[VlrRateado_ag])
```

**Fat. Cl c/ Promot.**

```dax
CALCULATE( [Faturamento Liquido 2], FILTER( fFaturamentoConsolidado, fFaturamentoConsolidado[_CHAVECLIENTE] IN VALUES(FPromotores[chave]) ) )
```

**% S/ Invest (Linha a Linha)**

```dax
DIVIDE( [Custo total Agencias Promotores], CALCULATE( [Fat. Cl c/ Promot.], REMOVEFILTERS(FPromotores[UF]) -- Substitua 'TabelaUF' pelo nome da tabela de onde vem a UF ) )
```

**FiltroAnaliseMetas**

```dax
VAR Meta = NOT ISBLANK([Meta Total]) VAR FAT = NOT ISBLANK([Peso Liquido Vendido]) RETURN IF(Meta || FAT, 1, 0)
```

**Base_Positivados**

```dax
``` VAR DataFinalAnterior = EOMONTH(MAX(dCalendario[Data]), -1) VAR DataInicialPeriodo = EDATE(DataFinalAnterior, -5) RETURN CALCULATE( DISTINCTCOUNT(fFaturamentoConsolidado[_CHAVECLIENTE]), KEEPFILTERS( dCalendario[Data] >= DataInicialPeriodo && dCalendario[Data] <= DataFinalAnterior ), ALL(dCalendario) ) ```
```

**Clientes_Positivados_Mes**

```dax
``` VAR UltimoDiaMes = MAX(dCalendario[Data]) VAR PrimeiroDiaMes = EOMONTH(UltimoDiaMes, -1) + 1 VAR DataFinalAnterior = EOMONTH(UltimoDiaMes, -1) VAR DataInicialPeriodo = EDATE(DataFinalAnterior, -5) VAR ClientesBaseAtiva = CALCULATETABLE( VALUES(fFaturamentoConsolidado[_CHAVECLIENTE]), dCalendario[Data] >= DataInicialPeriodo && dCalendario[Data] <= DataFinalAnterior, ALL(dCalendario) ) VAR ClientesCompraramMes = CALCULATETABLE( VALUES(fFaturamentoConsolidado[_CHAVECLIENTE]), KEEPFILTERS(dCalendario[Data] >= PrimeiroDiaMes && dCalendario[Data] <= UltimoDiaMes), ALL(dCalendario) ) RETURN COUNTROWS( INTERSECT( ClientesBaseAtiva, ClientesCompraramMes ) ) ```
```

**%_Positivacao_Clientes_Mes_Recorrente**

```dax
``` DIVIDE( [Clientes_Positivados_Mes], [Base_Positivados], 0 ) ```
```

**Clientes_Inativos_Base_Reativacao**

```dax
``` VAR UltimoDiaMes = MAX(dCalendario[Data]) VAR DataFinalAnterior = EOMONTH(UltimoDiaMes, -1) VAR DataInicialPeriodo = EDATE(DataFinalAnterior, -5) // 1. Clientes com Histórico de Compra (desde o início, até o mês anterior) VAR TodosClientesHistorico = CALCULATETABLE( VALUES(fFaturamentoConsolidado[_CHAVECLIENTE]), dCalendario[Data] < DataFinalAnterior + 1, ALL(dCalendario) ) // 2. Clientes Base Ativa (compraram nos últimos 6 meses, excluindo o atual) VAR ClientesBaseAtiva = CALCULATETABLE( VALUES(fFaturamentoConsolidado[_CHAVECLIENTE]), dCalendario[Data] >= DataInicialPeriodo && dCalendario[Data] <= DataFinalAnterior, ALL(dCalendario) ) RETURN // EXCEPT: Todos clientes com histórico MENOS aqueles que estão ativos COUNTROWS( EXCEPT( TodosClientesHistorico, ClientesBaseAtiva ) ) ```
```

**Clientes_Reativados_Mes**

```dax
``` VAR UltimoDiaMes = MAX(dCalendario[Data]) VAR PrimeiroDiaMes = EOMONTH(UltimoDiaMes, -1) + 1 VAR DataFinalAnterior = EOMONTH(UltimoDiaMes, -1) VAR DataInicialPeriodo = EDATE(DataFinalAnterior, -5) // 1. Todos os clientes com histórico (antes do mês atual) VAR TodosClientesHistorico = CALCULATETABLE( VALUES(fFaturamentoConsolidado[_CHAVECLIENTE]), dCalendario[Data] < PrimeiroDiaMes, ALL(dCalendario) ) // 2. Clientes da Base Ativa (compraram nos 6 meses anteriores) VAR ClientesBaseAtiva = CALCULATETABLE( VALUES(fFaturamentoConsolidado[_CHAVECLIENTE]), dCalendario[Data] >= DataInicialPeriodo && dCalendario[Data] <= DataFinalAnterior, ALL(dCalendario) ) // 3. Base Inativa = Histórico MENOS Ativa VAR ClientesBaseInativa = EXCEPT( TodosClientesHistorico, ClientesBaseAtiva ) // 4. Clientes que compraram no mês atual VAR ClientesCompraramMes = CALCULATETABLE( VALUES(fFaturamentoConsolidado[_CHAVECLIENTE]), KEEPFILTERS(dCalendario[Data] >= PrimeiroDiaMes && dCalendario[Data] <= UltimoDiaMes), ALL(dCalendario) ) RETURN // Intersecção: Inativos que compraram no mês = Reativados COUNTROWS( INTERSECT( ClientesBaseInativa, ClientesCompraramMes ) ) ```
```

**%_Reativacao_Clientes_Mes**

```dax
``` DIVIDE( [Clientes_Reativados_Mes], [Clientes_Inativos_Base_Reativacao], 0 ) ```
```

**Clientes_Lista_POSITIVADOS**

```dax
``` VAR UltimoDiaMes = MAX(dCalendario[Data]) VAR PrimeiroDiaMes = EOMONTH(UltimoDiaMes, -1) + 1 VAR DataFinalAnterior = EOMONTH(UltimoDiaMes, -1) VAR DataInicialPeriodo = EDATE(DataFinalAnterior, -5) // 1. Clientes da Base Ativa (6 meses anteriores) VAR ClientesBaseAtiva = CALCULATETABLE( VALUES(fFaturamentoConsolidado[_CHAVECLIENTE]), dCalendario[Data] >= DataInicialPeriodo && dCalendario[Data] <= DataFinalAnterior, ALL(dCalendario) ) // 2. Clientes que compraram no mês atual VAR ClientesCompraramMes = CALCULATETABLE( VALUES(fFaturamentoConsolidado[_CHAVECLIENTE]), KEEPFILTERS(dCalendario[Data] >= PrimeiroDiaMes && dCalendario[Data] <= UltimoDiaMes), ALL(dCalendario) ) // 3. Intersecção = Positivados VAR ListaClientesPositivados = INTERSECT( ClientesBaseAtiva, ClientesCompraramMes ) RETURN CONCATENATEX( FILTER( dClientes, dClientes[_CHAVECLIENTE] IN ListaClientesPositivados ), dClientes[_NOMECLIENTE], ", ", dClientes[_NOMECLIENTE], ASC ) ```
```

**Status_Positivacao_Base_Ativa_Refletida**

```dax
``` VAR UltimoDiaMes = MAX(dCalendario[Data]) VAR PrimeiroDiaMes = EOMONTH(UltimoDiaMes, -1) + 1 VAR DataFinalAnterior = EOMONTH(UltimoDiaMes, -1) VAR DataInicialPeriodo = EDATE(DataFinalAnterior, -5) // 1. Comprou nos 6 meses anteriores = Base Ativa VAR EstaBaseAtiva = CALCULATE( COUNTROWS(fFaturamentoConsolidado), dCalendario[Data] >= DataInicialPeriodo && dCalendario[Data] <= DataFinalAnterior, ALL(dCalendario) ) > 0 // 2. Comprou no mes filtrado VAR ComprouNoMes = CALCULATE( COUNTROWS(fFaturamentoConsolidado), dCalendario[Data] >= PrimeiroDiaMes && dCalendario[Data] <= UltimoDiaMes, ALL(dCalendario) ) > 0 RETURN IF( EstaBaseAtiva, IF(ComprouNoMes, 1, 0), BLANK() ) ```
```

**Filtro_Reativados_Lista_V3**

```dax
``` VAR UltimoDiaMes = MAX(dCalendario[Data]) VAR PrimeiroDiaMes = EOMONTH(UltimoDiaMes, -1) + 1 VAR DataFinalAnterior = EOMONTH(UltimoDiaMes, -1) VAR DataInicialPeriodo = EDATE(DataFinalAnterior, -5) // 1. Comprou no mes filtrado? VAR ComprouNoMes = CALCULATE( COUNTROWS(fFaturamentoConsolidado), dCalendario[Data] >= PrimeiroDiaMes && dCalendario[Data] <= UltimoDiaMes, ALL(dCalendario) ) > 0 // 2. Comprou nos 6 meses anteriores? (Se sim, NAO eh reativado) VAR Comprou6MAnteriores = CALCULATE( COUNTROWS(fFaturamentoConsolidado), dCalendario[Data] >= DataInicialPeriodo && dCalendario[Data] <= DataFinalAnterior, ALL(dCalendario) ) > 0 // 3. Tem historico antes do periodo de 6 meses? (excluir clientes novos) VAR TemHistoricoAntes = CALCULATE( COUNTROWS(fFaturamentoConsolidado), dCalendario[Data] < DataInicialPeriodo, ALL(dCalendario) ) > 0 RETURN IF( ComprouNoMes && NOT Comprou6MAnteriores && TemHistoricoAntes, 1, BLANK() ) ```
```

**Total_Clientes_Compraram_Mes**

```dax
CALCULATE( DISTINCTCOUNT(fFaturamentoConsolidado[_CHAVECLIENTE]) )
```

**Contagem_Clientes_Novos**

```dax
``` VAR UltimoDiaMes = MAX(dCalendario[Data]) VAR PrimeiroDiaMes = EOMONTH(UltimoDiaMes, -1) + 1 // Clientes que compraram no mês filtrado VAR ClientesQueCompraramNoMes = CALCULATETABLE( VALUES(fFaturamentoConsolidado[_CHAVECLIENTE]), KEEPFILTERS(dCalendario[Data] >= PrimeiroDiaMes && dCalendario[Data] <= UltimoDiaMes), ALL(dCalendario) ) // Clientes que compraram ANTES do mês filtrado VAR ClientesQueCompraramAntes = CALCULATETABLE( VALUES(fFaturamentoConsolidado[_CHAVECLIENTE]), dCalendario[Data] < PrimeiroDiaMes, ALL(dCalendario) ) // Clientes Novos = compraram no mês, mas NUNCA antes VAR ClientesNovos = EXCEPT( ClientesQueCompraramNoMes, ClientesQueCompraramAntes ) RETURN COUNTROWS(ClientesNovos) ```
```

**Percentual_Clientes_Novos**

```dax
DIVIDE( [Contagem_Clientes_Novos], [Total_Clientes_Compraram_Mes] )
```

**Cliente_Novo_Indice**

```dax
``` VAR UltimoDiaMes = MAX(dCalendario[Data]) VAR PrimeiroDiaMes = EOMONTH(UltimoDiaMes, -1) + 1 // 1. Comprou no mes filtrado? VAR ComprouNoMes = CALCULATE( COUNTROWS(fFaturamentoConsolidado), dCalendario[Data] >= PrimeiroDiaMes && dCalendario[Data] <= UltimoDiaMes, ALL(dCalendario) ) > 0 // 2. Comprou antes do mes filtrado? VAR ComprouAntes = CALCULATE( COUNTROWS(fFaturamentoConsolidado), dCalendario[Data] < PrimeiroDiaMes, ALL(dCalendario) ) > 0 RETURN IF( ComprouNoMes && NOT ComprouAntes, 1, BLANK() ) ```
```

**Rótulo BarrasFat**

```dax
``` VAR vFat = [Faturamento Liquido] VAR vFatFormat = FORMAT(vFat, "R$ #,##0") RETURN vFatFormat ```
```

**URL_FOTO_Gerente_Medida_Final**

```dax
``` VAR CodigoGerente = SELECTEDVALUE(dGerentes[_CODVEND]) -- ESTE É O PONTO CRÍTICO VAR URL_ENCONTRADA = LOOKUPVALUE( Tabela14[_FOTO], Tabela14[_CODVEND], CodigoGerente ) RETURN IF( ISBLANK(URL_ENCONTRADA), "https://i.postimg.cc/d1G0cHTR/Ativo-1.png", URL_ENCONTRADA ) ```
```

**Prospects**

```dax
COALESCE( COUNT(fProspects[US_CGC]), 0 )
```

**Convertidos**

```dax
COALESCE( COUNT(fProspects[fFaturamentoConsolidado._CHAVECLIENTE]), 0 )
```

**% Conversão**

```dax
COALESCE( DIVIDE( [Convertidos], [Prospects] ), 0)
```

**Qtd Representantes**

```dax
DISTINCTCOUNT(fFaturamentoConsolidado[_CODVEND])
```

**Municipios Atendidos**

```dax
COUNTROWS( SUMMARIZE( fFaturamento, dClientes[_MUNCLIENTE] ) )
```

**Top 1 Nome**

```dax
CALCULATE( SELECTEDVALUE(dVendedores[_NOMEVEND], FILTER( VALUES(dVendedores[_ALIAS]), [Rank Vendedor $] = 1 )))
```

**Top 2 Nome**

```dax
CALCULATE( SELECTEDVALUE(dVendedores[_NOMEVEND], FILTER( VALUES(dVendedores[_ALIAS]), [Rank Vendedor $] = 2 )))
```

**Top 3 Nome**

```dax
CALCULATE( SELECTEDVALUE(dVendedores[_NOMEVEND], FILTER( VALUES(dVendedores[_ALIAS]), [Rank Vendedor $] = 3 )))
```

**Top 4 Nome**

```dax
CALCULATE( SELECTEDVALUE(dVendedores[_NOMEVEND], FILTER( VALUES(dVendedores[_ALIAS]), [Rank Vendedor $] = 4 )))
```

**Top 5 Nome**

```dax
CALCULATE( SELECTEDVALUE(dVendedores[_NOMEVEND], FILTER( VALUES(dVendedores[_ALIAS]), [Rank Vendedor $] = 5 )))
```

**Top 1 Faturamento**

```dax
CALCULATE( [Faturamento (Atual)], FILTER( VALUES(dVendedores[_CODVEND]), [Rank Vendedor $] = 1 ))
```

**Top 2 Faturamento**

```dax
CALCULATE( [Faturamento (Atual)], FILTER( VALUES(dVendedores[_CODVEND]), [Rank Vendedor $] = 2 ))
```

**Top 3 Faturamento**

```dax
CALCULATE( [Faturamento (Atual)], FILTER( VALUES(dVendedores[_CODVEND]), [Rank Vendedor $] = 3 ))
```

**Top 4 Faturamento**

```dax
CALCULATE( [Faturamento (Atual)], FILTER( VALUES(dVendedores[_CODVEND]), [Rank Vendedor $] = 4 ))
```

**Top 5 Faturamento**

```dax
CALCULATE( [Faturamento (Atual)], FILTER( VALUES(dVendedores[_CODVEND]), [Rank Vendedor $] = 5 ))
```

**Rank Produtos $**

```dax
RANKX( ALLSELECTED(dProdutos), [Faturamento (Atual)] )
```

**Top 1 ProdutoDesc**

```dax
CALCULATE( SELECTEDVALUE(dProdutos[_DESCPRODUTO], FILTER( VALUES(dProdutos[DESCRIÇÃO LOUSINHA]), [Rank Produtos $] = 1 )))
```

**Top 2 ProdutoDesc**

```dax
CALCULATE( SELECTEDVALUE(dProdutos[_DESCPRODUTO], FILTER( VALUES(dProdutos[DESCRIÇÃO LOUSINHA]), [Rank Produtos $] = 2 )))
```

**Top 3 ProdutoDesc**

```dax
CALCULATE( SELECTEDVALUE(dProdutos[_DESCPRODUTO], FILTER( VALUES(dProdutos[DESCRIÇÃO LOUSINHA]), [Rank Produtos $] = 3 )))
```

**Top 1 ProdutoFat**

```dax
CALCULATE( [Faturamento (Atual)], FILTER( VALUES(dProdutos[DESCRIÇÃO LOUSINHA]), [Rank Produtos $] = 1 ))
```

**Top 2 ProdutoFat**

```dax
CALCULATE( [Faturamento (Atual)], FILTER( VALUES(dProdutos[DESCRIÇÃO LOUSINHA]), [Rank Produtos $] = 2 ))
```

**Top 1 ProdutoFoto**

```dax
CALCULATE( SELECTEDVALUE(dProdutos[Fotos]), FILTER( VALUES(dProdutos[DESCRIÇÃO LOUSINHA]), [Rank Produtos $] = 1 ))
```

**Top 2 ProdutoFoto**

```dax
CALCULATE( SELECTEDVALUE(dProdutos[Fotos]), FILTER( VALUES(dProdutos[DESCRIÇÃO LOUSINHA]), [Rank Produtos $] = 2 ))
```

**Top 3 ProdutoFoto**

```dax
CALCULATE( SELECTEDVALUE(dProdutos[Fotos]), FILTER( VALUES(dProdutos[DESCRIÇÃO LOUSINHA]), [Rank Produtos $] = 3 ))
```

**Top 3 ProdutoFat**

```dax
CALCULATE( [Faturamento (Atual)], FILTER( VALUES(dProdutos[DESCRIÇÃO LOUSINHA]), [Rank Produtos $] = 3 ))
```

**Rank Redes $**

```dax
RANKX( ALLSELECTED(dRedes), [Faturamento (Atual)] )
```

**Top 1 Atingimento**

```dax
CALCULATE( [% Ating Meta (KG)], FILTER( VALUES(dVendedores[_CODVEND]), [Rank Vendedor $] = 1 ))
```

**Top 2 Atingimento**

```dax
CALCULATE( [% Ating Meta (KG)], FILTER( VALUES(dVendedores[_CODVEND]), [Rank Vendedor $] = 2 ))
```

**Top 3 Atingimento**

```dax
CALCULATE( [% Ating Meta (KG)], FILTER( VALUES(dVendedores[_CODVEND]), [Rank Vendedor $] = 3 ))
```

**Top 4 Atingimento**

```dax
CALCULATE( [% Ating Meta (KG)], FILTER( VALUES(dVendedores[_CODVEND]), [Rank Vendedor $] = 4 ))
```

**Top 5 Atingimento**

```dax
CALCULATE( [% Ating Meta (KG)], FILTER( VALUES(dVendedores[_CODVEND]), [Rank Vendedor $] = 5 ))
```

**Top 6 Atingimento**

```dax
CALCULATE( [% Ating Meta (KG)], FILTER( VALUES(dVendedores[_CODVEND]), [Rank Vendedor $] = 6 ))
```

**Top 7 Atingimento**

```dax
CALCULATE( [% Ating Meta (KG)], FILTER( VALUES(dVendedores[_CODVEND]), [Rank Vendedor $] = 7 ))
```

**Top 8 Atingimento**

```dax
CALCULATE( [% Ating Meta (KG)], FILTER( VALUES(dVendedores[_CODVEND]), [Rank Vendedor $] = 8 ))
```

**Top 9 Atingimento**

```dax
CALCULATE( [% Ating Meta (KG)], FILTER( VALUES(dVendedores[_CODVEND]), [Rank Vendedor $] = 9 ))
```

**Top 10 Atingimento**

```dax
CALCULATE( [% Ating Meta (KG)], FILTER( VALUES(dVendedores[_CODVEND]), [Rank Vendedor $] = 10 ))
```

**Top 6 Nome**

```dax
CALCULATE( SELECTEDVALUE(dVendedores[_NOMEVEND], FILTER( VALUES(dVendedores[_ALIAS]), [Rank Vendedor $] = 6 )))
```

**Top 7 Nome**

```dax
CALCULATE( SELECTEDVALUE(dVendedores[_NOMEVEND], FILTER( VALUES(dVendedores[_ALIAS]), [Rank Vendedor $] = 7 )))
```

**Top 8 Nome**

```dax
CALCULATE( SELECTEDVALUE(dVendedores[_NOMEVEND], FILTER( VALUES(dVendedores[_ALIAS]), [Rank Vendedor $] = 8 )))
```

**Top 9 Nome**

```dax
CALCULATE( SELECTEDVALUE(dVendedores[_NOMEVEND], FILTER( VALUES(dVendedores[_ALIAS]), [Rank Vendedor $] = 9 )))
```

**Top 10 Nome**

```dax
CALCULATE( SELECTEDVALUE(dVendedores[_NOMEVEND], FILTER( VALUES(dVendedores[_ALIAS]), [Rank Vendedor $] = 10 )))
```

**Top 11 Nome**

```dax
CALCULATE( SELECTEDVALUE(dVendedores[_NOMEVEND], FILTER( VALUES(dVendedores[_ALIAS]), [Rank Vendedor $] = 11 )))
```

**Top 11 Atingimento**

```dax
CALCULATE( [% Ating Meta (KG)], FILTER( VALUES(dVendedores[_CODVEND]), [Rank Vendedor $] = 11 ))
```
