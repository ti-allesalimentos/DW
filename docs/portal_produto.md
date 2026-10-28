# Portal Alles — documento de produto (v0.1)

> Complementa `docs/portal_externo.md` (arquitetura). Decisões de 28/10/2026.
> Catálogo de trabalho: `portal_catalogo_recursos_v3.xlsx` (recursos, telas e KPIs por área).

## 1. Decisões tomadas

| # | Decisão |
|---|---|
| 1 | **Portal separado do Oryon**, em VM própria (DMZ), login pelo Microsoft Entra |
| 2 | **Fase 1 = portal interno** (dashboards já construídas e as de dado pronto). Representantes, clientes e fornecedores vêm depois |
| 3 | **Sem BI de autoatendimento:** os usuários consomem painéis prontos e **exportam** o que precisam (Excel, CSV, PDF) |
| 4 | **Áreas:** Comercial, Compras, Financeiro, Fiscal/Contábil, Logística, Produção, Estoque, RH/DP, Administração e **Marketing** |
| 5 | **Logística em espera:** o novo controle de frete no Oryon pode ser a fonte mais segura |
| 6 | **Preço de tabela (C11):** usa a **DA1 do Protheus** por ora. O Excel "Gestão de Preços" é diferente e fica para avaliar depois |
| 7 | **Estoque mínimo e ponto de pedido:** fora até o Lucas validar a fonte confiável |
| 8 | **Mapa de vendas por UF:** desejável, pós-v1 |
| 9 | Contabilidade (balancete, razão, DRE contábil, obrigações): **depois da implantação do SIGACTB e SIGAATF** |
| 10 | Representante vê a própria comissão e a inadimplência da carteira (**detalhar na fase dos representantes**) |

## 2. Escopo da v1: 50 telas com dado pronto

`✓` = já construída no Oryon dev (21); sem marca = dado pronto, falta construir (29).

| Área | Telas |
|---|---|
| **Comercial** (11) | C01 Visão executiva ✓ · C03 Análise detalhada ✓ · C04 Performance de vendedores ✓ · C05 Positivação e carteira ✓ · C06 Curva ABC e mix ✓ · C08 Pedidos em carteira · C09 Devoluções · C10 Bonificações, acordos e sell-out · C11 Preço e desvio de tabela · C12 Rede e grupo de clientes · C14 Clientes novos e recompra |
| **Compras** (6) | P01 Fornecedores e concentração ✓ · P02 Evolução de custo de compra ✓ · P03 Pedidos de compra em aberto e atrasados · P05 Histórico de preço por item · P06 Devoluções de compra · P07 Custo de entrada (frete, impostos) |
| **Financeiro** (10) | F01 Contas a receber ✓ · F02 Contas a pagar ✓ · F03 Fluxo de caixa ✓ · F04 Execução financeira ✓ · F05 Despesas por natureza ✓ · F06 Custo financeiro ✓ · F07 Comissões ✓ · F08 Posição bancária · F10 Prazo médio de recebimento e pagamento · F11 Inadimplência e provisão |
| **Produção** (7) | PR01 Visão executiva da produção ✓ · PR02 Produção semanal ✓ · PR03 Rendimento (yield) · PR04 Perdas e reprocessos · PR07 Consumo de insumos e embalagens · PR08 Ordens de produção · PR11 Gastos indiretos de fabricação |
| **RH/DP** (8) | H01 Headcount e estrutura ✓ · H02 Turnover e rescisões ✓ · H03 Banco de horas ✓ · H04 Hora extra ✓ · H07 Produtividade por colaborador · H09 Evolução salarial e equidade · H10 Dupla função e adicionais · H11 Ponto e marcações |
| **Fiscal/Contábil** (5) | X01 Impostos de saída · X02 Impostos de entrada e créditos · X04 Carga tributária por nota · X05 Notas de serviço (ISS) · X06 CT-e e frete fiscal |
| **Estoque** (1) | E03 Curva ABC de estoque |
| **Administração** (2) | A06 Execução do DW sob demanda ✓ · A04 Saúde dos dados |

## 3. Recursos da v1 (padrão em todas as áreas)

Filtros persistentes · períodos rápidos e ano fiscal · comparativos YoY/YTD · drill-down e
drill-through · **exportar Excel/CSV e PDF** · compartilhar por link · "atualizado em" e botão
Atualizar agora · glossário de métricas · responsivo (celular) · perfis e escopo por linha ·
auditoria de acesso. Demais recursos: ver a aba `Recursos x Áreas` do catálogo.

## 4. Depois da v1 (resumo)

- **Onda 3 (21 telas):** dependem de regra ou definição; cada uma tem dono e pendência na aba `Escopo v1`.
- **Portal (4 itens):** usuários e escopos, catálogo de métricas, auditoria e uso, alertas e agendamentos.
- **Marketing:** 10 telas e 10 KPIs em rascunho, a decidir (fonte: módulo MKT do Oryon e o gasto de sell-out).
- **Logística, contabilidade e estoque (parte):** em espera, conforme as decisões 5, 7 e 9.

## 5. Pendências com dono

| Pendência | Dono |
|---|---|
| Preencher `Dono` de cada item da onda 3 | Lucas |
| Validar a fonte confiável de estoque mínimo e ponto de pedido | Lucas |
| Premissas de absenteísmo (H05) | RH, a nomear |
| De-para do histórico pré-Protheus (DATAVALE, C16) | a nomear |
| Decidir as 10 telas e 10 KPIs de Marketing | Lucas |
