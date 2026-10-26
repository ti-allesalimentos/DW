# Operação do Warehouse — como funciona e como atualizar

> Como o DW roda no dia a dia, como funcionam as **atualizações incrementais** e
> como disparar **atualizações pontuais por dashboard**. Para instalar em produção,
> ver [`infra/DEPLOY.md`](../infra/DEPLOY.md); para a arquitetura e performance,
> `docs/arquitetura.md` e `docs/arquitetura_performance.md`.

---

## 1. Como o DW funciona (visão de ponta a ponta)

```
PROTHEUS (SQL Server)                     POSTGRES — DW
   │  extrator Python (pytds)                 bronze   espelho fiel das tabelas
   │  watermark + janela movel + MERGE   ──▶    │  dbt (views)
   │                                           prata   conformado (stg_*)
   │                                            │  dbt (tabelas / incremental)
   │                                           ouro    dim_/fato_/agg_  ◀── Oryon Board (oryon_ro)
```

1. **Extração** (`extracao/carga.py`): lê o Protheus e grava no `bronze` por
   `MERGE` (idempotente). Cada carga registra em **`ouro.controle_cargas`**
   (fonte, janela, linhas, status).
2. **Transformação** (`dbt`): `prata` conforma (views `stg_*`), `ouro` modela
   (`dim_`/`fato_`/`agg_`, tabelas). Fatos grandes são **incrementais**.
3. **Consumo**: o backend do Oryon lê **só o schema `ouro`** (role `oryon_ro`,
   somente leitura).

**Ciclo automático:** o systemd (`alles-dw-pipeline.timer`) roda a cada **2h**
`rodar_pipeline.sh` = **extração incremental → `dbt build`**. Se a extração falha,
para antes do dbt. Falha dispara **alerta por e-mail**.

---

## 2. Atualização incremental (o que é reprocessado)

O princípio é **reprocessar só a janela recente**, não a história toda — do extrator
até o dbt.

**No extrator:** relê o Protheus a partir de `watermark − janela`. O tipo de janela
segue a fonte (`extracao/fontes.yml`):
- **Data de negócio** (`D2_EMISSAO`, `D1_EMISSAO`, `C5_EMISSAO`): janela de **45 dias**
  — pega cancelamentos e lançamentos retroativos de NF.
- **`S_T_A_M_P_`** (SE1/SE2/SC6/SD3): janela de **3 dias** — pega alteração em
  registro antigo (ex.: baixa de um título velho).
- Cadastros (SA1/SB1/SA3…): carga **full** (são pequenos).

**No dbt (fatos grandes incrementais):** um `pre_hook` apaga a janela recente e o
modelo reinsere só esse período — o que **absorve updates e cancelamentos**. Duas
variantes, alinhadas ao watermark da fonte:
- **Variante A — janela por data de emissão (60d):** faturamento, devoluções,
  bonificação, refaturamento, coopeval, acordo, remessa.
- **Variante B — janela por `_carregado_em` (7d):** contas a pagar/receber,
  apontamento de produção, pedidos.

> Detalhe técnico completo: `docs/arquitetura_performance.md §5`.

**Quando rodar FULL (reconstruir tudo):** só após a **carga inicial do histórico**,
ou quando mudar a **regra** de um fato (a lógica passada precisa ser recalculada):
```bash
cd transformacao
dotenv -f ../.env run -- ../.venv/bin/dbt build --full-refresh --select <modelo>
```

---

## 3. Atualizações pontuais **por dashboard**

Cada dashboard do Board corresponde a um **domínio**, que agora é uma **pasta** de
modelos (`models/ouro/<domínio>`). Isso permite extrair só as fontes daquele assunto
e reconstruir só aquele domínio — sem rodar o ciclo inteiro.

### Mapa dashboard → domínio → fontes
| Dashboard (Board) | Domínio (pasta) | Fontes Protheus principais |
|---|---|---|
| Faturamento / Comercial | `comercial` | `SD2010 SD1010 SC5010 SC6010` (+ dims `SA1 SB1 SA3`) |
| Financeiro (receber/pagar/caixa…) | `financeiro` | `SE1010 SE2010 SE5010` |
| Compras / Fornecedores | `compras` | `SC1010 SC7010 SB2010 SA2010` |
| Produção | `industrial` | `SC2010 SD3010 SG2010 SH6010` |
| Gestão de Pessoas | `gestao_pessoas` | `SRA SRC SRD SRG SP*…` |
| Fiscal | `fiscal` | `SFT SDT SD1/SD2 SE2 SED…` |
| Logística / Fretes | `logistica` | `GU3 GW1 GW3 GW4 GWD…` |

### Opção A — manual (terminal)
Refresca o **dado do domínio** (extrai as fontes + reconstrói o domínio com as
dependências upstream — prata + dims compartilhadas):
```bash
cd /opt/alles-dataplatform

# 1) extrai só as fontes do domínio (exemplo: comercial)
for fonte in SD2010 SD1010 SC5010 SC6010; do
  .venv/bin/python -m extracao.carga --fonte "$fonte"
done

# 2) reconstrói só o domínio comercial (+ upstream: prata e dims)
cd transformacao
dotenv -f ../.env run -- ../.venv/bin/dbt build --select +path:models/ouro/comercial
```
- `+path:models/ouro/comercial` = os modelos de `ouro/comercial` **e seus
  ancestrais** (prata do comercial + dims conformadas). Os fatos incrementais
  reprocessam só a janela.
- Para um único modelo/tela: `--select +fato_faturamento` ou
  `--select +agg_faturamento_mes`.

### Opção B — sob demanda pela API (o botão "Atualizar agora" do Board)
A **`trigger_api`** (`infra/trigger_api/main.py`, porta 8090, protegida por
`X-API-Key`, uma execução por vez) expõe:
```
GET  /health
GET  /fontes                 # fontes + status da ultima carga
GET  /dominios               # dashboards que podem ser atualizados sob demanda
GET  /execucoes              # historico de execucoes manuais
POST /cargas/rodar           # body: {"fonte"|"dominio"|null, "solicitado_por"}
```

`POST /cargas/rodar` aceita (um OU outro, nunca os dois):
- **`dominio`** (ex.: `"comercial"`) → **refresh por dashboard**: extrai só as
  fontes daquele domínio e roda `dbt build --select +path:models/ouro/<dominio>`.
  As fontes são derivadas do **grafo do dbt** (seguem as dependências reais,
  inclusive cadastros e dependências cruzadas) — não há mapa a manter à mão.
- **`fonte`** (ex.: `"SD2010"`) → uma fonte + `dbt build` completo.
- **nenhum** → todas as fontes + build completo (= o ciclo do systemd).

Exemplo (o que o botão "Atualizar agora" do Board dispara):
```bash
curl -X POST http://<vm>:8090/cargas/rodar \
  -H "X-API-Key: $TRIGGER_API_KEY" -H 'Content-Type: application/json' \
  -d '{"dominio": "comercial", "solicitado_por": "fulano@alles"}'
# -> {"execucao_id": 42, "status": "rodando", "alvo": "dominio:comercial"}
```
Acompanhe em `GET /execucoes/{id}` (ou `ouro.controle_execucoes_manuais`).

**Fiação no Oryon (frontend → backend → API):** o botão na tela chama o módulo
`dw` do backend do Oryon, que repassa o `dominio` da tela para este
`POST /cargas/rodar`. O mapa tela→domínio vive no Oryon (ex.: tela de Faturamento
→ `comercial`). O DW não precisa saber de telas — só de domínios.

---

## 4. Comandos úteis (cheat sheet)

```bash
# estado das cargas
docker exec alles_dw_postgres psql -U alles -d alles_dw -c "select * from ouro.vw_saude_cargas;"

# plano de extracao (nao executa)
.venv/bin/python -m extracao.carga --listar

# ciclo completo manual (igual ao systemd)
infra/scripts/rodar_pipeline.sh

# refresh de um dominio / uma tela
dotenv -f .env run -- transformacao/../.venv/bin/dbt build --select +path:models/ouro/<dominio>

# backup / restore
infra/scripts/backup_dw.sh
gunzip -c backups/alles_dw_*.sql.gz | docker exec -i alles_dw_postgres psql -U alles -d alles_dw

# logs / systemd (na VM)
journalctl -u alles-dw-pipeline.service -f
systemctl list-timers 'alles-dw-*'
```
