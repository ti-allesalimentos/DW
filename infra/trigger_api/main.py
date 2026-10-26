"""API interna de trigger — dispara extracao + dbt build sob demanda.

Existe pra um consumidor (hoje: o modulo `dw` do Oryon) poder rodar uma
carga fora do ciclo automatico do systemd (a cada 2h), sem SSH, com o
mesmo historico que ja existe em `ouro.controle_cargas`.

Nao inventa um mecanismo de log novo por fonte — so acrescenta
`ouro.controle_execucoes_manuais` pra rastrear a EXECUCAO como um todo
(extracao de uma ou mais fontes + o `dbt build` que vem junto), porque
uma execucao manual pode ser maior do que uma linha de `controle_cargas`.

So aceita fontes de `extracao/fontes.yml` (nunca comando livre) e exige
`X-API-Key` em toda rota, exceto `/health`.

Uso (dev):
    uvicorn infra.trigger_api.main:app --host 127.0.0.1 --port 8090

Em producao roda via `infra/systemd/alles-dw-trigger-api.service`.
"""
from __future__ import annotations

import os
import secrets
import subprocess
import sys
import threading
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from dotenv import load_dotenv
from fastapi import Depends, FastAPI, Header, HTTPException
from pydantic import BaseModel
from sqlalchemy import text

from extracao import conexao
from extracao.carga import carregar_config

load_dotenv()

PROJECT_DIR = Path(__file__).resolve().parents[2]
LOG_DIR = PROJECT_DIR / "logs"
LOG_DIR.mkdir(exist_ok=True)

# dbt-core nao tem `python -m dbt` (sem __main__.py) — o executavel do
# console-script mora do lado do python do mesmo venv.
DBT_BIN = Path(sys.executable).parent / ("dbt.exe" if os.name == "nt" else "dbt")
TRANSFORMACAO_DIR = PROJECT_DIR / "transformacao"

# Dominios = assuntos/dashboards do Board. Cada um refresca com um `dbt --select`
# pela pasta de modelos (ver docs/operacao_warehouse.md). As FONTES de cada
# dominio nao sao mantidas a mao: sao derivadas do grafo do dbt
# (dbt ls --resource-type source), seguindo as dependencias reais — inclusive
# cadastros compartilhados entre dominios.
DOMINIOS: dict[str, str] = {
    "comercial":       "+path:models/ouro/comercial",
    "financeiro":      "+path:models/ouro/financeiro",
    "fiscal":          "+path:models/ouro/fiscal",
    "industrial":      "+path:models/ouro/industrial",
    "custo":           "+path:models/ouro/custo",
    "compras":         "+path:models/ouro/compras",
    "logistica":       "+path:models/ouro/logistica",
    "gestao_pessoas":  "+path:models/ouro/gestao_pessoas",
}

API_KEY = os.getenv("TRIGGER_API_KEY")

app = FastAPI(title="Alles DW — Trigger API", version="1.0")

# Lock em memoria: so vale dentro de UM processo uvicorn (--workers 1).
# E um "melhor esforco", nao um lock distribuido — combina com o resto do
# projeto (systemd/cron em vez de uma fila de verdade, ate a
# complexidade se justificar). Rodar com mais de um worker quebra essa
# garantia; documentado no service file.
_execucao_lock = threading.Lock()


def exigir_api_key(x_api_key: Optional[str] = Header(default=None)) -> None:
    if not API_KEY:
        raise HTTPException(503, "TRIGGER_API_KEY nao configurada neste ambiente")
    if not x_api_key or not secrets.compare_digest(x_api_key, API_KEY):
        raise HTTPException(401, "API key invalida ou ausente")


def nomes_fontes_validos() -> list[str]:
    return [f["nome"] for f in carregar_config()]


def fontes_do_dominio(dominio: str) -> list[str]:
    """Fontes (nomes do fontes.yml) de que o dominio depende, via grafo do dbt.

    Roda `dbt ls --select <select> --resource-type source` e mapeia cada
    `bronze.<tabela>` para o nome do fontes.yml (= tabela em maiusculo),
    mantendo so as que existem la.
    """
    select = DOMINIOS[dominio]
    res = subprocess.run(
        [str(DBT_BIN), "ls", "--select", select,
         "--resource-type", "source", "--output", "name"],
        cwd=TRANSFORMACAO_DIR,
        env={**os.environ.copy(), "DBT_PROFILES_DIR": "."},
        capture_output=True, text=True,
    )
    validas = set(nomes_fontes_validos())
    achadas = set()
    for linha in res.stdout.splitlines():
        linha = linha.strip()
        if linha.startswith("bronze."):
            nome = linha.split(".", 1)[1].upper()   # bronze.sd2010 -> SD2010
            if nome in validas:
                achadas.add(nome)
    return sorted(achadas)


class RodarCargaRequest(BaseModel):
    # Informe `fonte` OU `dominio` (nao os dois). Nenhum dos dois = ciclo
    # completo (todas as fontes + dbt build completo), igual ao systemd.
    fonte: Optional[str] = None       # uma fonte do fontes.yml
    dominio: Optional[str] = None     # refresh direcionado por dashboard (ver DOMINIOS)
    solicitado_por: Optional[str] = None


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/fontes", dependencies=[Depends(exigir_api_key)])
def listar_fontes():
    """Fontes conhecidas (fontes.yml) + status da ultima carga de cada uma."""
    engine = conexao.postgres()
    with engine.connect() as conn:
        linhas = conn.execute(text("SELECT * FROM ouro.vw_saude_cargas")).mappings().all()
    status_por_fonte = {linha["fonte"]: dict(linha) for linha in linhas}

    resultado = []
    for f in carregar_config():
        nome = f["nome"]
        status = status_por_fonte.get(nome)
        resultado.append({
            "nome": nome,
            "tabela": f["tabela"],
            "ultima_carga": status,
        })
    return resultado


@app.get("/dominios", dependencies=[Depends(exigir_api_key)])
def listar_dominios():
    """Dominios (dashboards) que podem ser atualizados sob demanda."""
    return [{"dominio": d, "select": s} for d, s in DOMINIOS.items()]


@app.get("/execucoes", dependencies=[Depends(exigir_api_key)])
def listar_execucoes(limite: int = 20):
    limite = max(1, min(limite, 200))
    engine = conexao.postgres()
    with engine.connect() as conn:
        linhas = conn.execute(
            text(
                "SELECT * FROM ouro.controle_execucoes_manuais "
                "ORDER BY solicitado_em DESC LIMIT :limite"
            ),
            {"limite": limite},
        ).mappings().all()
    return [dict(linha) for linha in linhas]


@app.get("/execucoes/{execucao_id}", dependencies=[Depends(exigir_api_key)])
def obter_execucao(execucao_id: int):
    engine = conexao.postgres()
    with engine.connect() as conn:
        linha = conn.execute(
            text("SELECT * FROM ouro.controle_execucoes_manuais WHERE id = :id"),
            {"id": execucao_id},
        ).mappings().first()
    if not linha:
        raise HTTPException(404, "execucao nao encontrada")
    return dict(linha)


@app.post("/cargas/rodar", dependencies=[Depends(exigir_api_key)])
def rodar_carga(body: RodarCargaRequest):
    if body.fonte is not None and body.dominio is not None:
        raise HTTPException(422, "informe 'fonte' OU 'dominio', nao os dois")
    if body.fonte is not None and body.fonte not in nomes_fontes_validos():
        raise HTTPException(422, f"fonte desconhecida: {body.fonte!r}")
    if body.dominio is not None and body.dominio not in DOMINIOS:
        raise HTTPException(422, f"dominio desconhecido: {body.dominio!r}. "
                                 f"Validos: {sorted(DOMINIOS)}")

    if not _execucao_lock.acquire(blocking=False):
        raise HTTPException(409, "ja existe uma execucao manual em andamento")

    # Rotulo gravado na coluna `fonte` do controle (reaproveitada): o nome da
    # fonte, "dominio:<x>" para refresh por dashboard, ou "(todas)".
    rotulo = f"dominio:{body.dominio}" if body.dominio else body.fonte

    engine = conexao.postgres()
    try:
        with engine.begin() as conn:
            execucao_id = conn.execute(
                text(
                    "INSERT INTO ouro.controle_execucoes_manuais "
                    "(fonte, solicitado_por, etapa, status) "
                    "VALUES (:fonte, :solicitado_por, 'extracao', 'rodando') "
                    "RETURNING id"
                ),
                {"fonte": rotulo, "solicitado_por": body.solicitado_por},
            ).scalar_one()
    except Exception:
        _execucao_lock.release()
        raise

    thread = threading.Thread(
        target=_executar_em_background,
        args=(execucao_id, body.fonte, body.dominio),
        daemon=True,
    )
    thread.start()
    return {"execucao_id": execucao_id, "status": "rodando", "alvo": rotulo or "(todas)"}


def _atualizar_execucao(execucao_id: int, **campos) -> None:
    engine = conexao.postgres()
    sets = ", ".join(f"{k} = :{k}" for k in campos)
    with engine.begin() as conn:
        conn.execute(
            text(f"UPDATE ouro.controle_execucoes_manuais SET {sets} WHERE id = :id"),
            {**campos, "id": execucao_id},
        )


def _executar_em_background(execucao_id: int, fonte: Optional[str],
                            dominio: Optional[str] = None) -> None:
    log_path = LOG_DIR / f"execucao_manual_{execucao_id}.log"
    try:
        with open(log_path, "w", encoding="utf-8") as log:
            log.write(f"===== execucao {execucao_id} iniciada em {datetime.now(timezone.utc).isoformat()} =====\n")

            # Resolve o alvo: dominio (dashboard) -> fontes do grafo + dbt --select;
            # fonte -> uma fonte + build completo; nenhum -> todas + build completo.
            if dominio:
                dbt_select = DOMINIOS[dominio]
                fontes_alvo = fontes_do_dominio(dominio)
                log.write(f"dominio={dominio}  select={dbt_select}\n")
                log.write(f"fontes do dominio={', '.join(fontes_alvo) or '(nenhuma)'}\n\n")
            elif fonte:
                dbt_select = None
                fontes_alvo = [fonte]
                log.write(f"fonte={fonte}\n\n")
            else:
                dbt_select = None
                fontes_alvo = None  # todas
                log.write("fonte=(todas)\n\n")
            log.flush()

            log.write("--- extracao ---\n")
            log.flush()
            cmd_extracao = [sys.executable, "-m", "extracao.carga"]
            for f in (fontes_alvo or []):
                cmd_extracao += ["--fonte", f]
            resultado = subprocess.run(
                cmd_extracao, cwd=PROJECT_DIR, env=os.environ.copy(),
                stdout=log, stderr=subprocess.STDOUT,
            )
            if resultado.returncode != 0:
                _atualizar_execucao(
                    execucao_id, etapa="extracao", status="erro",
                    mensagem_erro=f"extracao terminou com codigo {resultado.returncode} — ver {log_path.name}",
                    concluido_em=datetime.now(timezone.utc),
                )
                return

            _atualizar_execucao(execucao_id, etapa="dbt")
            cmd_dbt = [str(DBT_BIN), "build"]
            if dbt_select:
                cmd_dbt += ["--select", dbt_select]
            log.write(f"\n--- dbt {' '.join(cmd_dbt[1:])} ---\n")
            log.flush()
            resultado = subprocess.run(
                cmd_dbt,
                cwd=PROJECT_DIR / "transformacao",
                env={**os.environ.copy(), "DBT_PROFILES_DIR": "."},
                stdout=log, stderr=subprocess.STDOUT,
            )
            if resultado.returncode != 0:
                _atualizar_execucao(
                    execucao_id, etapa="dbt", status="erro",
                    mensagem_erro=f"dbt build terminou com codigo {resultado.returncode} — ver {log_path.name}",
                    concluido_em=datetime.now(timezone.utc),
                )
                return

            log.write(f"\n===== execucao {execucao_id} concluida com sucesso =====\n")
            _atualizar_execucao(
                execucao_id, etapa="concluido", status="sucesso",
                concluido_em=datetime.now(timezone.utc),
            )
    except Exception as exc:  # nunca deixar a thread morrer silenciosa sem atualizar o status
        _atualizar_execucao(
            execucao_id, status="erro",
            mensagem_erro=f"erro inesperado no trigger: {exc}",
            concluido_em=datetime.now(timezone.utc),
        )
    finally:
        _execucao_lock.release()
