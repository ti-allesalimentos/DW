# Modelo semantico: Produção

- Tabelas: 43
- Colunas: 403
- Medidas DAX: 53
- Relacionamentos: 38 (0 inativos, 1 bidirecionais)

## Tabelas

| Tabela | Colunas | Medidas |
|--------|--------:|--------:|
| ApontamentoOP | 16 | 26 |
| DateTableTemplate_fa31bf11-0b80-4859-8584-abc19c835bae | 7 | 0 |
| FMetas | 3 | 0 |
| FluxoAPONTAMENTODEPRODUCAO | 1 | 0 |
| FluxodCalendario | 1 | 0 |
| FluxodProdutos | 1 | 0 |
| FluxofCusto | 1 | 0 |
| Horas Trabalhadas | 3 | 0 |
| LocalDateTable_0df0d69a-f93f-4de9-b243-f9182c055bf7 | 7 | 0 |
| LocalDateTable_120d61a3-4556-464c-ba81-efebf6bd2404 | 7 | 0 |
| LocalDateTable_23b31689-4f29-4385-9158-8debcae57293 | 7 | 0 |
| LocalDateTable_3f6de3cc-ca2e-460a-80e8-319eb6074a1c | 7 | 0 |
| LocalDateTable_4fb402dd-44d5-4302-824a-cd05f550413d | 7 | 0 |
| LocalDateTable_5ec29932-f2a3-47bf-bfed-476d5f01e986 | 7 | 0 |
| LocalDateTable_64622fc9-c3e2-45c0-a84a-f32bbe2fe705 | 7 | 0 |
| LocalDateTable_9b43a8ad-3e63-487c-9fb3-cc584cc944d2 | 7 | 0 |
| LocalDateTable_9cbd2f55-5645-437d-bc92-6bd5c5a59d69 | 7 | 0 |
| LocalDateTable_9f6ea664-d7ab-4367-ad9c-0aa90d824bde | 7 | 0 |
| LocalDateTable_a2ce9b81-a5cf-4445-93a1-4eb40fd3b6a7 | 7 | 0 |
| LocalDateTable_af49816b-e04f-41e4-83d0-7b45e826f0f8 | 7 | 0 |
| LocalDateTable_b09c0c45-52f2-4e26-9ea5-d3909c6ad329 | 7 | 0 |
| LocalDateTable_b9f9ac5f-cdff-4048-bf11-3537248a1635 | 7 | 0 |
| LocalDateTable_c6db1dd6-43f8-43dd-b0e1-5acfc39ddf63 | 7 | 0 |
| LocalDateTable_c6f8464b-68ab-4924-a69d-e783e9bd2d41 | 7 | 0 |
| LocalDateTable_ce2327a6-b189-432a-a2a3-7479adda6a46 | 7 | 0 |
| LocalDateTable_cf13415c-4385-4b34-8287-9a1f2971e27e | 7 | 0 |
| LocalDateTable_de91def9-d0e8-464b-a773-182994ca5284 | 7 | 0 |
| LocalDateTable_e2244402-bdbc-4225-94ea-ec2da290b1c7 | 7 | 0 |
| LocalDateTable_e926b76f-f2d5-44fe-9d97-21855db1d976 | 7 | 0 |
| LocalDateTable_f2c7cbae-ac08-4274-b91c-db30d1083d57 | 7 | 0 |
| LocalDateTable_f46506e8-8883-4368-8549-0a5dd145d514 | 7 | 0 |
| LocalDateTable_f59b84da-bc12-404e-a6a7-20410b8c8eff | 7 | 0 |
| dAtualizacao | 3 | 0 |
| dCalendar | 114 | 0 |
| dConsumo | 9 | 0 |
| dFamilia | 6 | 0 |
| dOP | 6 | 0 |
| dProdutosAuxiliar | 4 | 0 |
| dTempo | 10 | 2 |
| fCCusto | 8 | 0 |
| fLancamentos | 18 | 25 |
| fPerdas | 9 | 0 |
| fProducao | 15 | 0 |

## Relacionamentos

| De | Para | Cardinalidade | Filtro | Ativo |
|----|------|---------------|--------|-------|
| dCalendar.Data | LocalDateTable_b9f9ac5f-cdff-4048-bf11-3537248a1635.Date | many->one | singleDirection | sim |
| dCalendar.AnoInicio | LocalDateTable_5ec29932-f2a3-47bf-bfed-476d5f01e986.Date | many->one | singleDirection | sim |
| dCalendar.AnoFim | LocalDateTable_9f6ea664-d7ab-4367-ad9c-0aa90d824bde.Date | many->one | singleDirection | sim |
| dCalendar.MesInicio | LocalDateTable_0df0d69a-f93f-4de9-b243-f9182c055bf7.Date | many->one | singleDirection | sim |
| dCalendar.MesFim | LocalDateTable_9cbd2f55-5645-437d-bc92-6bd5c5a59d69.Date | many->one | singleDirection | sim |
| dCalendar.TrimestreInicio | LocalDateTable_120d61a3-4556-464c-ba81-efebf6bd2404.Date | many->one | singleDirection | sim |
| dCalendar.TrimestreFim | LocalDateTable_b09c0c45-52f2-4e26-9ea5-d3909c6ad329.Date | many->one | singleDirection | sim |
| dCalendar.SemanaInicioISO | LocalDateTable_9b43a8ad-3e63-487c-9fb3-cc584cc944d2.Date | many->one | singleDirection | sim |
| dCalendar.SemanaFimISO | LocalDateTable_c6f8464b-68ab-4924-a69d-e783e9bd2d41.Date | many->one | singleDirection | sim |
| dCalendar.DataDeFechamentoRef | LocalDateTable_cf13415c-4385-4b34-8287-9a1f2971e27e.Date | many->one | singleDirection | sim |
| dCalendar.AnoFiscalInicio | LocalDateTable_3f6de3cc-ca2e-460a-80e8-319eb6074a1c.Date | many->one | singleDirection | sim |
| dCalendar.AnoFiscalFim | LocalDateTable_f2c7cbae-ac08-4274-b91c-db30d1083d57.Date | many->one | singleDirection | sim |
| dCalendar.TrimestreFiscalInicio | LocalDateTable_64622fc9-c3e2-45c0-a84a-f32bbe2fe705.Date | many->one | singleDirection | sim |
| dCalendar.TrimestreFiscalFim | LocalDateTable_4fb402dd-44d5-4302-824a-cd05f550413d.Date | many->one | singleDirection | sim |
| ApontamentoOP.DTPROD | dCalendar.Data | many->one | singleDirection | sim |
| ApontamentoOP.HORAINI | dTempo.Horario | many->one | singleDirection | sim |
| ApontamentoOP.CODPROD | dProdutosAuxiliar.Codigo | many->one | singleDirection | sim |
| dCalendar.DiaDaSemanaNome | 'Horas Trabalhadas'.DIA | many->one | singleDirection | sim |
| fLancamentos.EMISSAO | dCalendar.Data | many->one | singleDirection | sim |
| fLancamentos.OP | dOP.OP | many->one | singleDirection | sim |
| FMetas.'Consulta1.Data' | dCalendar.Data | many->one | singleDirection | sim |
| ApontamentoOP.CODPROD | dFamilia.COD | many->one | singleDirection | sim |
| dOP.CODPRODU | dProdutosAuxiliar.Codigo | many->one | singleDirection | sim |
| fLancamentos.'dOP.CODPRODU' | dFamilia.COD | many->one | singleDirection | sim |
| dAtualizacao.DataHora | LocalDateTable_23b31689-4f29-4385-9158-8debcae57293.Date | many->one | singleDirection | sim |
| dAtualizacao.Data | LocalDateTable_a2ce9b81-a5cf-4445-93a1-4eb40fd3b6a7.Date | many->one | singleDirection | sim |
| fCCusto.DTEMISSAO | LocalDateTable_ce2327a6-b189-432a-a2a3-7479adda6a46.Date | many->one | singleDirection | sim |
| fProducao.DTPROD | LocalDateTable_c6db1dd6-43f8-43dd-b0e1-5acfc39ddf63.Date | many->one | singleDirection | sim |
| fProducao.OP | dOP.OP | many->one | singleDirection | sim |
| fPerdas.BC_OP | dOP.OP | many->one | singleDirection | sim |
| fPerdas.BC_OP | fLancamentos.OP | many->many | bothDirections | sim |
| fPerdas.DTLANCAMENTO | dCalendar.Data | many->one | singleDirection | sim |
| dCalendar.MesAnoNome | LocalDateTable_e926b76f-f2d5-44fe-9d97-21855db1d976.Date | many->one | singleDirection | sim |
| dCalendar.MesDiaNome | LocalDateTable_de91def9-d0e8-464b-a773-182994ca5284.Date | many->one | singleDirection | sim |
| dCalendar.QuinzenaMesNome | LocalDateTable_af49816b-e04f-41e4-83d0-7b45e826f0f8.Date | many->one | singleDirection | sim |
| dCalendar.MesAnoFechamentoNome | LocalDateTable_e2244402-bdbc-4225-94ea-ec2da290b1c7.Date | many->one | singleDirection | sim |
| fProducao.HORAINI | LocalDateTable_f46506e8-8883-4368-8549-0a5dd145d514.Date | many->one | singleDirection | sim |
| fProducao.HORAFIM | LocalDateTable_f59b84da-bc12-404e-a6a7-20410b8c8eff.Date | many->one | singleDirection | sim |

## Medidas DAX

### ApontamentoOP

**Produção TurnoA**

```dax
CALCULATE( SUM(ApontamentoOP[QtdProduzida]), ApontamentoOP[TURNO] = "TURNO A" )
```

**Produção TunoB**

```dax
CALCULATE( SUM(ApontamentoOP[QtdProduzida]), ApontamentoOP[TURNO] = "TURNO B" )
```

**Produção Total**

```dax
``` SUM(ApontamentoOP[QTDPRODUZIDA]) ```
```

**Meta Total**

```dax
SUM(FMetas[Valor])
```

**% Atingimento**

```dax
- (DIVIDE([Meta Total] - [Produção Total], [Meta Total])) + 1
```

**Meta Almôndega**

```dax
CALCULATE( SUM(FMetas[Valor]), FMetas[familia] = "ALMONDEGA" )
```

**Produção Almôndega**

```dax
CALCULATE( SUM(ApontamentoOP[QTDPRODUZIDA]), ApontamentoOP[OPERACAO] = "ALMONDEGA" )
```

**% Atingimento Almondega**

```dax
- (DIVIDE([Meta Almôndega] - [Produção Almôndega], [Meta Almôndega])) + 1
```

**Meta Hamburguer**

```dax
CALCULATE( SUM(FMetas[Valor]), FMetas[familia] = "HAMBURGUER" )
```

**Produção CarneMoida**

```dax
CALCULATE( SUM(ApontamentoOP[QTDPRODUZIDA]), ApontamentoOP[OPERACAO] = "CARNE MOIDA" )
```

**Produção Calabresa**

```dax
CALCULATE( SUM(ApontamentoOP[QTDPRODUZIDA]), ApontamentoOP[OPERACAO] = "CALABRESA" )
```

**Produção Linguica**

```dax
CALCULATE( SUM(ApontamentoOP[QTDPRODUZIDA]), ApontamentoOP[OPERACAO] = "LINGUICA" )
```

**Produção Salsicha**

```dax
CALCULATE( SUM(ApontamentoOP[QTDPRODUZIDA]), ApontamentoOP[OPERACAO] = "SALSICHA" )
```

**Produção Mortadela**

```dax
CALCULATE( SUM(ApontamentoOP[QTDPRODUZIDA]), ApontamentoOP[OPERACAO] = "MORTADELA" )
```

**Meta CarneMoida**

```dax
CALCULATE( SUM(FMetas[Valor]), FMetas[familia] = "CARNE MOIDA" )
```

**Meta Calabresa**

```dax
CALCULATE( SUM(FMetas[Valor]), FMetas[familia] = "CALABRESA" )
```

**Meta Linguica**

```dax
CALCULATE( SUM(FMetas[Valor]), FMetas[familia] = "LINGUICA" )
```

**Meta Mortadela**

```dax
CALCULATE( SUM(FMetas[Valor]), FMetas[familia] = "MORTADELA" )
```

**Meta Salsicha**

```dax
CALCULATE( SUM(FMetas[Valor]), FMetas[familia] = "SALSICHA" )
```

**Produção Hamburguer**

```dax
CALCULATE( SUM(ApontamentoOP[QTDPRODUZIDA]), ApontamentoOP[OPERACAO] = "HAMBURGUER" )
```

**% Atingimento Calabresa**

```dax
``` - (DIVIDE([Meta Calabresa] - [Produção Calabresa], [Meta Calabresa])) + 1 ```
```

**% Atingimento CarneMoida**

```dax
``` - (DIVIDE([Meta CarneMoida] - [Produção CarneMoida], [Meta CarneMoida])) + 1 ```
```

**% Atingimento Hamburguer**

```dax
``` - (DIVIDE([Meta Hamburguer] - [Produção Hamburguer], [Meta Hamburguer])) + 1 ```
```

**% Atingimento Linguica**

```dax
``` - (DIVIDE([Meta Linguica] - [Produção Linguica], [Meta Linguica])) + 1 ```
```

**% Atingimento Mortadela**

```dax
``` - (DIVIDE([Meta Mortadela] - [Produção Mortadela], [Meta Mortadela])) + 1 ```
```

**% Atingimento Salsicha**

```dax
``` - (DIVIDE([Meta Salsicha] - [Produção Salsicha], [Meta Salsicha])) + 1 ```
```

### dTempo

**PRODUCAOTOTAL**

```dax
SUM(ApontamentoOP[QTDPRODUZIDA])
```

**PRODUCAO_SEMANAL**

```dax
CALCULATE(SUM(ApontamentoOP[QTDPRODUZIDA]),FILTER(ALL(ApontamentoOP),WEEKNUM(ApontamentoOP[DTPROD],2) = WEEKNUM(TODAY(), 2) && YEAR(ApontamentoOP[DTPROD])=YEAR(TODAY())))
```

### fLancamentos

**TotalLancado**

```dax
SUM(fLancamentos[QTD])
```

**Quebra**

```dax
DIVIDE([Produção Total] - [TotalLancado], [Produção Total])
```

**Lancamentos Almôndega**

```dax
CALCULATE( SUM(fLancamentos[QTD]), dFamilia[FAMILIA] = "ALMONDEGA", fLancamentos[CLASSIFICACAO] = "MASSA" )
```

**% Quebra Almondega**

```dax
``` DIVIDE([Produção Almôndega] - fLancamentos[Lancamentos Almôndega], fLancamentos[Lancamentos Almôndega]) ```
```

**Lancamentos CarneMoida**

```dax
CALCULATE( SUM(fLancamentos[QTD]), dFamilia[FAMILIA] = "CARNE MOIDA", fLancamentos[CLASSIFICACAO] = "MASSA" )
```

**Lancamentos Hamburguer**

```dax
CALCULATE( SUM(fLancamentos[QTD]), dFamilia[FAMILIA] = "HAMBURGUER", fLancamentos[CLASSIFICACAO] = "MASSA" )
```

**Lancamentos Calabresa**

```dax
CALCULATE( SUM(fLancamentos[QTD]), dFamilia[FAMILIA] = "CALABRESA", fLancamentos[CLASSIFICACAO] = "MASSA" )
```

**Lancamentos Salsicha**

```dax
CALCULATE( SUM(fLancamentos[QTD]), dFamilia[FAMILIA] = "SALSICHA", fLancamentos[CLASSIFICACAO] = "MASSA" )
```

**Lancamentos Mortadela**

```dax
CALCULATE( SUM(fLancamentos[QTD]), dFamilia[FAMILIA] = "MORTADELA", fLancamentos[CLASSIFICACAO] = "MASSA" )
```

**Lancamentos Linguica**

```dax
CALCULATE( SUM(fLancamentos[QTD]), dFamilia[FAMILIA] = "LINGUICA", fLancamentos[CLASSIFICACAO] = "MASSA" )
```

**% Quebra Carne Moida**

```dax
``` DIVIDE([Produção CarneMoida] - fLancamentos[Lancamentos CarneMoida], fLancamentos[Lancamentos CarneMoida]) ```
```

**% Quebra Hamburguer**

```dax
``` DIVIDE([Produção Hamburguer] - fLancamentos[Lancamentos Hamburguer], fLancamentos[Lancamentos Hamburguer]) ```
```

**% Quebra Calabresa**

```dax
``` DIVIDE([Produção Calabresa] - fLancamentos[Lancamentos Calabresa], fLancamentos[Lancamentos Calabresa]) ```
```

**% Quebra Salsicha**

```dax
``` DIVIDE([Produção Salsicha] - fLancamentos[Lancamentos Salsicha], fLancamentos[Lancamentos Salsicha]) ```
```

**% Quebra Linguica**

```dax
``` DIVIDE([Produção Linguica] - fLancamentos[Lancamentos Linguica], fLancamentos[Lancamentos Linguica]) ```
```

**% Quebra Mortadela**

```dax
``` DIVIDE([Produção Mortadela] - fLancamentos[Lancamentos Mortadela], fLancamentos[Lancamentos Mortadela]) ```
```

**Título Velocímetro Almôndega**

```dax
``` VAR Valor = DIVIDE([Produção Almôndega] - fLancamentos[Lancamentos Almôndega], fLancamentos[Lancamentos Almôndega], 0) RETURN IF(Valor >= 0, "% Rendimento Almôndega", "% Quebra Almôndega") ```
```

**Título Velocímetro Calabresa**

```dax
``` VAR Valor = DIVIDE([Produção Calabresa] - fLancamentos[Lancamentos Calabresa], fLancamentos[Lancamentos Calabresa], 0) RETURN IF(Valor >= 0, "% Rendimento Calabresa", "% Quebra Calabresa") ```
```

**Título Velocímetro Carne Moída**

```dax
``` VAR Valor = DIVIDE([Produção CarneMoida] - fLancamentos[Lancamentos CarneMoida], fLancamentos[Lancamentos CarneMoida], 0) RETURN IF(Valor >= 0, "% Rendimento Carne Moída", "% Quebra Carne Moída") ```
```

**Título Velocímetro Hambúrguer**

```dax
``` VAR Valor = DIVIDE([Produção Hamburguer] - fLancamentos[Lancamentos Hamburguer], fLancamentos[Lancamentos Hamburguer], 0) RETURN IF(Valor >= 0, "% Rendimento Hambúrguer", "% Quebra Hambúrguer") ```
```

**Título Velocímetro Linguiça**

```dax
``` VAR Valor = DIVIDE([Produção Linguica] - fLancamentos[Lancamentos Linguica], fLancamentos[Lancamentos Linguica], 0) RETURN IF(Valor >= 0, "% Rendimento Linguiça", "% Quebra Linguiça") ```
```

**Título Velocímetro Mortadela**

```dax
``` VAR Valor = DIVIDE([Produção Mortadela] - fLancamentos[Lancamentos Mortadela], fLancamentos[Lancamentos Mortadela], 0) RETURN IF(Valor >= 0, "% Rendimento Mortadela", "% Quebra Mortadela") ```
```

**Título Velocímetro Salsicha**

```dax
``` VAR Valor = DIVIDE([Produção Salsicha] - fLancamentos[Lancamentos Salsicha], fLancamentos[Lancamentos Salsicha], 0) RETURN IF(Valor >= 0, "% Rendimento Salsicha", "% Quebra Salsicha") ```
```

**Título Velocímetro Quebra**

```dax
``` VAR Valor = DIVIDE([Produção Total] - [TotalLancado], [Produção Total], 0) RETURN IF(Valor >= 0, "% Rendimento Total", "% Quebra Total") ```
```

**Top5**

```dax
RANKX(ALL(fLancamentos[PRODUTO]),[TotalLancado])
```
