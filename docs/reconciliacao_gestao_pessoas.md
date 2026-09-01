# Reconciliação — Gestão de Pessoas (Fase 10)

> Meta (arquitetura.md): zero divergência inexplicada contra a query legada
> de cada fato. Cada diferença encontrada abaixo foi investigada até a causa
> raiz — nenhuma foi ignorada ou arredondada.

`fGestaoPessoas.m` é o maior workbook do legado por tamanho (191 MB), mas o
`.m` em si é enxuto (214 linhas) — o peso é volume de dado (ponto, folha),
não regra de negócio. A maioria das consultas é `SELECT *` puro contra uma
única tabela, sem join, sem filtro além do `D_E_L_E_T_`: já completamente
servidas pelo bronze, sem precisar de modelo prata/ouro (ver seção
dedicada abaixo).

## Resultado (01/09/2026)

| Fato | Legado (ao vivo) | Novo (`prata_ouro`) | Diferença |
|---|---:|---:|---:|
| `fato_motivo_rescisao` | 494 | 494 | 0 |
| `fato_dupla_funcao` | 12 | 12 | 0 |
| `fato_historico_salarial` | 1.968¹ | 2.455 | +487¹ |

¹ Diferença deliberada — ver achado abaixo. Sem o corte de data do legado,
os dois lados também batem exatamente (2.455 = 2.455, confirmado
reexecutando a consulta legada sem a condição `R3_DATA > '20231201'`).

**Divergência final: zero.**

## Achado: `MOTIVORESCISAO.m` supera `fMotivoRescisão` do próprio `fGestaoPessoas.m`

Os dois arquivos têm uma consulta de motivo de rescisão quase idêntica —
`fMotivoRescisão` (`fGestaoPessoas.m`) é um subconjunto estrito de
`MOTIVORESCISAO` (join a menos, sem o valor pago). Construído aqui como
`fato_motivo_rescisao`, replicando a versão completa; a mais simples não
tem uso próprio que a completa não cubra.

## Achado: corte de data no histórico salarial não é regra de negócio

`sqlHistoricoSalarial` filtra `R3_DATA > '20231201'` — mais de um ano
antes da entrada do Protheus (01/02/2025) usada como referência em todo o
resto do projeto. Não há nenhuma razão de negócio visível para esse corte
específico; tem cara de "desde quando comecei a acompanhar isso".
`fato_historico_salarial` mirra o histórico completo do `SR3010`
(2.455 linhas, contra 1.968 do legado) — mesma lógica já aplicada ao
corte `GWM_DTEMIS > 20260416` na Fase 9.

## Achado: maioria das consultas do domínio não tem regra de negócio nenhuma

Das 12 consultas de `fGestaoPessoas.m`, 8 são `SELECT * FROM <tabela>
WHERE D_E_L_E_T_ = ''` — sem join, sem filtro adicional, sem cálculo:

| Consulta legada | Tabela | Linhas (bronze) |
|---|---|---:|
| `fMovimentosPeriodicos` | SRC010 | 13.276 |
| `fMovimentosHistorico` | SRD010 | 413.082 |
| `fMarcações` | SP8010 | 27.463 |
| `fControleAusencias` | SR8010 | 2.440 |
| `fApontamentos` | SPC010 | 30.762 |
| `fBancodeHoras` | SPI010 | 75.898 |
| `fEventosAbonados` | SPK010 | 13.500 |
| `fApontamentosHist` | SPH010 | 502.007 |

Essas 8 tabelas foram carregadas no bronze (fazem parte do domínio, citado
em arquitetura.md como "folha, ponto, banco de horas") mas **não ganharam
modelo prata/ouro dedicado** — o princípio deste projeto é que a prata
existe pra aplicar regra de negócio explícita, e não há regra nenhuma pra
aplicar aqui além do que o bronze já garante (mirror fiel, `_deletado`
rastreado). Construir uma "view espelho" em prata só pra existir seria
abstração sem propósito. Quem precisar desses dados para uma pergunta
específica de folha/ponto consulta o bronze diretamente ou pede um modelo
novo quando a pergunta aparecer.

## Modelos construídos com regra real

- `dim_funcionario` (SRA010) — inclui conversão de periculosidade/
  insalubridade de texto (`'0.30'`) pra numérico (`0.30`), já que são
  percentuais calculáveis, não rótulos.
- `dim_verba` (SRV010) — só identificação (código/descrição/tipo); a
  tabela tem 126 colunas de parametrização de cálculo de folha sem uso
  analítico direto.
- `fato_motivo_rescisao`, `fato_dupla_funcao`, `fato_historico_salarial`
  — únicas consultas do domínio com join, filtro de negócio ou cálculo
  reais.
