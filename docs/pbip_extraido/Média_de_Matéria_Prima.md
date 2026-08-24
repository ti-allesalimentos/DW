# Modelo semantico: Média de Matéria Prima

- Tabelas: 38
- Colunas: 350
- Medidas DAX: 4
- Relacionamentos: 30 (0 inativos, 0 bidirecionais)

## Tabelas

| Tabela | Colunas | Medidas |
|--------|--------:|--------:|
| DateTableTemplate_d56b9d9b-a7f1-44b1-9cdf-9d53d8880eb1 | 7 | 0 |
| Filial | 2 | 0 |
| FluxodCalendario | 1 | 0 |
| FluxodCompras | 1 | 0 |
| FluxodProdutos | 1 | 0 |
| FluxodSaldoAtual | 1 | 0 |
| FluxofCusto | 1 | 0 |
| LocalDateTable_0285440b-8965-4b5a-ab26-2aa62f622a7d | 7 | 0 |
| LocalDateTable_0c9c01cc-ee75-4699-ac6f-7d6ba61d7a77 | 7 | 0 |
| LocalDateTable_138692f2-2d2f-4cc2-8721-97f5a5699d06 | 7 | 0 |
| LocalDateTable_1d62a5bf-4305-4cd6-85ac-a3901777d951 | 7 | 0 |
| LocalDateTable_252655f6-48c5-4e4c-9d23-43d4db1e7395 | 7 | 0 |
| LocalDateTable_2b679daf-2575-47e7-b3c6-fda984d373b1 | 7 | 0 |
| LocalDateTable_2dd86942-d685-4ab2-b4f0-ca4ab76de4ab | 7 | 0 |
| LocalDateTable_327007b2-6b19-4f8d-ae0d-aebbcfb1a742 | 7 | 0 |
| LocalDateTable_35fc43bf-dca7-459c-9ae6-cfee7b1b9ef4 | 7 | 0 |
| LocalDateTable_3b170fe6-f689-4bdb-90c5-c5a4f7dafa2f | 7 | 0 |
| LocalDateTable_4495f189-6319-431f-9504-5c0155451549 | 7 | 0 |
| LocalDateTable_44a41642-de1d-4b23-bbfe-0e9175b85d32 | 7 | 0 |
| LocalDateTable_47e3e3b2-713b-4ce0-a587-2dac24715613 | 7 | 0 |
| LocalDateTable_4c1bbab6-2e36-451a-a4e9-199ad0c69cd7 | 7 | 0 |
| LocalDateTable_95024ac6-31e1-4986-868f-23b61eea405a | 7 | 0 |
| LocalDateTable_aabad2a3-d383-460e-aca8-61d03d056acf | 7 | 0 |
| LocalDateTable_ab9f8c12-569b-4ea4-9fb5-819ad44333b2 | 7 | 0 |
| LocalDateTable_c08936df-b583-4aae-af74-5615f92ece67 | 7 | 0 |
| LocalDateTable_d83575a2-a197-4851-a192-45c876ffc98c | 7 | 0 |
| LocalDateTable_e80f1451-4400-4610-a3cb-c299780fef20 | 7 | 0 |
| MEDIA | 1 | 1 |
| MEDIDAS | 1 | 2 |
| dAtravessador | 13 | 0 |
| dAtt | 3 | 0 |
| dCalendar | 114 | 0 |
| dComissao | 10 | 0 |
| dFornecedor | 13 | 0 |
| dGrupo | 2 | 0 |
| dProdutos | 9 | 0 |
| dSaldoMP | 6 | 1 |
| fEntradas | 24 | 0 |

## Relacionamentos

| De | Para | Cardinalidade | Filtro | Ativo |
|----|------|---------------|--------|-------|
| dSaldoMP.CODPROD | dProdutos._CODPRODUTO | many->one | singleDirection | sim |
| dProdutos._GRUPOESTOQUE | dGrupo.GRUPO | many->one | singleDirection | sim |
| dAtt.Data | LocalDateTable_e80f1451-4400-4610-a3cb-c299780fef20.Date | many->one | singleDirection | sim |
| fEntradas.CODIGO | dProdutos._CODPRODUTO | many->one | singleDirection | sim |
| dComissao.CHAVE | dFornecedor.CHAVE | many->one | singleDirection | sim |
| fEntradas.CHAVE | dFornecedor.CHAVE | many->one | singleDirection | sim |
| dSaldoMP.FILIAL | Filial.Filial | many->one | singleDirection | sim |
| dComissao.FILIAL | Filial.Filial | many->one | singleDirection | sim |
| fEntradas.FILIAL | Filial.Filial | many->one | singleDirection | sim |
| dCalendar.Data | LocalDateTable_0285440b-8965-4b5a-ab26-2aa62f622a7d.Date | many->one | singleDirection | sim |
| dCalendar.AnoInicio | LocalDateTable_c08936df-b583-4aae-af74-5615f92ece67.Date | many->one | singleDirection | sim |
| dCalendar.AnoFim | LocalDateTable_138692f2-2d2f-4cc2-8721-97f5a5699d06.Date | many->one | singleDirection | sim |
| dCalendar.MesInicio | LocalDateTable_3b170fe6-f689-4bdb-90c5-c5a4f7dafa2f.Date | many->one | singleDirection | sim |
| dCalendar.MesFim | LocalDateTable_2b679daf-2575-47e7-b3c6-fda984d373b1.Date | many->one | singleDirection | sim |
| dCalendar.TrimestreInicio | LocalDateTable_4c1bbab6-2e36-451a-a4e9-199ad0c69cd7.Date | many->one | singleDirection | sim |
| dCalendar.TrimestreFim | LocalDateTable_252655f6-48c5-4e4c-9d23-43d4db1e7395.Date | many->one | singleDirection | sim |
| dCalendar.SemanaInicioISO | LocalDateTable_2dd86942-d685-4ab2-b4f0-ca4ab76de4ab.Date | many->one | singleDirection | sim |
| dCalendar.SemanaFimISO | LocalDateTable_35fc43bf-dca7-459c-9ae6-cfee7b1b9ef4.Date | many->one | singleDirection | sim |
| dCalendar.DataDeFechamentoRef | LocalDateTable_aabad2a3-d383-460e-aca8-61d03d056acf.Date | many->one | singleDirection | sim |
| dCalendar.AnoFiscalInicio | LocalDateTable_47e3e3b2-713b-4ce0-a587-2dac24715613.Date | many->one | singleDirection | sim |
| dCalendar.AnoFiscalFim | LocalDateTable_44a41642-de1d-4b23-bbfe-0e9175b85d32.Date | many->one | singleDirection | sim |
| dCalendar.TrimestreFiscalInicio | LocalDateTable_4495f189-6319-431f-9504-5c0155451549.Date | many->one | singleDirection | sim |
| dCalendar.TrimestreFiscalFim | LocalDateTable_95024ac6-31e1-4986-868f-23b61eea405a.Date | many->one | singleDirection | sim |
| fEntradas.DTEMISSAO | LocalDateTable_d83575a2-a197-4851-a192-45c876ffc98c.Date | many->one | singleDirection | sim |
| fEntradas.DTLANCAMENTO | dCalendar.Data | many->one | singleDirection | sim |
| fEntradas.CHAVE-ATARVE | dAtravessador.CHAVE | many->one | singleDirection | sim |
| dCalendar.MesAnoNome | LocalDateTable_1d62a5bf-4305-4cd6-85ac-a3901777d951.Date | many->one | singleDirection | sim |
| dCalendar.MesDiaNome | LocalDateTable_327007b2-6b19-4f8d-ae0d-aebbcfb1a742.Date | many->one | singleDirection | sim |
| dCalendar.QuinzenaMesNome | LocalDateTable_0c9c01cc-ee75-4699-ac6f-7d6ba61d7a77.Date | many->one | singleDirection | sim |
| dCalendar.MesAnoFechamentoNome | LocalDateTable_ab9f8c12-569b-4ea4-9fb5-819ad44333b2.Date | many->one | singleDirection | sim |

## Medidas DAX

### MEDIA

**Medida Filtro Fornecedor**

```dax
VAR _OpcaoSelecionada = SELECTEDVALUE(MEDIA[Modo]) RETURN SWITCH ( TRUE(), _OpcaoSelecionada = "Compra", NOT(MAX(fEntradas[CODFOR]) = "MEDIA"), _OpcaoSelecionada = "Geral", TRUE(), TRUE() )
```

### MEDIDAS

**CM Unitário Ponderado**

```dax
DIVIDE ( SUM(fEntradas[Vr Custo Total]), SUM(fEntradas[Qtd]), 0 )
```

**CM Unitário**

```dax
DIVIDE ( SUM(fEntradas[Vr Total]), SUM(fEntradas[Qtd]), 0 )
```

### dSaldoMP

**CustoTotal**

```dax
SUMX(dSaldoMP, dSaldoMP[QTDATUAL] * dSaldoMP[CM])
```
