# Execução — operação do DW

> Como subir o ambiente, carregar dados e o que fazer quando algo falha.
> Referência conceitual: `docs/arquitetura.md`.

---

## 1. Ambiente

```bash
cp .env.example .env
```

Preencha o `.env`. O usuário do Protheus deve ser **somente leitura**. O arquivo
está no `.gitignore` e nunca deve ser versionado.

```bash
python -m venv .venv
source .venv/Scripts/activate    # Windows, Git Bash — use .venv\Scripts\activate no cmd/PowerShell
pip install -r requirements.txt
```

O extrator exige o **ODBC Driver 18 for SQL Server**. Sem ele, `pyodbc` falha
na conexão com o Protheus.

## 2. Banco

```bash
docker compose -f infra/docker-compose.yml up -d
```

Postgres na porta do `.env` (padrão 5433, para não colidir com uma instância
local em 5432) e Adminer em http://localhost:8080.

A maioria das máquinas não tem `psql` instalado fora do container — rode os
scripts direto nele (o nome do container é `alles_dw_postgres`, definido no
`docker-compose.yml`; confira com `docker ps` se subiu com outro nome):

```bash
docker exec -i alles_dw_postgres psql -U alles -d alles_dw < infra/sql/00_schemas.sql
docker exec -i alles_dw_postgres psql -U alles -d alles_dw < infra/sql/01_controle_cargas.sql
```

Se tiver `psql` local instalado, também funciona direto:

```bash
psql -h localhost -p 5433 -U alles -d alles_dw -f infra/sql/00_schemas.sql
psql -h localhost -p 5433 -U alles -d alles_dw -f infra/sql/01_controle_cargas.sql
```

Confira (dentro do `psql`, local ou via `docker exec -it alles_dw_postgres psql -U alles -d alles_dw`):
`\dn` deve listar `bronze`, `prata`, `ouro` — e ainda `raw` e `dw`, do piloto
anterior, que ficam intactos como referência de comparação.

## 3. Carga

**Conferir o plano antes de tocar no Protheus:**

```bash
python -m extracao.carga --listar
```

**Primeira carga — comece pequeno.** `SB1010` é cadastro de produtos: rápido,
serve para validar conexão, MERGE e registro de controle.

```bash
python -m extracao.carga --fonte SB1010
```

Valide:

```sql
select count(*) from bronze.sb1010;
select * from ouro.vw_saude_cargas;
```

**Idempotência — o teste que importa.** Rode a mesma carga de novo. A contagem
não pode mudar:

```bash
python -m extracao.carga --fonte SB1010
```

**Carga inicial do histórico.** É a operação mais pesada do projeto: ler todo o
`SD2010` do Protheus **de produção**.

```bash
python -m extracao.carga --fonte SD2010 --carga-inicial
```

Regras de segurança, não sugestões:

1. Rodar **fora do horário comercial**, combinado com quem opera o ERP.
2. O lote é anual. **Medir cada lote antes de seguir**: consulte
   `ouro.controle_cargas` para a duração e acompanhe o ERP.
3. Se algum lote degradar o ERP de forma perceptível, **parar e reavaliar** —
   o watermark preserva o que já entrou, então retomar é seguro.

**Carga incremental (a rotina).** Sem argumentos, percorre todas as fontes:

```bash
python -m extracao.carga
```

Cada fonte com watermark reprocessa os últimos 45 dias (`JANELA_MOVEL_DIAS`).
A janela existe porque nota fiscal é cancelada, corrigida e lançada com data
retroativa — sem ela, essas alterações nunca chegariam ao bronze. Notas que
somem da janela (canceladas) não são apagadas do bronze: ficam marcadas em
`_deletado`/`_deletado_em`.

`--carga-inicial` sem `--fonte` roda o histórico completo de **todas** as
fontes, em lotes anuais para as incrementais e carga cheia para as
dimensões — é o que popula o bronze pela primeira vez. Sigam-se as mesmas
regras de segurança acima.

## 4. Transformação

O dbt precisa de um `profiles.yml` local (nunca versionado) e das variáveis
do `.env` no ambiente — ele não lê o `.env` sozinho como o extrator Python.

```bash
cd transformacao
cp profiles.yml.example profiles.yml   # aponta pro Postgres via env_var()
export DBT_PROFILES_DIR=.
```

Para carregar o `.env` sem quebrar o shell (o arquivo tem um caminho de rede
do Windows com espaço, que o `source` do bash não interpreta bem), use o
`dotenv` CLI que já vem com o `python-dotenv`:

```bash
dotenv -f ../.env run -- dbt deps
dotenv -f ../.env run -- dbt seed              # carrega as regras versionadas (CSV) na prata
dotenv -f ../.env run -- dbt build             # roda seeds + modelos + testes
dotenv -f ../.env run -- dbt source freshness  # confere se alguma fonte parou de carregar
dotenv -f ../.env run -- dbt docs generate && dotenv -f ../.env run -- dbt docs serve
```

`dbt build` verde é o critério de aceite: se um teste de chave ou de not-null
falha, o dado não sobe.

Se `dbt --version` falhar com `UnserializableField` do `mashumaro`, é um bug
de versão conhecido entre o `dbt-core` 1.11 e o `mashumaro` 3.14 — o
`requirements.txt` já fixa uma versão mais nova que corrige.

## 5. Quando falha

**Carga com status `erro`.** O stack trace fica na própria tabela:

```sql
select fonte, inicio, mensagem_erro
from ouro.controle_cargas
where status = 'erro'
order by inicio desc
limit 10;
```

**Carga travada em `rodando`.** O processo morreu sem registrar o fim. O bronze
está íntegro — o MERGE é transacional, ou entrou tudo ou nada. Feche o registro
à mão e rode de novo:

```sql
update ouro.controle_cargas
set status = 'erro', fim = now(), mensagem_erro = 'processo interrompido'
where id = <id>;
```

**Coluna nova na origem.** O extrator adiciona sozinho e avisa no log
(`coluna nova em ...`). Nenhuma ação necessária — mas vale entender o que a
Alles criou no Protheus.

**Divergência de contagem contra o legado.** Esperada, e é o ponto: o bronze
traz linhas que o `raw` filtrava por regra de negócio. A diferença deve ser
**exatamente** as linhas excluídas por CFOP, filial, cliente ou nota — nada
além. Se for além, investigue antes de seguir.

## 6. O que nunca fazer

- Colocar filtro de negócio na extração. Bronze é pouso fiel; regra é da prata.
- Rodar a carga inicial em horário comercial.
- Versionar `.env` ou `profiles.yml`.
- Alterar qualquer coisa do legado que está em produção.
