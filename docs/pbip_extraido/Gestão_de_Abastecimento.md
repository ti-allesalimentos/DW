# Modelo semantico: Gestão de Abastecimento

- Tabelas: 49
- Colunas: 438
- Medidas DAX: 17
- Relacionamentos: 45 (0 inativos, 2 bidirecionais)

## Tabelas

| Tabela | Colunas | Medidas |
|--------|--------:|--------:|
| DateTableTemplate_6ccb1288-1aa6-4b19-b5da-b22b6a473d9b | 7 | 0 |
| FluxodCalendario | 1 | 0 |
| FluxodCompras | 1 | 0 |
| FluxodProdutos | 1 | 0 |
| FluxofCompras | 1 | 0 |
| FluxofCusto | 1 | 0 |
| LocalDateTable_03ad2f83-b340-4bef-aec3-bdf3bcc9789c | 7 | 0 |
| LocalDateTable_0a2354f3-5018-4bbd-8196-ea21ece6b9c1 | 7 | 0 |
| LocalDateTable_10c5de2a-0c4e-4bde-a0de-8b0d65d24334 | 7 | 0 |
| LocalDateTable_36d18837-12ea-44d7-9fe9-a802519f5741 | 7 | 0 |
| LocalDateTable_3fc50039-2d57-4957-baf4-03185de11cf2 | 7 | 0 |
| LocalDateTable_4288a2f3-0e48-4f41-8bf7-773cbfa5832f | 7 | 0 |
| LocalDateTable_438e23e4-3674-441b-b8ed-5190cbe3016d | 7 | 0 |
| LocalDateTable_45b4a1d8-c5f8-41db-8c0e-c1f06595528e | 7 | 0 |
| LocalDateTable_529fca75-0c98-4f6f-aae9-5cb591188414 | 7 | 0 |
| LocalDateTable_59b207d2-649d-4541-9dbc-e6f3f9fcf1c4 | 7 | 0 |
| LocalDateTable_5a46859f-a2f8-4bc1-ae64-a4abb43c8aa6 | 7 | 0 |
| LocalDateTable_620a44c0-a440-44aa-878e-f94ae7168442 | 7 | 0 |
| LocalDateTable_626b6501-b4a3-4bd3-95d1-30f7bd58e871 | 7 | 0 |
| LocalDateTable_62aad389-4d47-4a58-9bd8-e639190fdd47 | 7 | 0 |
| LocalDateTable_703187eb-8bb1-4480-ac49-5bf3b8e646ab | 7 | 0 |
| LocalDateTable_7451be9f-7933-4e80-8956-0496eca6feaf | 7 | 0 |
| LocalDateTable_74a7a006-7e84-49f0-b103-66ca6e709188 | 7 | 0 |
| LocalDateTable_78e5b560-f5df-4b93-bd6d-1d4335f2609e | 7 | 0 |
| LocalDateTable_88435b9a-4409-4a83-9cbd-404d3a294c3e | 7 | 0 |
| LocalDateTable_891bfe04-151e-41b0-998e-9636d9eb9da8 | 7 | 0 |
| LocalDateTable_8df1928a-105f-4a34-9001-87341e07d379 | 7 | 0 |
| LocalDateTable_99d56ee8-8563-4d48-a9e2-dc3e75c93cb1 | 7 | 0 |
| LocalDateTable_c6a2a783-ccf3-43f6-ac91-795bd2e4d123 | 7 | 0 |
| LocalDateTable_cec5c058-08ca-410b-927c-62d11dd1e139 | 7 | 0 |
| LocalDateTable_d1fdaa90-bfc4-4575-b4cd-869bb566a630 | 7 | 0 |
| LocalDateTable_e10d7384-b8ec-4fd3-a153-76c02ec3e3c2 | 7 | 0 |
| LocalDateTable_fb205a33-013a-4db8-8516-df4c655d780c | 7 | 0 |
| LocalDateTable_fec4e809-ada0-4f74-a652-a4f0ca99dcb9 | 7 | 0 |
| Medidas | 1 | 17 |
| dAgrupador | 2 | 0 |
| dAgrupadorPA | 2 | 0 |
| dCalendar | 114 | 0 |
| dDescReduz | 4 | 0 |
| dFamilia | 5 | 0 |
| dFormulaPadrao | 9 | 0 |
| dFornecedor | 4 | 0 |
| dProdutos | 8 | 0 |
| dProdutosAcabados | 8 | 0 |
| fEntradas | 12 | 0 |
| fGPT | 23 | 0 |
| fPedCompra | 25 | 0 |
| fPrevisProducao | 8 | 0 |
| fSaldoFisico | 5 | 0 |

## Relacionamentos

| De | Para | Cardinalidade | Filtro | Ativo |
|----|------|---------------|--------|-------|
| fGPT.'DT HORA FIM' | LocalDateTable_74a7a006-7e84-49f0-b103-66ca6e709188.Date | many->one | singleDirection | sim |
| fPedCompra.'INICIO DA COMPRA' | LocalDateTable_626b6501-b4a3-4bd3-95d1-30f7bd58e871.Date | many->one | singleDirection | sim |
| fPedCompra.'INICIO DE TRANSITO' | LocalDateTable_5a46859f-a2f8-4bc1-ae64-a4abb43c8aa6.Date | many->one | singleDirection | sim |
| fEntradas.DTEMISSAO | LocalDateTable_88435b9a-4409-4a83-9cbd-404d3a294c3e.Date | many->one | singleDirection | sim |
| fEntradas.DTLANCAMENTO | LocalDateTable_0a2354f3-5018-4bbd-8196-ea21ece6b9c1.Date | many->one | singleDirection | sim |
| fGPT.'fEntradas.DTEMISSAO' | LocalDateTable_03ad2f83-b340-4bef-aec3-bdf3bcc9789c.Date | many->one | singleDirection | sim |
| dFamilia.COD | dDescReduz.Codigo | one->one | bothDirections | sim |
| fPedCompra.PRODUTO | dProdutos._CODPRODUTO | many->one | singleDirection | sim |
| fEntradas.CODIGO | dProdutos._CODPRODUTO | many->one | singleDirection | sim |
| fGPT.'fEntradas.CODIGO' | dProdutos._CODPRODUTO | many->one | singleDirection | sim |
| dFormulaPadrao.CODPROD | dProdutos._CODPRODUTO | many->one | singleDirection | sim |
| fPedCompra.CHAVEFORNECEDOR | dFornecedor.CHAVEFORNECEDOR | many->one | singleDirection | sim |
| fEntradas.CHAVEFORNECEDOR | dFornecedor.CHAVEFORNECEDOR | many->one | singleDirection | sim |
| fSaldoFisico.B2_COD | dProdutos._CODPRODUTO | many->one | singleDirection | sim |
| dCalendar.Data | LocalDateTable_c6a2a783-ccf3-43f6-ac91-795bd2e4d123.Date | many->one | singleDirection | sim |
| dCalendar.AnoInicio | LocalDateTable_d1fdaa90-bfc4-4575-b4cd-869bb566a630.Date | many->one | singleDirection | sim |
| dCalendar.AnoFim | LocalDateTable_7451be9f-7933-4e80-8956-0496eca6feaf.Date | many->one | singleDirection | sim |
| dCalendar.MesInicio | LocalDateTable_78e5b560-f5df-4b93-bd6d-1d4335f2609e.Date | many->one | singleDirection | sim |
| dCalendar.MesFim | LocalDateTable_438e23e4-3674-441b-b8ed-5190cbe3016d.Date | many->one | singleDirection | sim |
| dCalendar.TrimestreInicio | LocalDateTable_4288a2f3-0e48-4f41-8bf7-773cbfa5832f.Date | many->one | singleDirection | sim |
| dCalendar.TrimestreFim | LocalDateTable_620a44c0-a440-44aa-878e-f94ae7168442.Date | many->one | singleDirection | sim |
| dCalendar.SemanaInicioISO | LocalDateTable_e10d7384-b8ec-4fd3-a153-76c02ec3e3c2.Date | many->one | singleDirection | sim |
| dCalendar.SemanaFimISO | LocalDateTable_529fca75-0c98-4f6f-aae9-5cb591188414.Date | many->one | singleDirection | sim |
| dCalendar.DataDeFechamentoRef | LocalDateTable_59b207d2-649d-4541-9dbc-e6f3f9fcf1c4.Date | many->one | singleDirection | sim |
| dCalendar.AnoFiscalInicio | LocalDateTable_45b4a1d8-c5f8-41db-8c0e-c1f06595528e.Date | many->one | singleDirection | sim |
| dCalendar.AnoFiscalFim | LocalDateTable_703187eb-8bb1-4480-ac49-5bf3b8e646ab.Date | many->one | singleDirection | sim |
| dCalendar.TrimestreFiscalInicio | LocalDateTable_fb205a33-013a-4db8-8516-df4c655d780c.Date | many->one | singleDirection | sim |
| dCalendar.TrimestreFiscalFim | LocalDateTable_3fc50039-2d57-4957-baf4-03185de11cf2.Date | many->one | singleDirection | sim |
| fPrevisProducao.Descricao | dDescReduz.Descricao | many->one | singleDirection | sim |
| dProdutos.B1_X_AGRUP | dAgrupador.Chave | many->one | singleDirection | sim |
| dFormulaPadrao.CODPAI | dProdutosAcabados._CODPRODUTO | many->one | singleDirection | sim |
| dProdutosAcabados.B1_X_AGRUP | dAgrupadorPA.Chave | many->one | singleDirection | sim |
| fPrevisProducao.Codigo | dProdutosAcabados._CODPRODUTO | many->one | singleDirection | sim |
| fPrevisProducao.Data | dCalendar.Data | many->one | singleDirection | sim |
| fPrevisProducao.Codigo | dFormulaPadrao.CODPAI | many->many | bothDirections | sim |
| fPedCompra.'DATA ENTREGUE' | dCalendar.Data | many->one | singleDirection | sim |
| fGPT.'DT HORA INI' | dCalendar.Data | many->one | singleDirection | sim |
| fPedCompra.EMISSAO | LocalDateTable_cec5c058-08ca-410b-927c-62d11dd1e139.Date | many->one | singleDirection | sim |
| dCalendar.MesAnoNome | LocalDateTable_fec4e809-ada0-4f74-a652-a4f0ca99dcb9.Date | many->one | singleDirection | sim |
| dCalendar.MesDiaNome | LocalDateTable_10c5de2a-0c4e-4bde-a0de-8b0d65d24334.Date | many->one | singleDirection | sim |
| dCalendar.MesAnoAtualNome | LocalDateTable_36d18837-12ea-44d7-9fe9-a802519f5741.Date | many->one | singleDirection | sim |
| dCalendar.QuinzenaMesNome | LocalDateTable_99d56ee8-8563-4d48-a9e2-dc3e75c93cb1.Date | many->one | singleDirection | sim |
| dCalendar.MesAnoFechamentoNome | LocalDateTable_8df1928a-105f-4a34-9001-87341e07d379.Date | many->one | singleDirection | sim |
| dProdutos._DTAULTCOMPRA | LocalDateTable_891bfe04-151e-41b0-998e-9636d9eb9da8.Date | many->one | singleDirection | sim |
| dProdutosAcabados._DTAULTCOMPRA | LocalDateTable_62aad389-4d47-4a58-9bd8-e639190fdd47.Date | many->one | singleDirection | sim |

## Medidas DAX

### Medidas

**Peso Inicial**

```dax
AVERAGE(fGPT[PESO INI])
```

**Peso Final**

```dax
AVERAGE(fGPT[PESO FIM])
```

**Diferença de Peso**

```dax
[Peso Inicial] - [Peso Final]
```

**Quantidade NF**

```dax
SUM(fGPT[fEntradas.QTD])
```

**Qtd Veículos**

```dax
DISTINCTCOUNT(fGPT[PLACA])
```

**Tempo Médio de Permanência (Medida Horas)**

```dax
AVERAGEX( 'fGPT', DATEDIFF( fGPT[DT HORA INI], NOW(), HOUR ) )
```

**Previsão Produção**

```dax
SUM(fPrevisProducao[QUANTIDADE])
```

**Qtd por KG**

```dax
SUM(dFormulaPadrao[Consumo por KG])
```

**Qtd Estoque**

```dax
SUMX( VALUES(dProdutos[_DESCPRODUTO]), CALCULATE(SUM(fSaldoFisico[B2_QATU])) )
```

**Estoque - Previsão**

```dax
[Qtd Estoque] - [Consumo Prev]
```

**Qtd Pedido**

```dax
SUMX( VALUES(dProdutos[_DESCPRODUTO]), CALCULATE(SUM(fPedCompra[Qtd Pendente])) )
```

**Necessidade**

```dax
VAR Resultado = [Consumo Prev] - ([Qtd Estoque] + [Qtd Pedido]) RETURN IF( Resultado < 0, 0, Resultado )
```

**Consumo Prev**

```dax
SUMX( dFormulaPadrao, dFormulaPadrao[Consumo por KG] * [Previsão Produção] )
```

**Soma QTD por Status**

```dax
CALCULATE( SUM(fGPT[fEntradas.QTD]), fGPT[STATUS] IN {"AGUARDANDO ENTRADA", "AMOSTRA RETIRADA", "APROVADO"} )
```

**Cor da Linha**

```dax
``` IF( [Necessidade] > 0, "#FF8080", // Vermelho "#80ff80"  // Verde ) ```
```

**Cor da Linha Prev**

```dax
``` IF( [Estoque - Previsão] < 0, "#FF8080", // Vermelho "#80ff80"  // Verde ) ```
```

**Capacidade Prod**

```dax
DIVIDE([Qtd Estoque], [Qtd por KG])
```
