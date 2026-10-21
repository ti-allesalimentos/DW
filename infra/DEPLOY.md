# Deploy do DW Alles em VM Linux de produção

> Runbook passo a passo. A infra já está escrita no repo (docker-compose,
> systemd units, SQLs, extrator em `pytds`, pipeline). Aqui é **provisionar,
> subir e validar**. Operação do dia a dia e refresh por dashboard: ver
> [`docs/operacao_warehouse.md`](../docs/operacao_warehouse.md).

Convenção: o projeto vive em **`/opt/alles-dataplatform`** e roda sob o usuário
de serviço **`alles-dw`** (é o que os systemd units esperam).

---

## Pré-requisitos — especificação da VM (para o time de infra)

DW on-premises: Postgres + ETL Python + dbt, consumido pelo backend do Oryon.

**Hardware**
| Recurso | Mínimo | Recomendado | Observação |
|---------|--------|-------------|------------|
| vCPU | 4 | 8 | `dbt build` a cada 2h; carga inicial é intensiva |
| RAM | 8 GB | 16 GB | extração carrega lotes em memória (pandas); Postgres + dbt juntos |
| Disco | 100 GB SSD | 200 GB SSD | DB + índices + 14 dias de backup (~1,2 GB/dump) + WAL + Docker + logs |

**SO:** Ubuntu Server LTS 22.04/24.04 ou Debian 12, **x86_64**. Timezone **America/Sao_Paulo**.

**Software** (o deploy instala; infra pode deixar pronto): Docker Engine + Docker
Compose plugin, Python 3.11+, git.

**Rede**
- **Saída:** acesso ao **Protheus (SQL Server)** de produção (host/porta) + internet
  para Docker Hub, PyPI, GitHub e SMTP (allowlist possível).
- **Entrada:** **TCP 8090** (trigger-api) e **TCP 5433** (Postgres) **apenas do IP do
  backend do Oryon** — nunca internet; + **SSH (22)** para administração.
- Firewall (ufw/firewalld) aplicando as regras acima.

**Acesso/contas:** SSH; permissão para criar o usuário de serviço **`alles-dw`** no
grupo **`docker`**; usuário Protheus **somente leitura**; senha forte para o Postgres
do DW.

**Dimensionamento do disco:** o histórico do Protheus começa em **01/02/2025** (a
carga inicial não multiplica muito o volume), mas reserve folga para crescimento; os
backups podem ir para um mount/volume separado se preferirem.

---

## Fase 1 — Provisionar a VM

```bash
# usuário de serviço + docker
sudo useradd -r -m -d /opt/alles-dataplatform -s /usr/sbin/nologin alles-dw
sudo usermod -aG docker alles-dw          # para o pipeline/backup usarem `docker exec`

# código (deploy a partir do git)
sudo -u alles-dw git clone git@github.com:ti-allesalimentos/DW.git /opt/alles-dataplatform
cd /opt/alles-dataplatform

# venv + dependencias (pinadas no requirements.txt; extrator usa pytds, sem ODBC)
sudo -u alles-dw python3 -m venv .venv
sudo -u alles-dw .venv/bin/pip install -r requirements.txt
```

**Secrets (`.env`, fora do git):**
```bash
sudo -u alles-dw cp .env.example .env
sudo -u alles-dw nano .env    # preencher Protheus (read-only), senha do DW,
                              # TRIGGER_API_KEY e o bloco SMTP (alerta por e-mail)
```

**Rede/firewall:** liberar a porta **8090** (trigger-api) **só para o IP do backend
do Oryon**; nunca para a internet. O Postgres (5433) não sai da VM.

---

## Fase 2 — Subir o DW

```bash
cd /opt/alles-dataplatform

# 1) Postgres do DW (container)
docker compose -f infra/docker-compose.yml up -d postgres

# 2) Schemas, controle de cargas, execucoes manuais
docker exec -i alles_dw_postgres psql -U alles -d alles_dw < infra/sql/00_schemas.sql
docker exec -i alles_dw_postgres psql -U alles -d alles_dw < infra/sql/01_controle_cargas.sql
docker exec -i alles_dw_postgres psql -U alles -d alles_dw < infra/sql/02_execucoes_manuais.sql

# 3) Role de leitura do Oryon (oryon_ro) — criar com a senha do .env do backend,
#    depois aplicar os grants (idempotentes).
docker exec -i alles_dw_postgres psql -U alles -d alles_dw \
  -c "CREATE ROLE oryon_ro LOGIN PASSWORD 'DEFINA_A_SENHA';"
docker exec -i alles_dw_postgres psql -U alles -d alles_dw < infra/sql/03_grants_oryon_ro.sql

# 4) dbt: deps + seeds
cd transformacao
cp profiles.yml.example profiles.yml
export DBT_PROFILES_DIR=.
dotenv -f ../.env run -- ../.venv/bin/dbt deps
dotenv -f ../.env run -- ../.venv/bin/dbt seed
cd ..
```

**Backup (inegociável em produção):** habilitar o timer diário (ver Fase 4) e
**testar um restore** antes do go-live (ver seção Backup/Restore).

---

## Fase 3 — Carga inicial do histórico

A operação mais pesada do projeto (ler todo o `SD2` do Protheus). Fazer **fora do
horário comercial**, por lotes anuais, medindo o impacto no ERP.

```bash
cd /opt/alles-dataplatform
.venv/bin/python -m extracao.carga --listar          # confere o plano
.venv/bin/python -m extracao.carga --carga-inicial    # historico completo, por lotes

cd transformacao
export DBT_PROFILES_DIR=.
dotenv -f ../.env run -- ../.venv/bin/dbt build        # primeira construcao = full
```

Meta: **`dbt build` verde** (`PASS=... ERROR=0`) e bronze/ouro populados.

---

## Fase 4 — Orquestração automática (systemd)

```bash
cd /opt/alles-dataplatform/infra/systemd
sudo cp alles-dw-*.service alles-dw-*.timer /etc/systemd/system/
sudo cp alles-dw.logrotate /etc/logrotate.d/alles-dw
sudo systemctl daemon-reload

# pipeline a cada 2h + trigger-api + backup diario
sudo systemctl enable --now alles-dw-pipeline.timer
sudo systemctl enable --now alles-dw-trigger-api.service
sudo systemctl enable --now alles-dw-backup.timer
```

Validar:
```bash
systemctl list-timers 'alles-dw-*'            # proximos disparos
sudo systemctl start alles-dw-pipeline.service # roda um ciclo agora
journalctl -u alles-dw-pipeline.service -f     # acompanha
curl -s localhost:8090/health                  # trigger-api
```

**Teste do alerta:** force uma falha (ex.: `.env` com Protheus inválido) e confirme
que o e-mail chega (`alles-dw-alerta@...`). Depois corrija.

**Gate da Fase 3 (arquitetura):** 7 dias rodando sozinho sem intervenção.

---

## Fase 5 — Go-live (cutover para o Oryon)

1. Reconciliar os domínios já fechados (Comercial) contra o legado, **na VM**.
2. Apontar o backend do Oryon (produção) para o DW de prod: `DW_POSTGRES_HOST`
   (host interno da VM), `DW_POSTGRES_PORT=5433`, `DW_POSTGRES_USER=oryon_ro`.
   O backend lê **só o schema `ouro`**.
3. Conferir as telas do Board carregando com dado de produção.

---

## Backup / Restore

- **Backup:** `infra/scripts/backup_dw.sh` (timer diário 03:00). Gera
  `backups/alles_dw_AAAAMMDD_HHMMSS.sql.gz`, retém 14 dias.
- **Restore:**
  ```bash
  gunzip -c backups/alles_dw_AAAAMMDD_HHMMSS.sql.gz \
    | docker exec -i alles_dw_postgres psql -U alles -d alles_dw
  ```
- **Drill obrigatório antes do go-live:** restaurar um backup num banco/efêmero e
  conferir contagens.

---

## Troubleshooting rápido

| Sintoma | Causa provável / ação |
|---|---|
| `Could not import module "main"` (backend) / container em restart logo após reiniciar o Docker | bind-mount em cache obsoleto → `docker compose up -d --force-recreate` |
| Board para de ler após um `dbt build` | grant do `oryon_ro` → reaplicar `infra/sql/03_grants_oryon_ro.sql` (o ALTER DEFAULT PRIVILEGES evita isso) |
| Extração falha ao conectar no Protheus | `.env` (host/porta/credenciais). O extrator usa `pytds` — **não** precisa de ODBC |
| `dbt` com erro de versão/import | usar o `.venv` do projeto (deps pinadas: dbt-core 1.12.x, mashumaro≥3.22) |
| Pipeline falhou | `journalctl -u alles-dw-pipeline -n 100` e `ouro.controle_cargas` / `ouro.vw_saude_cargas` |
