# Prompts para o Claude Code

Use um prompt por fase. Faça a fase terminar (com o "Meta" atingido)
antes de passar ao próximo. Cole o prompt no Claude Code, dentro da
pasta do projeto.

---

## Prompt 0 — Contexto (rode uma vez, no início)
> Este é um projeto de data warehouse replicável. Leia o `README.md`,
> o `docs/roadmap.md` e o `sql/01_modelo_faturamento.sql` para entender
> a arquitetura. Estamos migrando um DW que hoje vive em Excel/Power Query
> para Postgres + dashboards em Python. Vamos avançar UMA fase por vez;
> não pule etapas e me explique cada ferramenta nova antes de usá-la.

## Prompt 1 — Ambiente e Postgres
> Fase 1 e 2. Me guie para: criar o `.env` a partir do `.env.example`,
> subir o Postgres e o Adminer com `docker compose up -d`, e validar que
> o banco responde. Explique cada comando do Docker. Não avance de fase.

## Prompt 2 — Criar a estrutura do banco
> Com o Postgres no ar, execute o `sql/01_modelo_faturamento.sql` para
> criar os schemas `raw` e `dw` e todas as tabelas. Depois liste as
> tabelas criadas em cada schema para confirmar. A `dw.map_produto_cx`
> deve já vir preenchida.

## Prompt 3 — Ingestão do Protheus
> Fase de ingestão. Vou preencher as credenciais do Protheus no `.env`.
> Confira o `ingestion/queries/faturamento.sql`, ajuste se preciso, e rode
> `ingestion/extract_protheus.py` para popular `raw.faturamento`.
> Valide com um `count(*)`. Se faltar driver ODBC do SQL Server, me ajude a instalar.

## Prompt 4 — Dimensões e povoamento do fato
> Popular o modelo. Traga as dimensões (produto, familia, cliente,
> vendedor, calendario) para as tabelas `dw.dim_*` — a partir do Protheus
> ou das planilhas atuais. Em seguida rode o bloco de povoamento do fato
> do `sql/01_modelo_faturamento.sql`. Explique como a conversão -CX é
> aplicada pelo join com `map_produto_cx`.

## Prompt 5 — Reconciliação
> Rode a query de reconciliação (`count` e `sum(total)` de
> `dw.fato_faturamento`) e me ajude a comparar com o total do
> `fFaturamento` na planilha antiga. Se houver diferença, investigue
> filtros de CFOP, filial e exclusões de NF até bater.

## Prompt 6 — Dashboard
> Suba o `dashboards/faturamento_app.py` com
> `streamlit run dashboards/faturamento_app.py`. Confirme que os
> indicadores batem com a planilha. Depois me ajude a evoluir o dashboard
> reproduzindo os gráficos que eu já tenho hoje.

## Prompt 7 — dbt (transformação versionada)
> Fase de transformação. Introduza o dbt: inicialize um projeto
> `dbt-postgres`, e converta o bloco de povoamento do fato em modelos dbt
> nas camadas bronze → silver → gold, com testes de chave e de not-null.
> Explique o dbt conforme formos avançando.

## Prompt 8 — Dagster (orquestração)
> Última fase do piloto. Introduza o Dagster para orquestrar o fluxo
> ingestão (Protheus → raw) → dbt (transformação) → dashboard, com
> agendamento diário. Isto substitui o antigo `atualizador.xlsm`.

## Prompt 9 — Extrair o template replicável
> O piloto de faturamento está validado. Ajude-me a generalizar este
> projeto num template: parametrizar por `config/cliente.yml`, isolar a
> biblioteca de componentes de dashboard reutilizáveis, e documentar como
> criar um cliente novo do zero.
