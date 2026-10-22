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

Executado e validado na VM `srvdatawarehouse` (Ubuntu 24.04). O `sudo` pede a senha
do seu usuário; os demais comandos rodam como o usuário de serviço `alles-dw`.

```bash
# fuso horario (os timers dependem disso) + pacotes (no Ubuntu 24.04 o venv e pacote a parte)
sudo timedatectl set-timezone America/Sao_Paulo
sudo apt-get update && sudo apt-get install -y python3.12-venv python3-pip

# usuario de servico. O home e /home/alles-dw (NAO /opt/...): o git clone abaixo
# precisa de um diretorio vazio.
sudo useradd -m -s /bin/bash alles-dw
sudo usermod -aG docker alles-dw          # para o pipeline/backup usarem `docker`
sudo mkdir -p /opt/alles-dataplatform
sudo chown alles-dw:alles-dw /opt/alles-dataplatform
```

**Chave de deploy (o repositório é privado, a VM clona por SSH, somente leitura):**
```bash
sudo -u alles-dw mkdir -m 700 /home/alles-dw/.ssh
sudo -u alles-dw ssh-keygen -t ed25519 -N "" -C "alles-dw@srvdatawarehouse" -f /home/alles-dw/.ssh/id_ed25519
sudo -u alles-dw sh -c 'ssh-keyscan -t ed25519 github.com >> /home/alles-dw/.ssh/known_hosts'
sudo cat /home/alles-dw/.ssh/id_ed25519.pub     # chave PUBLICA (nao e segredo)
```
No GitHub: **ti-allesalimentos/DW → Settings → Deploy keys → Add deploy key**, cole a
chave pública e **deixe "Allow write access" desmarcado**. Teste (a mensagem
`successfully authenticated` basta; o comando sai com código 1 mesmo assim):
```bash
sudo -u alles-dw ssh -T git@github.com
```

**Código e dependências:**
```bash
# use --branch master (ou a branch de ensaio, enquanto o PR nao estiver mesclado)
sudo -u alles-dw git clone --branch master git@github.com:ti-allesalimentos/DW.git /opt/alles-dataplatform
cd /opt/alles-dataplatform
sudo -u alles-dw python3 -m venv .venv
sudo -u alles-dw .venv/bin/pip install -r requirements.txt   # extrator usa pytds, sem ODBC
sudo -u alles-dw .venv/bin/dbt --version | grep -iE "installed|postgres"   # dbt-core 1.12.x
```

**Secrets (`.env`, fora do git).** A senha do Postgres e a `TRIGGER_API_KEY` são geradas
na própria VM e nunca passam pelo terminal:
```bash
sudo -u alles-dw bash -c 'cd /opt/alles-dataplatform \
  && cp .env.example .env && chmod 600 .env \
  && sed -i "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$(openssl rand -hex 24)|; s|^TRIGGER_API_KEY=.*|TRIGGER_API_KEY=$(openssl rand -hex 32)|" .env'

sudo -u alles-dw nano /opt/alles-dataplatform/.env   # Protheus (read-only) e bloco SMTP
```
Mantenha `POSTGRES_HOST=localhost` e `POSTGRES_PORT=5433` (o pipeline roda na VM). **Não use
comentário na mesma linha de um valor** (o `alertar_falha.sh` lê a linha crua).

Valide as conexões (somente leitura, não imprime credenciais). O Protheus deve dar `[OK]`;
o Postgres só passa depois da Fase 2:
```bash
sudo -u alles-dw bash -c 'cd /opt/alles-dataplatform && .venv/bin/python infra/scripts/testar_conexoes.py'
```

**Rede/firewall:** liberar a porta **8090** (trigger-api) **só para o IP do backend
do Oryon**; nunca para a internet. O Postgres (5433) só precisa ser alcançável pelo
backend do Oryon (role somente leitura) e nunca pela internet.

---

## Fase 2 — Subir o DW

```bash
cd /opt/alles-dataplatform

# 1) Postgres do DW (container). O --env-file e OBRIGATORIO: sem ele o compose procura
#    o .env dentro de infra/, nao acha, e sobe com usuario/banco vazios.
sudo -u alles-dw docker compose -f infra/docker-compose.yml --env-file .env up -d postgres
sudo docker ps --filter name=alles_dw_postgres --format '{{.Names}} {{.Status}}'   # espere "(healthy)"

# 2) Schemas, controle de cargas, execucoes manuais (idempotentes)
for f in 00_schemas 01_controle_cargas 02_execucoes_manuais; do
  sudo -u alles-dw docker exec -i alles_dw_postgres psql -U alles -d alles_dw -v ON_ERROR_STOP=1 < infra/sql/$f.sql
done
```

**3) Role de leitura do Oryon (`oryon_ro`).** A senha é digitada no `psql` (não aparece
na tela nem fica no histórico). Guarde-a no gerenciador de senhas: vai no `.env` do
backend do Oryon como `DW_POSTGRES_PASSWORD`.
```bash
sudo -u alles-dw docker exec -it alles_dw_postgres psql -U alles -d alles_dw
#   dentro do psql:
#     CREATE ROLE oryon_ro LOGIN;
#     \password oryon_ro
#     \q
sudo -u alles-dw docker exec -i alles_dw_postgres psql -U alles -d alles_dw -v ON_ERROR_STOP=1 < infra/sql/03_grants_oryon_ro.sql
```

**4) dbt: dependências e seeds:**
```bash
sudo -u alles-dw bash -c 'cd /opt/alles-dataplatform/transformacao \
  && cp -n profiles.yml.example profiles.yml && export DBT_PROFILES_DIR=. \
  && ../.venv/bin/dotenv -f ../.env run -- ../.venv/bin/dbt deps \
  && ../.venv/bin/dotenv -f ../.env run -- ../.venv/bin/dbt seed'
```

**Backup (inegociável em produção):** habilitar o timer diário (ver Fase 4) e
**testar um restore** antes do go-live (ver seção Backup/Restore).

---

## Fase 3 — Carga inicial do histórico

A operação mais pesada do projeto: lê as 71 fontes do Protheus de produção. Estimativa
(histórico de cargas do DW de dev): **3 a 5 horas**, dominadas pela leitura do Protheus
(só `SELECT`; as fontes por data entram em lotes anuais a partir de 01/02/2025, os
cadastros e as sem data entram cheios). Fazer **fora do horário comercial**.

O extrator (`python -m extracao.carga`) **para na primeira fonte que falha**. Por isso a
carga inicial usa o runner `infra/scripts/carga_inicial.sh`: chama o extrator **uma fonte
por vez**, segue adiante quando uma falha, **pula o que já foi carregado** (é retomável) e
lista no fim o que falhou. Reexecutar não duplica nada (a carga é `MERGE`).

```bash
cd /opt/alles-dataplatform
sudo -u alles-dw bash -c 'DRY_RUN=1 infra/scripts/carga_inicial.sh'   # mostra o plano (nao carrega)

# carga de verdade, desacoplada do SSH (pode fechar o terminal):
sudo -u alles-dw bash -c 'nohup infra/scripts/carga_inicial.sh >/dev/null 2>&1 &'
tail -f logs/carga_inicial.log          # acompanha (Ctrl+C so sai do tail)
```

Se alguma fonte falhar, o final do log lista quais e o comando para refazer só elas
(`infra/scripts/carga_inicial.sh FONTE1 FONTE2`). Para uma fonte específica já carregada,
`FORCAR=1`. Conferência do estado, a qualquer hora:
```bash
sudo docker exec alles_dw_postgres psql -U alles -d alles_dw -c \
  "select status, count(*) from ouro.controle_cargas group by 1;"
```

Depois da carga, construa o modelo (primeira construção = full):
```bash
sudo -u alles-dw bash -c 'cd /opt/alles-dataplatform/transformacao && export DBT_PROFILES_DIR=. \
  && ../.venv/bin/dotenv -f ../.env run -- ../.venv/bin/dbt build'
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
| Postgres não sobe / `variable POSTGRES_USER is not set` | faltou `--env-file .env` no `docker compose` (sem ele o `.env` é procurado em `infra/`) |
| `pip install` falha com `ResolutionImpossible` (mashumaro) | usar o `requirements.txt` do repo (`mashumaro>=3.15,<3.18`); não forçar versão do mashumaro |
| Extração falha ao conectar no Protheus | `.env` (host/porta/credenciais). O extrator usa `pytds` — **não** precisa de ODBC |
| `dbt` com erro de versão/import | usar o `.venv` do projeto (deps pinadas: dbt-core 1.12.x, mashumaro≥3.22) |
| Pipeline falhou | `journalctl -u alles-dw-pipeline -n 100` e `ouro.controle_cargas` / `ouro.vw_saude_cargas` |
