# Backlog de paridade — o que o Power BI mede hoje

> Extração dos sete projetos `.pbip` de `C:\BI\PBIP`, em formato TMDL.
> Este documento responde à pergunta que o inventário do Excel não responde:
> *o que a empresa efetivamente mede com aqueles dados.*
> 21/08/2026. Complementa `docs/inventario_dw_legado.md` e `docs/arquitetura.md` (v1.3).

Modelos extraídos em `docs/pbip_extraido/*.md`, pelo script `extrair_tmdl.py`.

---

## 1. Panorama

**7 relatórios · 304 tabelas · 3.318 colunas · 484 medidas DAX · 281 relacionamentos · 50 páginas.**

| Relatório | Tabelas | Colunas | Medidas | Relações | Páginas |
|-----------|--------:|--------:|--------:|---------:|--------:|
| Comercial | 49 | 490 | **254** | 42 | 16 |
| Venda Real | 55 | 594 | 115 | 69 | 13 |
| Produção | 43 | 403 | 53 | 38 | 3 |
| Gestão de Pessoas | 64 | 873 | 41 | 52 | 10 |
| Gestão de Abastecimento | 49 | 438 | 17 | 45 | 4 |
| Média de Matéria Prima | 38 | 350 | 4 | 30 | 2 |
| Pedidos de Venda | 6 | 170 | 0 | 5 | 2 |

Todas as 304 tabelas estão em modo **import** — nenhum DirectQuery. As origens
confirmam a cadeia completa: **Protheus → Excel (`P:\T.I\01. BASES`) → Power BI**.
Os modelos leem `fFaturamento.xlsx`, `dCalendario.xlsx`, `dProdutos.xlsx`, `fCusto.xlsx`,
`fCompras.xlsx`, `fGestaoPessoas.xlsx` e companhia — os mesmos workbooks inventariados.
Cinco tabelas de `Pedidos de Venda` vêm de **dataflows do Power BI**, uma terceira
origem que não estava mapeada.

---

## 2. O que o negócio mede — os blocos que o ouro precisa sustentar

### Comercial (254 + 115 medidas)

**Faturamento e metas.** Faturamento bruto e líquido, peso, preço médio, ticket médio,
notas emitidas — cada um com comparativo YoY e MoM. Metas com **diluição por família de
produto × gestor**, meta diária original e recalculada, meta MTD até hoje, dias úteis
realizados, forecast de fechamento e percentual de atingimento em KG e em R$.

**Deduções da receita.** Devoluções, acordo comercial, descontos, bonificação e
refaturamento, cada um com peso, preço médio e participação percentual sobre a receita
bruta — mais rankings de quem mais devolve, por família, cliente e setor.

**Preço.** Preço de tabela versus praticado, desvio percentual por família, gestor,
cliente e pedido, preço médio ponderado.

**Clientes.** Segmentação **RFV completa em 11 segmentos** (campeões, fiéis, potenciais
fiéis, recentes, hibernando, promissores, precisam de atenção, prestes a hibernar, não
podemos perdê-los, em risco, perdidos) com valor, contagem e percentual de cada.
Positivação e reativação mensal, clientes novos, inativos há mais de 60 dias, base
ativa, taxa de conversão de prospects.

**Concentração.** Pareto de produtos (acumulado, complemento, quantidade de produtos que
formam 80% do faturamento, comparação de ranking com o mês anterior) e Curva ABC de
clientes com corte em 80% e 95%.

**Ponte preço-volume-mix.** O modelo Comercial tem uma decomposição completa de
variação: efeito volume, efeito preço e efeito mix — cada um sobre venda, sobre custo e
sobre margem — mais o impacto de clientes novos e de clientes perdidos, e os efeitos de
desconto e devolução sobre a margem. É a análise mais sofisticada do acervo.

**Margem.** Existe, mas é **paramétrica, não custeada**: `Margem = -(1 - Mk-UP - %COMISS
- GGF - ICMS - PIS - COFINS - Fin)`, com o custo vindo de `AVERAGE(TabelaPrecos[CustoUnitario])`.
Não é margem apurada contra custo real de produção.

**Trade e promotores.** Custo de agências de promotores, faturamento de clientes com
promotor, retorno sobre investimento linha a linha, sell-out.

### Produção (53 medidas)

Produção por turno (A e B) e total, com **meta e atingimento por linha de produto** —
almôndega, hambúrguer, carne moída, calabresa, linguiça, salsicha, mortadela. Lançamentos
por linha e **percentual de quebra** de cada uma. Produção semanal.

### Gestão de Abastecimento (17 medidas)

Fluxo de recebimento (peso inicial, peso final, diferença, quantidade de NF, veículos,
tempo médio de permanência), previsão de produção, estoque, necessidade de compra,
consumo previsto e capacidade de produção.

### Matéria-prima (4 medidas)

Custo médio unitário e ponderado por fornecedor.

### Gestão de Pessoas (41 medidas)

Headcount mês a mês (com e sem afastados), budget de headcount, admitidos e demitidos,
**turnover** com média, soma mensal, por área e contra budget, motivos de desligamento.
**Banco de horas** (saldo, crédito, débito, ranking de positivos e negativos) e **horas
extras** (saldo, valor por verba, índice, valor-hora, HE 50% e 100%, base de cálculo com
periculosidade, insalubridade e adicional de dupla função). Páginas de absenteísmo,
acidentes e SLA de vagas.

### Pedidos de Venda

Fluxo de embarque e pedidos em aberto — sem medidas, só tabelas e visuais diretos.

---

## 3. Conflitos e dívidas encontrados

**Dois modelos para o mesmo assunto.** `Comercial` e `Venda Real` cobrem ambos o
faturamento, com fatos diferentes — `fFaturamentoConsolidado[_TOTALVENDA]` contra
`fFaturamento[TOTAL]` — e medidas equivalentes com nomes distintos:

| Comercial | Venda Real | Mesma coisa? |
|-----------|------------|--------------|
| `Faturamento (Atual)` | `Total Vendido` | Sim, fatos diferentes |
| `Faturamento Liquido` | `Venda Real Liquida` | Fórmula idêntica, nome diferente |
| `Peso Total (Atual)` | `Peso Total` | Sim |
| `Tot Devolvido` | `Total Devolvido` | Sim |

**E, dentro do próprio `Venda Real`, duas medidas quase homônimas com semânticas
diferentes:** `Venda Real Liquida` subtrai devolução; `VENDA REAL` **não subtrai**, e
ainda é calculada linha a linha com `SUMX`. Quem usa uma achando que é a outra obtém um
número diferente sem nenhum aviso.

**Calendário replicado cinco vezes.** `dCalendar`, `dCalendario` e `FluxodCalendario`
convivem em cinco modelos. O mesmo vale para `dProdutos`/`FluxodProdutos` (5 modelos),
`dFamilia` (4) e `FluxofCusto` (4).

**Sedimento visível no modelo.** Medidas chamadas `test`, `preço real 123`,
`Teste_Ultima_Compra_Global`, `Faturamento Liquido 2`, `Meta Diluída 2`,
`% Fat (kg) vs Meta (kg) Cartão 2`, além de `$ TOT DESC_OLD` e `%DESCTOT_OLD` convivendo
com as versões sem sufixo. Ninguém sabe quais visuais ainda apontam para as antigas.

**Vinte e duas medidas para um ranking.** `Top 1 Nome` … `Top 11 Nome` e
`Top 1 Atingimento` … `Top 11 Atingimento`, mais `Top 1..3 ProdutoDesc/ProdutoFat/ProdutoFoto`.
No modelo alvo isso é uma consulta com `ORDER BY` e `LIMIT`.

**Um erro de digitação virou nome permanente.** A tabela de custos chama-se
`TebelaPrecosConsu` e é referenciada assim por todas as medidas de margem.

**Nenhum RLS.** Nenhum dos sete modelos define papéis de segurança em nível de linha.
Isso significa que **a alçada por carteira não existe hoje** — quando o Oryon Board a
aplicar, será capacidade nova, não migração. Vale ajustar a expectativa de quem hoje vê
tudo.

**Nove relacionamentos bidirecionais e cinco inativos** distribuídos pelos modelos —
cada bidirecional é um caminho de ambiguidade em potencial que o modelo estrela do ouro
deve eliminar por construção.

---

## 4. O que isso obriga no desenho do ouro

1. **Um só fato de faturamento.** `Comercial` e `Venda Real` convergem para
   `fato_faturamento`, com as deduções (devolução, acordo, desconto, bonificação,
   refaturamento) como fatos próprios ligados a ele. As duas versões de "venda líquida"
   viram **uma** métrica com definição escrita.
2. **Dimensões conformadas de verdade.** Calendário, produto, família, cliente,
   vendedor e gestor existem uma vez, no ouro, e servem os nove domínios.
3. **Metas como fato de primeira classe.** Meta por família × gestor × mês, com a
   diluição e o cálculo de MTD feitos em SQL, não em DAX.
4. **Custo real, para a margem deixar de ser paramétrica.** O domínio Custo (fase 5)
   é o que permite substituir `Margem = -(1 - Mk-UP - ...)` por margem apurada.
5. **As análises pesadas viram marts.** RFV, Pareto, Curva ABC, positivação/reativação
   e a ponte preço-volume-mix são caras de recalcular a cada abertura de tela: devem ser
   materializadas no ouro, não computadas no request.
6. **Alçada é requisito novo.** Não há RLS a migrar; o desenho parte do zero.

---

## 5. Uma oportunidade que muda o risco do projeto

Como os relatórios leem dos workbooks Excel, e não do Protheus direto, **é possível
repontar um relatório existente para o ouro assim que o domínio dele estiver pronto** —
trocando `Excel.Workbook(...)` por `PostgreSQL.Database(...)` nas partições, sem
reconstruir visual nenhum.

Isso resolve o risco de fôlego registrado na arquitetura (valor visível só na Fase 12):
cada domínio concluído pode devolver valor imediato, e o relatório em produção vira o
melhor teste de reconciliação possível — se os números da tela não mudarem, o ouro está
correto.

Não substitui o Oryon Board; é uma ponte entre a entrega do DW e a das telas.

---

## 6. Perguntas que o inventário levanta

1. **`Comercial` ou `Venda Real` — qual é a referência?** Os dois medem faturamento com
   fatos diferentes. Assim como no caso da planilha versus relatórios da diretoria,
   isso precisa de veredito.
2. **`VENDA REAL` deveria subtrair devolução?** Se sim, é um erro em produção hoje.
3. **As medidas `_OLD`, `2`, `test` ainda alimentam algum visual?** Dá para verificar
   varrendo os JSON das páginas — vale fazer antes de migrar qualquer uma delas.
4. **A margem paramétrica é aceitável no destino**, ou o projeto deve entregar margem
   custeada quando o domínio Custo ficar pronto?
5. **Os dataflows de `Pedidos de Venda`** — o que alimenta esses cinco conjuntos, e essa
   origem continua depois da migração?
