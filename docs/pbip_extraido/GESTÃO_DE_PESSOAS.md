# Modelo semantico: GESTÃO DE PESSOAS

- Tabelas: 64
- Colunas: 873
- Medidas DAX: 41
- Relacionamentos: 52 (0 inativos, 4 bidirecionais)

## Tabelas

| Tabela | Colunas | Medidas |
|--------|--------:|--------:|
| BUDGET | 9 | 0 |
| DateTableTemplate_ee5ceb5f-c5de-4562-ab9a-d23524d0103b | 7 | 0 |
| FluxoGestaoPessoas | 1 | 0 |
| FluxoManual | 1 | 0 |
| FluxodCalendario | 1 | 0 |
| FluxofCusto | 1 | 0 |
| LocalDateTable_105fa702-13a9-4886-8903-d069c24dd9b1 | 7 | 0 |
| LocalDateTable_140681c9-5cfc-4b8b-9a52-888ae4fdae9b | 7 | 0 |
| LocalDateTable_151fce92-520c-412d-a91d-fce4cf346ff8 | 7 | 0 |
| LocalDateTable_1abf9db3-d5a9-479a-b49f-7bfcc30a885a | 7 | 0 |
| LocalDateTable_286be22e-8cd1-4594-80b8-bab2e0cd751d | 7 | 0 |
| LocalDateTable_3092eacd-d8f8-49d4-977b-a2738e45b15e | 7 | 0 |
| LocalDateTable_30d7baf3-7041-4b41-8f18-91c8ee56f5a5 | 7 | 0 |
| LocalDateTable_3be88918-6486-4f23-afdd-6d3039c7a05f | 7 | 0 |
| LocalDateTable_3d0d22c3-ab21-4330-ab90-1cb75fcf6123 | 7 | 0 |
| LocalDateTable_401701e6-6485-4fde-9ce0-17e2ecb58c76 | 7 | 0 |
| LocalDateTable_4926a490-f53e-4397-b46b-678633def673 | 7 | 0 |
| LocalDateTable_4de16a80-56fa-43c5-a623-a5f2c66933cb | 7 | 0 |
| LocalDateTable_5c46ab12-5853-468d-b67d-5529174bef89 | 7 | 0 |
| LocalDateTable_5cccb132-db31-492d-aa41-06978258be52 | 7 | 0 |
| LocalDateTable_5f71ca7a-77f3-4395-a1cf-701f8f9e9524 | 7 | 0 |
| LocalDateTable_60e8954c-1747-46be-942b-bab217254134 | 7 | 0 |
| LocalDateTable_70253bcc-f732-43c3-a2e9-e65cc16e430c | 7 | 0 |
| LocalDateTable_73d57f62-be0e-4ec2-9633-e39062960f67 | 7 | 0 |
| LocalDateTable_771a817c-b81c-41da-b800-c44e582568c9 | 7 | 0 |
| LocalDateTable_80183c80-1bb3-4d7e-8bf6-5743706c895a | 7 | 0 |
| LocalDateTable_85cc0917-f9df-45ef-9d77-c0b90b63e1e3 | 7 | 0 |
| LocalDateTable_8c6a9602-ae6b-4664-a914-3f79276d5ffc | 7 | 0 |
| LocalDateTable_95044764-aef2-4562-9300-0b5d22abf60e | 7 | 0 |
| LocalDateTable_a05ba150-d60f-4814-b680-58534e53ce80 | 7 | 0 |
| LocalDateTable_a42575da-4f77-44d0-9ee7-27af6da75435 | 7 | 0 |
| LocalDateTable_a6c99781-94b9-446c-ab07-d2f8967b055d | 7 | 0 |
| LocalDateTable_a74a132b-3800-4e75-a159-5726bb55e9d1 | 7 | 0 |
| LocalDateTable_ace0a781-dd7a-4fea-92fc-ef2d958a8164 | 7 | 0 |
| LocalDateTable_dad2b1a1-febb-4b34-b436-e840342aca55 | 7 | 0 |
| LocalDateTable_f3cc3aea-ab0d-4f49-b0e0-d63757ff54f0 | 7 | 0 |
| LocalDateTable_f5ca04ea-53d4-4f0f-8984-e5c52728c5d6 | 7 | 0 |
| LocalDateTable_f61be752-2f9d-4278-a225-56a65b19185c | 7 | 0 |
| LocalDateTable_f6276de0-cd7d-4836-9221-c4b93dd006dd | 7 | 0 |
| LocalDateTable_f89f206c-9eeb-48e7-af14-1895a31d03e0 | 7 | 0 |
| LocalDateTable_fbcb7e30-aae7-4eb8-acf6-d0d27516b7ea | 7 | 0 |
| LocalDateTable_febf7926-c566-4a5f-9ab5-ad76ad99226c | 7 | 0 |
| MEDIDAS | 1 | 41 |
| dCTT | 3 | 0 |
| dCalendar | 117 | 0 |
| dDuplaFuncao | 4 | 0 |
| dEventos | 7 | 0 |
| dFuncionarios | 26 | 0 |
| dMotivosRescisão | 3 | 0 |
| dSalarioMinimo | 4 | 0 |
| dVerbas | 122 | 0 |
| fApontamentos | 9 | 0 |
| fApontamentosHist | 9 | 0 |
| fApontamentosUnificado | 10 | 0 |
| fBancodeHoras | 27 | 0 |
| fControleAusencias | 69 | 0 |
| fEmpresas | 2 | 0 |
| fEventosAbonados | 22 | 0 |
| fHistoricoSalarial | 4 | 0 |
| fHorasExtras | 10 | 0 |
| fMarcações | 46 | 0 |
| fMotivoRescisão | 8 | 0 |
| fMovimentosHistorico | 53 | 0 |
| fMovimentosPeriodicos | 45 | 0 |

## Relacionamentos

| De | Para | Cardinalidade | Filtro | Ativo |
|----|------|---------------|--------|-------|
| dFuncionarios.DTNASCIMENTO | LocalDateTable_4de16a80-56fa-43c5-a623-a5f2c66933cb.Date | many->one | singleDirection | sim |
| dFuncionarios.DEMISSÃO | LocalDateTable_286be22e-8cd1-4594-80b8-bab2e0cd751d.Date | many->one | singleDirection | sim |
| dCTT.CC | dFuncionarios.'CENTRO DE CUSTO' | many->many | bothDirections | sim |
| dCalendar.AnoInicio | LocalDateTable_140681c9-5cfc-4b8b-9a52-888ae4fdae9b.Date | many->one | singleDirection | sim |
| dCalendar.AnoFim | LocalDateTable_5cccb132-db31-492d-aa41-06978258be52.Date | many->one | singleDirection | sim |
| dCalendar.MesAnoNome | LocalDateTable_771a817c-b81c-41da-b800-c44e582568c9.Date | many->one | singleDirection | sim |
| dCalendar.MesDiaNome | LocalDateTable_dad2b1a1-febb-4b34-b436-e840342aca55.Date | many->one | singleDirection | sim |
| dCalendar.MesInicio | LocalDateTable_3092eacd-d8f8-49d4-977b-a2738e45b15e.Date | many->one | singleDirection | sim |
| dCalendar.MesFim | LocalDateTable_95044764-aef2-4562-9300-0b5d22abf60e.Date | many->one | singleDirection | sim |
| dCalendar.TrimestreInicio | LocalDateTable_60e8954c-1747-46be-942b-bab217254134.Date | many->one | singleDirection | sim |
| dCalendar.TrimestreFim | LocalDateTable_3be88918-6486-4f23-afdd-6d3039c7a05f.Date | many->one | singleDirection | sim |
| dCalendar.SemanaInicioISO | LocalDateTable_30d7baf3-7041-4b41-8f18-91c8ee56f5a5.Date | many->one | singleDirection | sim |
| dCalendar.SemanaFimISO | LocalDateTable_f3cc3aea-ab0d-4f49-b0e0-d63757ff54f0.Date | many->one | singleDirection | sim |
| dCalendar.QuinzenaMesNome | LocalDateTable_1abf9db3-d5a9-479a-b49f-7bfcc30a885a.Date | many->one | singleDirection | sim |
| dCalendar.DataDeFechamentoRef | LocalDateTable_f5ca04ea-53d4-4f0f-8984-e5c52728c5d6.Date | many->one | singleDirection | sim |
| dCalendar.MesAnoFechamentoNome | LocalDateTable_85cc0917-f9df-45ef-9d77-c0b90b63e1e3.Date | many->one | singleDirection | sim |
| dCalendar.AnoFiscalInicio | LocalDateTable_3d0d22c3-ab21-4330-ab90-1cb75fcf6123.Date | many->one | singleDirection | sim |
| dCalendar.AnoFiscalFim | LocalDateTable_151fce92-520c-412d-a91d-fce4cf346ff8.Date | many->one | singleDirection | sim |
| dCalendar.TrimestreFiscalInicio | LocalDateTable_a6c99781-94b9-446c-ab07-d2f8967b055d.Date | many->one | singleDirection | sim |
| dCalendar.TrimestreFiscalFim | LocalDateTable_105fa702-13a9-4886-8903-d069c24dd9b1.Date | many->one | singleDirection | sim |
| BUDGET.BUDGET | LocalDateTable_73d57f62-be0e-4ec2-9633-e39062960f67.Date | many->one | singleDirection | sim |
| dCalendar.Data | BUDGET.BUDGET | one->one | bothDirections | sim |
| dFuncionarios.ADMISSAO | LocalDateTable_5f71ca7a-77f3-4395-a1cf-701f8f9e9524.Date | many->one | singleDirection | sim |
| fControleAusencias.R8_DATA | LocalDateTable_a05ba150-d60f-4814-b680-58534e53ce80.Date | many->one | singleDirection | sim |
| fControleAusencias.R8_DATAINI | LocalDateTable_5c46ab12-5853-468d-b67d-5529174bef89.Date | many->one | singleDirection | sim |
| fControleAusencias.R8_DATAFIM | LocalDateTable_f61be752-2f9d-4278-a225-56a65b19185c.Date | many->one | singleDirection | sim |
| fControleAusencias.CHAVEFILMAT | dFuncionarios.CHAVEFILMAT | many->one | singleDirection | sim |
| fEventosAbonados.PK_DATA | LocalDateTable_ace0a781-dd7a-4fea-92fc-ef2d958a8164.Date | many->one | singleDirection | sim |
| fBancodeHoras.PI_DTBAIX | LocalDateTable_8c6a9602-ae6b-4664-a914-3f79276d5ffc.Date | many->one | singleDirection | sim |
| fApontamentos.DATA | LocalDateTable_a42575da-4f77-44d0-9ee7-27af6da75435.Date | many->one | singleDirection | sim |
| fMarcações.P8_DATA | LocalDateTable_80183c80-1bb3-4d7e-8bf6-5743706c895a.Date | many->one | singleDirection | sim |
| fMarcações.P8_DATAAPO | LocalDateTable_fbcb7e30-aae7-4eb8-acf6-d0d27516b7ea.Date | many->one | singleDirection | sim |
| fMarcações.P8_DATAALT | LocalDateTable_f6276de0-cd7d-4836-9221-c4b93dd006dd.Date | many->one | singleDirection | sim |
| fMovimentosHistorico.RD_DTREF | LocalDateTable_a74a132b-3800-4e75-a159-5726bb55e9d1.Date | many->one | singleDirection | sim |
| fMotivoRescisão.DATADEM | LocalDateTable_70253bcc-f732-43c3-a2e9-e65cc16e430c.Date | many->one | singleDirection | sim |
| fMotivoRescisão.CHAVEFILMAT | dFuncionarios.CHAVEFILMAT | many->one | singleDirection | sim |
| fEventosAbonados.CHAVEFILMAT | dFuncionarios.CHAVEFILMAT | many->one | singleDirection | sim |
| fBancodeHoras.CHAVEFILMAT | dFuncionarios.CHAVEFILMAT | many->one | singleDirection | sim |
| fApontamentos.CHAVEFILMAT | dFuncionarios.CHAVEFILMAT | many->one | singleDirection | sim |
| fBancodeHoras.PI_DATA | dCalendar.Data | many->one | singleDirection | sim |
| dCalendar.MesCompetencia | LocalDateTable_f89f206c-9eeb-48e7-af14-1895a31d03e0.Date | many->one | singleDirection | sim |
| fApontamentosUnificado.CHAVEFILMAT | dFuncionarios.CHAVEFILMAT | many->one | singleDirection | sim |
| fApontamentosHist.CHAVEFILMAT | dFuncionarios.CHAVEFILMAT | many->one | singleDirection | sim |
| fHorasExtras.CHAVEFILMAT | dFuncionarios.CHAVEFILMAT | many->one | singleDirection | sim |
| fMovimentosPeriodicos.CHAVEFILMAT | dFuncionarios.CHAVEFILMAT | many->one | singleDirection | sim |
| fHorasExtras.DATA | dCalendar.Data | many->one | singleDirection | sim |
| dSalarioMinimo.Mês | LocalDateTable_401701e6-6485-4fde-9ce0-17e2ecb58c76.Date | many->one | singleDirection | sim |
| dDuplaFuncao.CHAVEFILMAT | dFuncionarios.CHAVEFILMAT | one->one | bothDirections | sim |
| dCalendar.Data | dSalarioMinimo.Mês | one->one | bothDirections | sim |
| fHistoricoSalarial.DATA_ALT | LocalDateTable_4926a490-f53e-4397-b46b-678633def673.Date | many->one | singleDirection | sim |
| fHistoricoSalarial.CHAVEFILMAT | dFuncionarios.CHAVEFILMAT | many->one | singleDirection | sim |
| fHistoricoSalarial.DATA_FIM | LocalDateTable_febf7926-c566-4a5f-9ab5-ad76ad99226c.Date | many->one | singleDirection | sim |

## Medidas DAX

### MEDIDAS

**Nº Colaboradores**

```dax
CALCULATE( DISTINCTCOUNT(dFuncionarios[Chave]), dFuncionarios[SITUAÇÃO] <> "D" )
```

**Headcount Mês a Mês**

```dax
``` VAR DataFimDoContexto = EOMONTH( MAX('dCalendar'[Data]), 0 ) VAR FuncionariosComViculo = CALCULATETABLE( SUMMARIZE( 'dFuncionarios', 'dFuncionarios'[CHAVEFILMAT] ), 'dFuncionarios'[ADMISSAO] <= DataFimDoContexto, OR( ISBLANK('dFuncionarios'[DEMISSÃO]), 'dFuncionarios'[DEMISSÃO] > DataFimDoContexto ) ) VAR FuncionariosAfastadosNaData = CALCULATETABLE( SUMMARIZE( 'fControleAusencias', 'fControleAusencias'[CHAVEFILMAT] ), 'fControleAusencias'[R8_DATAINI] <= DataFimDoContexto, OR( ISBLANK('fControleAusencias'[R8_DATAFIM]), 'fControleAusencias'[R8_DATAFIM] >= DataFimDoContexto ), 'fControleAusencias'[R8_TIPOAFA] <> "001" ) RETURN COUNTROWS( EXCEPT( FuncionariosComViculo, FuncionariosAfastadosNaData ) ) ```
```

**Contagem Mês Fechado**

```dax
CALCULATE( DISTINCTCOUNT(dFuncionarios[MATRICULA]), FILTER( ALL(dFuncionarios), dFuncionarios[SITUAÇÃO] <> "D" && dFuncionarios[ADMISSAO] <= MAX(dCalendar[Data]) ) )
```

**HeadCout Budget**

```dax
SUM(BUDGET[HEADCOUNT])
```

**Headcount Mês a Mês s Afastados**

```dax
``` VAR DataFimDoContexto = EOMONTH( MAX('dCalendar'[Data]), 0 ) VAR FuncionariosComViculo = CALCULATETABLE( SUMMARIZE( 'dFuncionarios', 'dFuncionarios'[CHAVEFILMAT] ), 'dFuncionarios'[ADMISSAO] <= DataFimDoContexto, OR( ISBLANK('dFuncionarios'[DEMISSÃO]), 'dFuncionarios'[DEMISSÃO] > DataFimDoContexto ) ) VAR FuncionariosAfastadosNaData = CALCULATETABLE( SUMMARIZE( 'fControleAusencias', 'fControleAusencias'[CHAVEFILMAT] ), 'fControleAusencias'[R8_DATAINI] <= DataFimDoContexto, OR( ISBLANK('fControleAusencias'[R8_DATAFIM]), 'fControleAusencias'[R8_DATAFIM] >= DataFimDoContexto ), 'fControleAusencias'[R8_TIPOAFA] <> "001" ) RETURN COUNTROWS( EXCEPT( FuncionariosComViculo, FuncionariosAfastadosNaData ) ) ```
```

**Demitidos**

```dax
CALCULATE( COUNTROWS('dFuncionarios'), 'dFuncionarios'[DEMISSÃO] >= MIN('dCalendar'[Data]), 'dFuncionarios'[DEMISSÃO] <= MAX('dCalendar'[Data]), NOT ISBLANK('dFuncionarios'[DEMISSÃO]) )
```

**Admitidos**

```dax
CALCULATE( COUNTROWS('dFuncionarios'), 'dFuncionarios'[ADMISSAO] >= MIN('dCalendar'[Data]), 'dFuncionarios'[ADMISSAO] <= MAX('dCalendar'[Data]), NOT ISBLANK('dFuncionarios'[ADMISSAO]) )
```

**Turnover**

```dax
``` DIVIDE( [Turnover_Média], [Headcount Mês a Mês], 0 ) ```
```

**Turnover Budget**

```dax
SUM(BUDGET[TURNOVER])
```

**Demitidos por Motivo**

```dax
CALCULATE( COUNTROWS('fMotivoRescisão'), 'fMotivoRescisão'[DATADEM] <= MIN('dCalendar'[Data]) )
```

**Turnover_Média**

```dax
DIVIDE( [Admitidos] + [Demitidos], 2, 0 )
```

**Meses Selecionados**

```dax
``` CALCULATE( DISTINCTCOUNT('dCalendar'[MesAnoNome]), ALLSELECTED('dCalendar') -- Considera todos os meses no contexto atual do filtro de página/visual ) ```
```

**Turnover_Soma_Mensal**

```dax
``` -- SOMA o valor da sua taxa de Turnover em TODOS os meses selecionados SUMX( VALUES('dCalendar'[MesAnoNome]), [Turnover] ) ```
```

**Turnover_Area_Media**

```dax
``` VAR Qtd_Meses = [Meses Selecionados] -- Sua medida de contagem de meses VAR Soma_Taxas = [Turnover_Soma_Mensal] RETURN DIVIDE( Soma_Taxas, Qtd_Meses, 0 ) ```
```

**Saldo BH**

```dax
``` SUMX( VALUES('fBancodeHoras'[CHAVEFILMAT]), VAR _Colaborador = 'fBancodeHoras'[CHAVEFILMAT] VAR _MaxData = CALCULATE( MAX('fBancodeHoras'[PI_DATA]), FILTER( ALL('fBancodeHoras'), 'fBancodeHoras'[CHAVEFILMAT] = _Colaborador ) ) -- 1. CÁLCULO ACUMULADO REAL (em horas decimais - ex: 5.9333...) VAR _SaldoAcumuladoReal = CALCULATE( SUMX( 'fBancodeHoras', VAR _QuantOriginal = 'fBancodeHoras'[PI_QUANT] VAR _Tipo = 'fBancodeHoras'[PI_PD] -- Conversão da Base 60 (Minutos) VAR _HorasCheias = TRUNC(_QuantOriginal) VAR _MinutosDecimais = _QuantOriginal - _HorasCheias VAR _MinutosCorrigidos = _MinutosDecimais / 0.6 VAR _QuantidadeReal = _HorasCheias + _MinutosCorrigidos -- Aplicação do Sinal (010 = CRÉDITO, 014 = DÉBITO) RETURN SWITCH( TRUE(), _Tipo = "010", _QuantidadeReal, _Tipo = "014", -_QuantidadeReal, 0 ) ), FILTER( ALL('fBancodeHoras'), 'fBancodeHoras'[CHAVEFILMAT] = _Colaborador && 'fBancodeHoras'[PI_DATA] <= _MaxData && ISBLANK('fBancodeHoras'[PI_DTBAIX]) ) ) -- 2. FORMATAÇÃO PARA O VISUAL DO PROTHEUS (H,MM) VAR _Horas = TRUNC(ABS(_SaldoAcumuladoReal)) VAR _MinutosReaisDecimais = ABS(_SaldoAcumuladoReal) - _Horas VAR _MinutosProtheus = ROUND(_MinutosReaisDecimais * 60, 0) -- Converte 0.9333 -> 56 VAR _ResultadoFinal = _Horas + (_MinutosProtheus / 100) -- 3. RETORNA O SINAL CORRETO RETURN IF( _SaldoAcumuladoReal < 0, -_ResultadoFinal, _ResultadoFinal ) ) ```
```

**Total Credito Tabela**

```dax
``` VAR _TotalHorasReais = SUMX( FILTER('fBancodeHoras', 'fBancodeHoras'[PI_PD] = "010" && ISBLANK(fBancodeHoras[PI_DTBAIX]) ), VAR _QuantOriginal = 'fBancodeHoras'[PI_QUANT] -- 1. Separa a parte inteira (horas cheias) VAR _HorasCheias = TRUNC(_QuantOriginal) -- 2. Separa a parte decimal (minutos no formato Protheus) VAR _MinutosDecimais = _QuantOriginal - _HorasCheias -- 3. Converte APENAS a parte decimal (minutos) para a base real (÷ 0.6) VAR _MinutosCorrigidos = _MinutosDecimais / 0.6 -- 4. Soma as horas corrigidas VAR _QuantidadeReal = _HorasCheias + _MinutosCorrigidos RETURN _QuantidadeReal ) -- 1. Calcula as horas inteiras VAR _Horas = TRUNC(ABS(_TotalHorasReais)) -- 2. Converte a parte decimal (minutos reais) para minutos inteiros do Protheus (Base 60) VAR _Minutos = ROUND((ABS(_TotalHorasReais) - _Horas) * 60, 0) -- 3. Combina o resultado no formato H,MM (ex: 50.30) VAR _ResultadoHMM = _Horas + (_Minutos / 100) -- 4. Retorna o valor final POSITIVO RETURN _ResultadoHMM ```
```

**Total Débito Tabela**

```dax
``` VAR _TotalHorasReais = SUMX( -- CORREÇÃO: Filtrando para Débito ('010') FILTER('fBancodeHoras', 'fBancodeHoras'[PI_PD] = "014" && ISBLANK(fBancodeHoras[PI_DTBAIX]) ), VAR _QuantOriginal = 'fBancodeHoras'[PI_QUANT] -- Correção da Base 60 para 100 VAR _HorasCheias = TRUNC(_QuantOriginal) VAR _MinutosDecimais = _QuantOriginal - _HorasCheias VAR _MinutosCorrigidos = _MinutosDecimais / 0.6 VAR _QuantidadeReal = _HorasCheias + _MinutosCorrigidos RETURN _QuantidadeReal ) -- 1. Calcula as horas inteiras VAR _Horas = TRUNC(ABS(_TotalHorasReais)) -- 2. Converte a parte decimal (minutos reais) para minutos inteiros do Protheus (Base 60) VAR _Minutos = ROUND((ABS(_TotalHorasReais) - _Horas) * 60, 0) -- 3. Combina o resultado no formato H,MM (ex: 5.56) VAR _ResultadoHMM = _Horas + (_Minutos / 100) -- 4. Aplica o sinal negativo no resultado final RETURN _ResultadoHMM * -1 ```
```

**Saldo BH GB**

```dax
``` VAR _SaldoTotalReais = [Total Credito GB] + [Total Debito GB] -- 1. Pega o valor absoluto para iniciar a formatação VAR _HorasAbsolutas = ABS(_SaldoTotalReais) -- 2. Separa a parte inteira (horas) VAR _Horas = TRUNC(_HorasAbsolutas) -- 3. Separa a parte decimal (minutos reais no formato decimal) VAR _MinutosReaisDecimais = _HorasAbsolutas - _Horas -- 4. Converte os Minutos Reais (Base 100) para Minutos Protheus (Base 60) VAR _MinutosProtheus = ROUND(_MinutosReaisDecimais * 60, 0) -- Ex: 0.9333 * 60 = 56 -- 5. Combina o resultado no formato H,MM (Ex: 5 + 0.56 = 5.56) VAR _ResultadoFormatado = _Horas + (_MinutosProtheus / 100) -- 6. Aplica o sinal do resultado original RETURN IF( _SaldoTotalReais < 0, -_ResultadoFormatado, _ResultadoFormatado ) ```
```

**Total Credito GB**

```dax
``` VAR _TotalHorasReais = SUMX( FILTER('fBancodeHoras', 'fBancodeHoras'[PI_PD] = "010"), VAR _QuantOriginal = 'fBancodeHoras'[PI_QUANT] -- 1. Separa a parte inteira (horas cheias) VAR _HorasCheias = TRUNC(_QuantOriginal) -- 2. Separa a parte decimal (minutos no formato Protheus) VAR _MinutosDecimais = _QuantOriginal - _HorasCheias -- 3. Converte APENAS a parte decimal (minutos) para a base real (÷ 0.6) VAR _MinutosCorrigidos = _MinutosDecimais / 0.6 -- 4. Soma as horas corrigidas VAR _QuantidadeReal = _HorasCheias + _MinutosCorrigidos RETURN _QuantidadeReal ) -- 1. Calcula as horas inteiras VAR _Horas = TRUNC(ABS(_TotalHorasReais)) -- 2. Converte a parte decimal (minutos reais) para minutos inteiros do Protheus (Base 60) VAR _Minutos = ROUND((ABS(_TotalHorasReais) - _Horas) * 60, 0) -- 3. Combina o resultado no formato H,MM (ex: 50.30) VAR _ResultadoHMM = _Horas + (_Minutos / 100) -- 4. Retorna o valor final POSITIVO RETURN _ResultadoHMM ```
```

**Total Debito GB**

```dax
``` VAR _TotalHorasReais = SUMX( FILTER('fBancodeHoras', 'fBancodeHoras'[PI_PD] = "014"), VAR _QuantOriginal = 'fBancodeHoras'[PI_QUANT] -- 1. Separa a parte inteira (horas cheias) VAR _HorasCheias = TRUNC(_QuantOriginal) -- 2. Separa a parte decimal (minutos no formato Protheus) VAR _MinutosDecimais = _QuantOriginal - _HorasCheias -- 3. Converte APENAS a parte decimal (minutos) para a base real (÷ 0.6) VAR _MinutosCorrigidos = _MinutosDecimais / 0.6 -- 4. Soma as horas corrigidas VAR _QuantidadeReal = _HorasCheias + _MinutosCorrigidos RETURN _QuantidadeReal ) -- 1. Calcula as horas inteiras VAR _Horas = TRUNC(ABS(_TotalHorasReais)) -- 2. Converte a parte decimal (minutos reais) para minutos inteiros do Protheus (Base 60) VAR _Minutos = ROUND((ABS(_TotalHorasReais) - _Horas) * 60, 0) -- 3. Combina o resultado no formato H,MM (ex: 50.30) VAR _ResultadoHMM = _Horas + (_Minutos / 100) -- 4. Retorna o valor final POSITIVO RETURN _ResultadoHMM * -1 ```
```

**Ranqueamento Saldo BH**

```dax
``` RANKX( ALLSELECTED(dFuncionarios[NOME]), [Saldo BH], , DESC, DENSE ) ```
```

**Ranqueamento Saldo BH Neg**

```dax
``` RANKX( ALLSELECTED(dFuncionarios[NOME]), [Saldo BH], , ASC, DENSE ) ```
```

**Saldo de Horas Positivas**

```dax
SUMX( VALUES('fBancodeHoras'[CHAVEFILMAT]), -- Avalia o saldo de cada colaborador único VAR _Saldo = [Saldo BH] -- Usa sua medida final RETURN IF( _Saldo > 0, -- Se o saldo for maior que zero (horas devidas pela empresa) _Saldo,    -- Soma o saldo 0          -- Senão, soma zero ) )
```

**Saldo de Horas Negativas**

```dax
SUMX( VALUES('fBancodeHoras'[CHAVEFILMAT]), -- Avalia o saldo de cada colaborador único VAR _Saldo = [Saldo BH] -- Usa sua medida final RETURN IF( _Saldo < 0, -- Se o saldo for maior que zero (horas devidas pela empresa) _Saldo,    -- Soma o saldo 0          -- Senão, soma zero ) )
```

**Saldo HE**

```dax
``` SUMX( 'fHorasExtras', -- Itera sobre cada linha da tabela VAR _QuantOriginal = 'fHorasExtras'[QUANTC] -- 1. Separa a parte inteira (horas cheias) VAR _HorasCheias = TRUNC(_QuantOriginal) -- 2. Separa a parte decimal (minutos no formato Protheus) VAR _MinutosDecimais = _QuantOriginal - _HorasCheias -- 3. Converte APENAS a parte decimal (minutos) para a base real (÷ 0.6) VAR _MinutosCorrigidos = _MinutosDecimais / 0.6 -- 4. Retorna o valor real corrigido (Base 100) daquela linha RETURN _HorasCheias + _MinutosCorrigidos ) ```
```

**Vr Periculosidade**

```dax
``` SUMX( 'dFuncionarios', 'dFuncionarios'[SALARIO] * 'dFuncionarios'[PERICULOSIDADE] ) ```
```

**Vr Ad Dupla Funcao**

```dax
``` SUMX( 'dFuncionarios', 'dFuncionarios'[SALARIO] * 'dFuncionarios'[AD DUPLA FUNCAO] ) ```
```

**Vr Insalubridade**

```dax
``` SUMX( 'dFuncionarios', VAR _DataContexto = MIN(dCalendar[Data]) -- Use a coluna de data da sua tabela FATO -- 2. BUSCA O VALOR DO SALÁRIO MÍNIMO DAQUELE MÊS/DATA VAR _ValorSalarioMinimo = CALCULATE( MAX('dSalarioMinimo'[Valor]), -- Pega o valor (R$ 1518,00 no seu exemplo) FILTER( ALL('dSalarioMinimo'), -- Remove filtros de outras tabelas de Salário Mínimo 'dSalarioMinimo'[Mês] = _DataContexto ) ) -- 3. OBTÉM O PERCENTUAL DE INSALUBRIDADE DO FUNCIONÁRIO ATUAL VAR _PercentualInsalubridade = 'dFuncionarios'[INSALUBRIDADE] -- 4. CALCULA O ADICIONAL (Salário Mínimo * Percentual) RETURN _ValorSalarioMinimo * _PercentualInsalubridade ) ```
```

**Vr Salário**

```dax
``` SUMX( -- 1. ITERAÇÃO: Lista de CHAVEFILMATs visíveis. VALUES('fHistoricoSalarial'[CHAVEFILMAT]), -- 2. BLOCO DE CÁLCULO PARA CADA FUNCIONÁRIO -- Variáveis de Contexto (Mais limpas) VAR _DataContexto = MAX('dCalendar'[DATA]) -- CRÍTICO: Não precisamos do MIN/MAX aqui, o SUMX já nos deu a CHAVEFILMAT VAR _ChaveDaLinha = 'fHistoricoSalarial'[CHAVEFILMAT] RETURN CALCULATE( -- EXPRESSÃO: Pega o valor do salário MAX('fHistoricoSalarial'[SALÁRIO]), -- ARGUMENTOS DE FILTRO ALL('fHistoricoSalarial'), -- FILTRO CRÍTICO CORRIGIDO: Usa a chave da linha atual do SUMX 'fHistoricoSalarial'[CHAVEFILMAT] = _ChaveDaLinha, -- Filtro Temporal: Data de Início <= Data Contexto 'fHistoricoSalarial'[DATA_ALT] <= _DataContexto, -- Filtro Temporal: Data de Fim >= Data Contexto 'fHistoricoSalarial'[DATA_FIM] >= _DataContexto ) ) ```
```

**Vr Base HE**

```dax
[Vr Salário] + [Vr Periculosidade] + [Vr Insalubridade] + [Vr Ad Dupla Funcao]
```

**Hrs Jornada**

```dax
``` SUMX( -- 1. ITERAÇÃO TEMPORAL: Itera sobre cada mês (ou dia) do contexto de filtro atual -- Isso garante que o cartão some os resultados de todos os meses filtrados. VALUES('dCalendar'[MesAnoNome]), -- Use a coluna de granularidade mensal (ou a data completa se preferir) -- 2. BLOCO DE CÁLCULO ORIGINAL (adaptado para a iteração) VAR DataFimDoContexto = EOMONTH( MAX('dCalendar'[Data]), 0 ) -- Restante da lógica de filtro de vínculo e afastamento VAR FuncionariosComViculo = CALCULATETABLE( SUMMARIZE( 'dFuncionarios', 'dFuncionarios'[CHAVEFILMAT] ), 'dFuncionarios'[ADMISSAO] <= DataFimDoContexto, OR( ISBLANK('dFuncionarios'[DEMISSÃO]), 'dFuncionarios'[DEMISSÃO] > DataFimDoContexto ) ) VAR FuncionariosAfastadosNaData = CALCULATETABLE( SUMMARIZE( 'fControleAusencias', 'fControleAusencias'[CHAVEFILMAT] ), 'fControleAusencias'[R8_DATAINI] <= DataFimDoContexto, OR( ISBLANK('fControleAusencias'[R8_DATAFIM]), 'fControleAusencias'[R8_DATAFIM] >= DataFimDoContexto ), 'fControleAusencias'[R8_TIPOAFA] <> "001" ) VAR FuncionariosAtivos = EXCEPT( FuncionariosComViculo, FuncionariosAfastadosNaData ) RETURN -- 3. SOMA FINAL: Soma a HRJORNADA dos ativos do mês atual na iteração SUMX( FuncionariosAtivos, LOOKUPVALUE( 'dFuncionarios'[HRJORNADA], 'dFuncionarios'[CHAVEFILMAT], 'dFuncionarios'[CHAVEFILMAT] ) ) ) ```
```

**Vr Hora**

```dax
DIVIDE([Vr Base HE], [Hrs Jornada])
```

**Vr HE 100%**

```dax
[Vr Hora] * 2
```

**Vr Hora 50%**

```dax
[Vr Hora] * 1.5
```

**Valor Total HE por Verba**

```dax
``` SUMX( 'fHorasExtras', VAR _DescricaoHE = 'fHorasExtras'[Descricao] VAR _QuantidadeHE = 'fHorasExtras'[QUANTC] VAR _HorasCheias = TRUNC(_QuantidadeHE) VAR _MinutosDecimais = _QuantidadeHE - _HorasCheias VAR _QuantidadeReal = _HorasCheias + (_MinutosDecimais / 0.6) VAR _ValorCalculado = SWITCH( TRUE(), _DescricaoHE = "HE 50%" || _DescricaoHE = "HE COMPEN 50%", _QuantidadeReal * [Vr Hora 50%], _DescricaoHE = "HE DSR 100%" || _DescricaoHE = "HE FERIADO 100%", _QuantidadeReal * [Vr HE 100%], 0 ) RETURN _ValorCalculado ) ```
```

**Indice de Horas Extras**

```dax
DIVIDE([Saldo HE], [Hrs Jornada])
```

**Ranqueamento Saldo HE**

```dax
``` RANKX( ALLSELECTED(dFuncionarios[NOME]), [Saldo HE], , DESC, DENSE ) ```
```

**Ranqueamento Valor HE**

```dax
``` RANKX( ALLSELECTED(dFuncionarios[NOME]), [Valor Total HE por Verba], , DESC, DENSE ) ```
```

**Cor Condicional CC HE**

```dax
``` VAR ValorAtual = [Valor Total HE por Verba] RETURN SWITCH( TRUE(), ValorAtual > 40000, "#6B2328", ValorAtual > 20000, "#DE6A73", ValorAtual <= 20000, "#F0E199", "Gray" ) ```
```

**Cor Condicional SL CC HE**

```dax
``` VAR ValorAtual = [Saldo HE] RETURN SWITCH( TRUE(), ValorAtual > 1000, "#6B2328", ValorAtual > 400, "#DE6A73", ValorAtual <= 399.99, "#F0E199", "Gray" ) ```
```

**Média Vr/Hora**

```dax
DIVIDE([Valor Total HE por Verba], [Saldo HE])
```
