# Arquitetura — Plataforma Analítica Alles

> Documento de referência da reconstrução do Data Warehouse da Alles Alimentos
> e das dashboards do **Oryon Board**.
> Versão 1.5 — 21/08/2026. Substitui o `docs/roadmap.md` original.

---

## 1. Objetivo

Substituir a base analítica atual — DW em Excel/Power Query alimentando dashboards
no Power BI — por uma plataforma de dados própria, em camadas, servindo dashboards
de **todas as áreas de negócio** dentro do **Oryon Board**, com controle de alçada
por usuário.

Não é uma migração de ferramenta. É a mudança do lugar onde a regra de negócio mora:
hoje ela está espalhada entre queries SQL, passos de Power Query, medidas DAX e
planilhas manuais em rede. No modelo alvo ela vive em um único lugar versionado.

### Princípios

1. **Uma fonte de verdade por métrica.** Se "faturamento líquido" existe em dois
   lugares, um deles está errado e ninguém sabe qual.
2. **Cada camada tem uma responsabilidade só.** Bronze não decide nada. Prata não
   agrega. Ouro não limpa.
3. **Regra de negócio é código versionado**, com autor, data e motivo — nunca um
   filtro solto dentro de uma query.
4. **Fidelidade ao passado é ponto de partida, não destino.** Reproduzimos os
   números atuais para validar a migração; onde a planilha estava errada, corrigimos
   de forma explícita e documentada.
5. **Uma ferramenta nova por vez.** Cada fase termina com algo funcionando.

---

## 2. Decisões arquiteturais

| # | Decisão | Escolha | Por quê | Alternativa descartada |
|---|---------|---------|---------|------------------------|
| 1 | Banco do DW | PostgreSQL 16 | Já em uso, maduro, suporta bem carga intradiária e leitura concorrente pela API; particionamento por data nos fatos grandes | ClickHouse (peso operacional), DuckDB (ruim para escrita concorrente + API multiusuário) |
| 2 | Camadas | bronze → prata → ouro | Separa pouso, conformação e modelagem; torna auditável a origem de cada número | raw → dw (modelo atual, mistura limpeza e modelagem) |
| 3 | Transformação | **dbt (dbt-postgres)** | Linhagem, testes de chave/not-null, modelos incrementais, documentação gerada | SQL puro numerado (sem testes nem linhagem) |
| 4 | Ingestão | **Extrator Python próprio**, incremental por watermark + janela móvel + MERGE | Controle total e depuração direta quando uma NF não bater | dlt (abstração a mais para o problema atual) |
| 5 | Orquestração | **cron/systemd timers** com tabela de controle de execuções | Sobe em um dia, suficiente para o volume atual; Dagster entra quando a complexidade justificar | Dagster desde o início (peso operacional prematuro) |
| 6 | Fontes manuais | **Versionadas no git** (seeds dbt), migrando para tela de manutenção no Oryon quando esta for implantada | Rastreabilidade imediata e custo zero; a tela vem sem retrabalho | Continuar no `fManual.xlsx` em `P:\` |
| 7 | Camada semântica | Marts no ouro, um por dashboard; API fina | Mantém a regra em SQL versionado e o backend burro; permite aplicar alçada no `WHERE` | Métricas calculadas no backend ou no frontend |
| 8 | Produção | VM Linux on-premises, já existente e sob administração interna | Dados fiscais internos, custo previsível, latência baixa até o Protheus | Cloud gerenciada |
| 9 | Versionamento | Git + repositório remoto privado, desde o primeiro commit | Pré-requisito de qualquer coisa definitiva | Pasta local sem histórico (situação atual) |
| 10 | Histórico | Todo o disponível no Protheus — que **começa em 01/02/2025**, data de entrada do ERP. O histórico anterior existe apenas no legado **DATAVALE** | O corte `> '20250131'` não era sedimento: é o limite físico dos dados | Ignorar o histórico pré-Protheus (perderia a base de comparação plurianual) |
| 11 | Alçada | Dois níveis: permissão de módulo (já existe no Oryon) + filtro por linha injetado pelo FastAPI no `WHERE` | Uma só tecnologia, fácil de testar e depurar | RLS no Postgres (mais à prova de falhas, porém amarra a alçada ao banco e dificulta o debug) |
| 12 | Critério de migração | **Zero divergência inexplicada** contra o Power BI | Toda diferença precisa de causa identificada — e aí se decide qual lado está certo. Revela erros da planilha em vez de escondê-los | Bater ao centavo (perpetua gambiarras no DW novo); tolerância percentual (mascara erro sistemático) |
| 13 | Origens | Protheus (ERP) **e o banco operacional do próprio Oryon** (módulo MKT) | Marketing não tem origem no ERP; suas demandas operacionais nascem no Oryon | Conectores de mídia paga / CRM externo (sem fonte estruturada hoje) |

---

## 3. Arquitetura alvo

```
┌──────────────┐   extrator Python      ┌──────────────────────────────────────┐
│   PROTHEUS   │   (watermark + MERGE)  │        POSTGRES — DW (VM Linux)      │
│  SQL Server  │ ─────────────────────► │                                      │
│  (produção)  │                        │  bronze  pouso fiel, imutável        │
└──────────────┘                        │     ↓    dbt                         │
┌──────────────┐   extrator Python      │  prata   conformado, deduplicado     │
│  ORYON MKT   │ ─────────────────────► │     ↓    dbt                         │
│  (operação)  │                        │  ouro    modelo estrela + marts      │
└──────────────┘                        │                                      │
┌──────────────┐   seeds dbt (git)      │                                      │
│ fontes       │ ─────────────────────► │                                      │
│ manuais      │                        │                                      │
└──────────────┘                        └───────────────┬──────────────────────┘
                                                        │ somente leitura
                                                        ▼
                                        ┌──────────────────────────────────────┐
                                        │   ORYON — FastAPI (backend)          │
                                        │   autentica → aplica alçada → serve  │
                                        └───────────────┬──────────────────────┘
                                                        ▼
                                        ┌──────────────────────────────────────┐
                                        │   ORYON BOARD — dashboards por área   │
                                        └──────────────────────────────────────┘
```

### O que cada camada pode e não pode fazer

**Bronze — o pouso.**
Cópia fiel do que o Protheus devolveu, sem nenhuma regra de negócio. Sem filtro de
CFOP, sem exclusão de NF, sem conversão de unidade, sem TRIM. Todo campo texto entra
como texto. Cada linha carrega `_carregado_em` e `_lote_id`. Se amanhã descobrirmos
que uma regra estava errada, o bronze permite reprocessar sem reler o Protheus.

**Prata — a conformação.**
Aqui acontece o trabalho técnico: TRIM nos campos CHAR de largura fixa do Protheus,
casts de data (incluindo as sentinelas `1900-01-01` → NULL e os textos `DD-MM-YYYY`
do `CONVERT 105`), montagem das chaves de negócio (`chave_cliente = cod || loja`),
deduplicação, normalização de códigos. A prata **não decide o que é faturamento** —
ela apenas entrega dados limpos e tipados. Também é onde as regras de negócio
explícitas se aplicam: filtro de CFOP, exclusões de NF (via tabela versionada),
conversão caixa→quilo.

**Ouro — o modelo.**
Modelo estrela por domínio (fatos e dimensões conformadas) mais os **marts**: uma
view ou tabela por dashboard do Oryon Board, já no grão e com as métricas que aquela
tela precisa. Dimensões são **conformadas** — existe uma `dim_cliente` só, usada pelo
comercial, pelo financeiro e pela logística, não uma por área.

---

## 4. Convenções

- Schemas: `bronze`, `prata`, `ouro`. Nomes de objeto em minúsculo com `_`.
- Prefixos no ouro: `dim_`, `fato_`, `mart_`.
- Datas em `DATE`, dinheiro em `NUMERIC(18,2)`, quantidade em `NUMERIC(18,3)`,
  percentual em `NUMERIC(9,4)` — nunca `FLOAT` para valor monetário.
- Chaves substitutas (`sk_`) nos fatos; chaves de negócio preservadas e com
  restrição `UNIQUE` para permitir o MERGE idempotente.
- Toda tabela do bronze e do ouro tem `_carregado_em`; toda carga registra em
  `ouro.controle_cargas` (domínio, início, fim, linhas, status, erro).
- Sem acento e sem espaço em nome de objeto. Documentação e descrições em português.

---

## 5. Ingestão incremental

O modelo atual reescreve a tabela inteira a cada execução (`if_exists="replace"`),
o que é incompatível com atualização várias vezes ao dia. O padrão alvo:

**Fatos (alto volume, mutáveis):**
1. Lê o watermark do domínio em `ouro.controle_cargas` (última data processada).
2. Extrai do Protheus a partir de `watermark − janela_movel` (padrão: 45 dias) —
   a janela existe porque NF é cancelada, corrigida e lançada retroativamente.
3. Grava em tabela de staging e faz `MERGE` no bronze pela chave de negócio
   (`filial + nfe + serie + item`).
4. Marca como deletadas as linhas que sumiram da janela (cancelamentos).
5. Atualiza o watermark.

**Dimensões (baixo volume):** carga full a cada execução — mais simples e barata que
qualquer lógica incremental. `SA1` (clientes), `SB1` (produtos), `SA3` (vendedores)
custam segundos.

**Carga inicial:** como o histórico completo será carregado, a primeira execução é
por lotes anuais, fora do horário comercial, com o watermark avançando a cada lote.

---

## 6. Dívidas do modelo atual e como serão tratadas

| Dívida | Situação hoje | Tratamento |
|--------|---------------|------------|
| Exclusões de NF hardcoded | 38 números de NF listados dentro do `WHERE` da query de faturamento, "para bater com a planilha" | Saem do SQL. Viram `prata.excecoes_nf` (seed versionado) com número, filial, motivo e data. Cada exclusão precisa de justificativa — as que não tiverem, revisamos |
| Filtro `D2_EMISSAO > '20250131'` | Limita o DW ao que a planilha cobria | Removido. Histórico completo no bronze; recortes ficam nas dashboards |
| Cliente `97316293` excluído | Hardcoded na query | Vira exceção documentada em `prata.excecoes_cliente` |
| Conversão -CX duplicada | Centralizada em `map_produto_cx` só no faturamento; nos fatos extras (bonificação, remessas, coopeval, acordo) a lista de fatores está repetida dentro de cada query | Uma única macro dbt lendo o seed `map_produto_cx`, aplicada em todos os fatos |
| Fontes manuais em rede | `fManual.xlsx` e `dCalendario.xlsx` em `P:\T.I\01. BASES` | Seeds versionados no git; calendário passa a ser gerado por código (ano fiscal Abr–Mar, dias úteis, feriados). Depois, tela de manutenção no Oryon |
| Sem git | Pasta local sem histórico | Repositório inicializado no primeiro commit da fundação |
| Sem testes | Nenhuma validação automática | Testes dbt: unicidade de chave, not-null nas FKs, relacionamento fato→dimensão, e um teste de reconciliação contra o total conhecido |
| Órfãos silenciosos | Fato grava `NULL` quando o cliente não existe na dimensão — a receita é preservada, mas o problema fica invisível | Membro "não identificado" explícito nas dimensões + teste que falha quando os órfãos passam de um limiar |

---

## 7. Consumo pelo Oryon Board

O Oryon é a plataforma SaaS própria, com autenticação e permissionamento já
funcionais. O Oryon Board é o módulo de BI. O backend FastAPI lê **exclusivamente
da camada ouro** — nunca do Protheus, nunca da prata.

Padrão por dashboard:
1. Um mart no ouro, no grão da tela, com as métricas já calculadas.
2. Um endpoint FastAPI que recebe filtros, aplica o predicado de alçada do usuário
   e devolve JSON.
3. A tela no Oryon Board.

### Alçada em dois níveis

**Nível 1 — acesso ao módulo.** Já existe no Oryon: define quais dashboards o usuário
consegue abrir.

**Nível 2 — filtro por linha.** O FastAPI resolve o escopo do usuário autenticado
(representante vê a própria carteira, gestor vê a equipe, diretoria vê tudo) e injeta
o predicado correspondente no `WHERE` de toda consulta ao ouro. O filtro é aplicado no
backend, não no banco.

A consequência prática: **nenhuma rota pode montar SQL sem passar pela função que
aplica o escopo.** Isso precisa ser uma camada obrigatória do backend — um repositório
ou dependency injection que já recebe o predicado pronto —, nunca um `WHERE` que cada
endpoint lembra de escrever. Uma rota que esqueça o filtro vaza dados sem erro visível.
Descartamos RLS no Postgres, que seria imune a esse esquecimento, em troca de debug
mais simples e de uma tecnologia só; o preço é essa disciplina no código.

---

## 8. Roadmap

**O DW inteiro — bronze, prata e ouro de todos os domínios — é construído antes de
qualquer dashboard.** As telas do Oryon Board vêm depois, sobre um modelo completo e já
reconciliado. O inventário dos `.pbix` deixa de ser pré-requisito e vira tarefa
paralela.

Construção **por domínio, um de cada vez**: cada um percorre o trilho inteiro antes de o
próximo começar. Assim um erro de método aparece no primeiro domínio, não no nono.

### Os nove domínios

Definidos em 21/08/2026, a partir do inventário do DW legado (cap. 9). O recorte segue
o tamanho e o entrelaçamento reais de cada assunto, não o organograma.

| # | Domínio | Origem legada | Por que é um domínio |
|---|---------|---------------|----------------------|
| 1 | **Comercial** | `fFaturamento`, `PEDIDOSDEVENDACONSOLIDADO`, `fComissao` | Faturamento, pedidos e comissão respondem à mesma pergunta: o que foi vendido e por quem |
| 2 | **Financeiro** | `fFinanceiro` | 61 consultas — o maior conjunto de regras do DW atual |
| 3 | **Fiscal** | `fFiscal` | 156 MB e 19 tabelas próprias; apêndice do Financeiro seria subestimá-lo |
| 4 | **Industrial** | `APONTAMENTODEPRODUCAO` | Ordens, apontamentos, reprocessos — `SC2`, `SD3`, `SG2`, `SH6` |
| 5 | **Custo** | `fCusto` | Entrelaça Industrial (`SC2`/`SD3`) e Frete (`GW*`); construído logo após o Industrial, que lhe dá base |
| 6 | **Compras** | `fCompras` | Pedidos, entradas, saldo físico, histórico de preço |
| 7 | **Logística** | `fFretes` + `fLogistica` | Unificados: compartilham as mesmas tabelas de TMS (`GU3`, `GW1`, `GW3`, `GW4`) |
| 8 | **Gestão de Pessoas** | `fGestaoPessoas`, `MOTIVORESCISAO` | Protheus RH — 14 tabelas, folha, ponto, banco de horas |
| 9 | **Marketing** | Oryon MKT | Única origem fora do ERP |

### Passo de descoberta (abre todo domínio novo)

O inventário do capítulo 9 **substituiu** a descoberta por dicionário para os domínios
já cobertos pelo DW legado: o código Power Query extraído já diz quais tabelas, filtros
e joins a Alles usa. O passo agora é:

1. Ler o `.m` correspondente em `docs/legado_m/` — a especificação de fato.
2. Confrontar com o dicionário do Protheus (`SX2`/`SX3`) apenas para campos
   customizados (`_X_`) cujo significado o M não explique.
3. Validar as regras encontradas com o responsável da área — sobretudo as que parecem
   sedimento (cortes de data, exclusões pontuais) e não decisão.

### Fases

**Fase 1 — Fundação** *(primeira entrega)*
Git inicializado; estrutura bronze/prata/ouro; projeto dbt configurado; extrator
incremental funcionando para o domínio comercial; `controle_cargas` operante.
Detalhada em `docs/fase1_fundacao.md`.
Meta: `dbt build` verde e bronze do comercial populado com histórico completo.

**Fase 2 — Comercial completo (bronze → ouro)**
Modelo estrela do comercial — faturamento, devoluções, bonificação, refaturamento,
remessas, acordo comercial, pedidos e comissão — com dimensões conformadas e as dívidas
do capítulo 6 resolvidas. Meta: **zero divergência inexplicada** contra a planilha
`fFaturamento`, com cada diferença registrada em `docs/reconciliacao_comercial.md`.

**Fase 3 — Orquestração intradiária**
Timers systemd, log de execução, alerta em falha. Meta: DW atualizado várias vezes ao
dia sem intervenção, por sete dias seguidos.

**Fases 4 a 11 — Os demais domínios, um por ciclo**
Financeiro → Fiscal → Industrial → Custo → Compras → Logística → Gestão de Pessoas →
Marketing. Cada um percorre descoberta → bronze → prata → ouro, com reconciliação
contra o workbook legado correspondente.

A ordem não é arbitrária. Comercial, Financeiro e Fiscal fecham o ciclo do que é
vendido, recebido e declarado. Industrial e Custo abrem o do que é produzido e a que
preço — e juntos com o Comercial habilitam **margem apurada contra custo real**. Hoje o
Power BI já calcula margem, mas de forma **paramétrica**: `-(1 - Mk-UP - %COMISS - GGF -
ICMS - PIS - COFINS - Fin)`, com custo vindo da média de uma tabela de preços. Compras e
Logística completam a cadeia. Gestão de Pessoas e Marketing, menos entrelaçados com os
demais, fecham a fila.

**Fase 12 — Dashboards no Oryon Board**
Com o DW completo: inventário dos `.pbip` (se ainda não tiver sido feito em paralelo),
marts por tela, endpoints FastAPI com alçada e as telas do Board. Domínio por domínio,
na mesma ordem em que o DW foi construído.

**Fase 13 — Desligamento do legado**

**Regra que vale desde já: nada do que está rodando é alterado.** O
`atualizador_1.9.xlsm`, os workbooks de `P:\T.I\01. BASES`, os sete relatórios do
Power BI e os seis pipelines de relatório seguem intocados durante todo o projeto. O DW
novo nasce ao lado, não por cima. Enquanto um domínio não estiver substituído no Board,
**o legado continua sendo a referência oficial daquele número.**

Só quando o Board cobrir um domínio é que o consumidor legado correspondente pode ser
desativado — desativar no fim é diferente de alterar no meio. Esta fase é o encerramento
ordenado do DW antigo, não uma migração de seus componentes.

---

## 9. Fontes de conhecimento das regras

Duas auditorias mapearam onde as regras de negócio da empresa realmente vivem.

### 9.1 O DW legado em Excel (21/08/2026)

**Inventário completo em `docs/inventario_dw_legado.md`.** O código Power Query dos 22
workbooks de `P:\T.I\01. BASES` foi extraído para `docs/legado_m/*.m` pelo script
`docs/legado_m/extrair_m.py`: **272 consultas, 70 tabelas do Protheus, ~600 MB de
planilha**. É a especificação de fato de todos os domínios — não uma hipótese.

Isso corrigiu a premissa anterior de que as áreas fora do comercial não teriam nada
mapeado. Elas têm, e o mapa está no capítulo 10.

Achados que impactam a construção: duas janelas de data convivendo dentro do próprio
`fFaturamento` (`D2_EMISSAO > '20250131'` e `> '20250430'`); a string de conexão do
Protheus repetida nos 22 workbooks; toda carga diária falhando na segunda tentativa
antes de passar; e `SB1010` sendo lido por doze workbooks diferentes — doze definições
possíveis de "produto".

### 9.2 Os modelos do Power BI (21/08/2026)

**Backlog completo em `docs/backlog_paridade.md`.** Os sete projetos `.pbip` foram
extraídos em TMDL para `docs/pbip_extraido/`: **304 tabelas, 3.318 colunas, 484 medidas
DAX, 281 relacionamentos, 50 páginas** nos relatórios Comercial, Venda Real, Produção,
Gestão de Pessoas, Gestão de Abastecimento, Média de Matéria Prima e Pedidos de Venda.

Isso fecha o mapa: o Excel diz de onde os dados vêm, o Power BI diz o que a empresa mede
com eles. E confirma a cadeia completa — **Protheus → Excel (`P:\T.I\01. BASES`) →
Power BI**: os modelos leem os workbooks inventariados no capítulo 9.1, não o ERP.

Dois achados com efeito direto no desenho:

**Nenhum dos sete modelos define RLS.** A alçada por linha **não existe hoje** — quando
o Oryon Board a aplicar, será capacidade nova, não migração. Quem hoje enxerga tudo
passará a enxergar menos, e isso precisa ser combinado antes.

**`Comercial` e `Venda Real` medem a mesma coisa de dois jeitos**, sobre fatos
diferentes (`fFaturamentoConsolidado` e `fFaturamento`). Pior: dentro de `Venda Real`,
`Venda Real Liquida` subtrai devolução e `VENDA REAL` não — duas medidas quase homônimas
com resultados distintos. É a terceira instância do mesmo problema estrutural, depois da
planilha versus relatórios e das seis cópias de `faturamento.sql`.

### 9.3 Os seis pipelines de relatório (20/08/2026)

Seis repositórios de relatórios em produção foram inspecionados. O que eles contêm:

### O que ganhamos

**Um dicionário de dados da Alles já validado.** O `CLAUDE.md` do
`relatorio-clevel-protheus-semanal` documenta, tabela por tabela, os campos realmente
em uso (`SD2010`, `SF2010`, `SC5010`, `SA1010`, `SA3010`, `SD1010`, `SF1010`,
`SB1010`), os CFOPs de venda **e de devolução**, os fatores de conversão -CX, os joins
de referência e a regra de que faturamento bruto = `D2_TOTAL + D2_DESCZFR`. Isso reduz
drasticamente o passo de descoberta do comercial.

**Regras analíticas já codificadas em SQL**, prontas para virar marts do ouro:
curva ABC, cross-sell de famílias, Pareto 80/20, RFV, inativos e perdidos, recorrência
de não-positivação, âncoras por representante, análise por estado, variação de
faturamento.

**Uma fonte de dados que o modelo atual ignora: as metas.** O arquivo
`METASDEVENDASBI2026.xlsx` alimenta o farol diário e o relatório semanal. Meta versus
realizado é o centro de qualquer dashboard comercial e **não existe** no modelo do
`alles-dataplatform`. Precisa entrar como fato ou dimensão própria no ouro.

### O que isso revelou de problema

**Existem hoje duas definições de faturamento rodando em produção.** Os relatórios
que vão para a diretoria usam `D_E_L_E_T_ = ''`; o `alles-dataplatform` usa
`D_E_L_E_T_ <> '*'`. Mais grave: os relatórios **não aplicam** a lista de 38 NFs
excluídas nem o recorte de data que a planilha `fFaturamento` aplica. Ou seja, o número
que a diretoria recebe e o número da planilha não são o mesmo número — e é provável que
ninguém saiba disso. Resolver essa divergência é pré-requisito da Fase 2: não dá para
reconciliar contra duas referências que discordam entre si.

**Nenhuma das seis áreas novas tem cobertura.** Todos os seis repositórios são
comerciais. Para Financeiro, Industrial, Compras, Logística e RH não há nenhuma query,
nenhum mapeamento e nenhuma regra escrita — o passo de descoberta do capítulo 8 é a
única via.

**A mesma query, copiada seis vezes.** Cada repositório tem sua própria versão de
`faturamento.sql`, `clientes.sql`, `produtos.sql`. Já divergem entre si. É exatamente o
problema que o DW existe para acabar — ver Fase 11.

---

### 9.4 Definições de negócio fechadas (21/08/2026)

**Referência do faturamento: o modelo `Venda Real`.** É a base do `fato_faturamento`.
O modelo `Comercial` não é descartado — ele carrega duas coisas que o `Venda Real` não
tem, e ambas migram como componentes próprios:

- **Histórico DATAVALE** (ERP anterior ao Protheus). Vive na aba `fFaturamentoDataVale`
  do `fManual.xlsx` e chega ao modelo por um dataflow. **Problema sério: as doze colunas
  não têm nome** — são literalmente `Coluna 1` a `Coluna 12`. O significado de cada uma
  existe apenas na cabeça de quem montou a tabela. Enquanto isso não for documentado, o
  histórico pré-Protheus é inutilizável. Depois de documentado, precisa de um **de-para
  Datavale × Protheus** para produto, cliente e vendedor, sem o qual as séries não se
  ligam.
- **Metas de venda.** Migram como fato próprio, e o Lucas quer **redesenhar a regra de
  controle e a lógica de visualização** — ou seja, não é migração fiel: é uma
  oportunidade de corrigir o modelo de metas. A nova regra ainda será definida.

**Janela do Protheus.** O corte `> '20250131'` não era sedimento: **01/02/2025 é a data
de entrada do ERP**. O bronze traz tudo o que existir; o que houver antes disso é
resíduo de migração e não deve ser tratado como faturamento.

**As 38 NFs excluídas permanecem fora**, agora numa tabela auxiliar versionada
(`prata.excecoes_nf`), com número, filial e motivo — em vez de literais dentro do SQL.

**Margem e Marketing ficam para um segundo momento.** A margem custeada aguarda
definição de negócio; o Marketing já tem um board com perguntas definidas dentro do
módulo Oryon MKT, que servirá de especificação quando chegar a vez.

**Uma camada a mais que não estava mapeada.** Dos 304 objetos dos modelos, **58 vêm de
dataflows do Power BI** (`Fluxo*`), não direto dos workbooks. A cadeia real é, para
essas tabelas, **Protheus → Excel → dataflow → modelo** — quatro saltos, cada um um
lugar onde a regra pode ter sido alterada sem registro.

---

## 10. Mapa de origens no Protheus

Confirmado pelo inventário do capítulo 9 — são as tabelas efetivamente consultadas em
produção hoje, não hipótese.

| Domínio | Tabelas | Origem legada |
|---------|---------|---------------|
| Comercial | `SD2` `SF2` `SD1` `SF1` `SC5` `SC6` `SC9` `SE4` `SA1` `SA3` `SB1` `SE1` `SE5` `DAK` | `fFaturamento`, `PEDIDOSDEVENDACONSOLIDADO`, `fComissao` |
| Financeiro | `SE1` `SE2` `SE5` `SED` `SEV` `CT1` `CTT` `CQ0` `FK5` `FK7` `FRV` `SA6` `SIG` `SX5` | `fFinanceiro` |
| Fiscal | `SFT` `SDT` `SDS` `SF1` `SF2` `SD1` `SD2` `SE2` `SED` `SCR` `SAK` `AC9` `SC7` `SBM` `CTT` | `fFiscal` |
| Industrial | `SC2` `SD3` `SG2` `SH6` `SB1` | `APONTAMENTODEPRODUCAO` |
| Custo | `SB9` `SC2` `SD3` `SD1` `SF1` `CTT` `GU3` `GW1` `GW3` `GW4` `GWM` `SA2` `SB1` | `fCusto` |
| Compras | `SC1` `SC7` `SD1` `SF1` `SB2` `SA1` `SA2` `SE4` | `fCompras`, `dCompras` |
| Logística | `GU3` `GW1` `GW3` `GW4` `GWM` `GWD` `GWL` `GXG` `SF4` `SB2` `AC9` `SD2` `SF2` `SE2` | `fFretes`, `fLogistica`, `dSaldoAtual` |
| Gestão de Pessoas | `SRA` `SRC` `SRD` `SRG` `SRV` `SR3` `SR8` `SP8` `SPC` `SPH` `SPI` `SPK` `RCC` `RG1` | `fGestaoPessoas`, `MOTIVORESCISAO` |
| Marketing | — | Banco do Oryon (módulo MKT) |

### Fontes que não vêm do ERP

| Fonte | Onde está hoje | Destino |
|-------|----------------|---------|
| Família, marca, sub-recorte, região, destino, motivo de devolução, grupos e contas | `fManual.xlsx` | Seeds no git → tela de manutenção no Oryon |
| Metas de venda | `METASDEVENDASBI2026.xlsx` | Fato próprio no ouro; meta versus realizado |
| Calendário (ano fiscal Abr–Mar, dias úteis, feriados) | `dCalendario.xlsx` | Gerado por código (T8 da Fase 1) |

---

## 11. Questões em aberto

Sete questões foram fechadas em 21/08/2026 (ver cap. 9.4). Restam:

1. **`VENDA REAL` deveria subtrair devolução?** Dentro do modelo eleito como referência,
   `Venda Real Liquida` subtrai e `VENDA REAL` não. Uma das duas está errada, e a
   definitiva precisa ser escolhida antes de virar `fato_faturamento`.
2. **Quem documenta as doze colunas do DATAVALE?** Sem isso o histórico pré-Protheus
   não entra no DW. É trabalho de arqueologia, não de engenharia — depende de alguém que
   se lembre.
3. **Qual a nova regra de metas?** Você quer redesenhar controle e visualização; o
   modelo do ouro depende dessa definição.
4. **O que alimenta os dataflows do Power BI?** 58 tabelas passam por eles. Se houver
   transformação lá dentro, ela é regra de negócio não inventariada.
5. **Escopo de Marketing** — o board do Oryon MKT já tem as perguntas; falta traduzi-las
   em modelo quando o domínio chegar.
6. **Margem custeada** — aguarda definição de negócio.

### Riscos conhecidos

- **Carga inicial do histórico completo.** Ler todo o `SD2` do Protheus de produção é
  a operação mais pesada do projeto. Fazer por lotes anuais, fora do horário
  comercial, medindo o impacto no ERP antes de seguir para o lote seguinte.
- **A alçada no backend depende de disciplina.** Ver capítulo 7: uma rota que monte
  SQL sem passar pela camada de escopo vaza dados silenciosamente. Mitigação: teste
  automatizado que percorre as rotas do Board e falha se alguma consultar o ouro sem
  o predicado.
- **Divergências que não fecham.** É provável que parte das 38 NFs excluídas e do
  filtro de CFOP não tenha justificativa documentada. O critério de zero divergência
  inexplicada vai expor isso — e o tempo de investigação precisa estar no plano, não
  ser tratado como imprevisto.
- **O DW legado pode quebrar durante a migração.** Um workbook de 191 MB e outro de
  156 MB, com toda carga já dependendo de retry para passar, são estrutura em fadiga.
  Se o `atualizador` parar antes de o novo DW cobrir aquele domínio, a empresa fica
  sem o número. Isso empurra a favor de acelerar Financeiro e Fiscal, os dois maiores.
- **Nove domínios é um projeto longo.** O risco não é técnico, é de fôlego: entregar
  valor visível apenas na Fase 12 é muito tempo sem retorno percebido.
  Repontar os relatórios existentes para o ouro foi considerado e **descartado**: a
  decisão é reconstruí-los direto no Board. Isso mantém o legado intocado, mas devolve o
  risco de fôlego por inteiro. **Mitigação recomendada:** antecipar a primeira tela do
  Board para o Comercial logo após a Fase 3, fora da ordem, como prova de valor — e usar
  o relatório legado equivalente, ainda rodando, como referência de reconciliação lado a
  lado. Decisão a tomar quando a Fase 3 fechar.
