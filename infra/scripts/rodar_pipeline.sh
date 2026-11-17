#!/usr/bin/env bash
# =====================================================================
# Roda o ciclo completo do DW: extracao incremental -> dbt build.
# Pensado pra rodar sob o systemd (alles-dw-pipeline.service), mas roda
# igual num terminal comum pra teste manual.
#
# Nao decide nada sozinho: se a extracao falhar, para antes do dbt --
# nao faz sentido transformar um bronze que nao terminou de carregar.
# =====================================================================
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/pipeline.log"
mkdir -p "$LOG_DIR"

log() {
    printf '%s [rodar_pipeline] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" | tee -a "$LOG_FILE"
}

CICLO_ID=""
CICLO_STATUS="erro"
# Sinaliza o ciclo em ouro.controle_ciclos (best effort: nunca derruba o pipeline).
registrar_ciclo() { (cd "$PROJECT_DIR" && python -m extracao.ciclo "$@") 2>/dev/null || true; }
encerrar_ciclo() { [ -n "$CICLO_ID" ] && registrar_ciclo fim "$CICLO_ID" "$CICLO_STATUS"; }
trap encerrar_ciclo EXIT

falhar() {
    log "FALHA: $1"
    # OnFailure= do systemd cuida do alerta (ver alles-dw-pipeline.service);
    # aqui so garantimos que a falha fica registrada e o exit code e != 0.
    exit 1
}

cd "$PROJECT_DIR" || { echo "nao encontrou PROJECT_DIR=$PROJECT_DIR"; exit 1; }

log "===== ciclo iniciado ====="

source .venv/bin/activate 2>/dev/null || source .venv/Scripts/activate 2>/dev/null \
    || falhar "nao encontrou o virtualenv em .venv (rode 'python -m venv .venv' e instale requirements.txt)"

# Trava compartilhada com a trigger_api (flock): ciclo e execucao manual nunca rodam juntos.
# Se uma execucao manual esta em andamento, espera ate 30 min (elas levam poucos minutos); depois desiste.
mkdir -p "$LOG_DIR"
exec 9>>"$LOG_DIR/.execucao.lock"
if ! flock -n 9; then
    log "outra execucao do DW esta em andamento; aguardando ate 30 min pela trava..."
    flock -w 1800 9 || falhar "trava ocupada por mais de 30 min — ciclo nao executado (a proxima rodada tenta de novo)"
fi

# systemd define INVOCATION_ID em toda unidade; fora dele, e execucao manual.
if [ -n "${INVOCATION_ID:-}" ]; then ORIGEM="systemd"; else ORIGEM="terminal:$(id -un)"; fi
CICLO_ID="$(registrar_ciclo inicio "$ORIGEM")"

log "extracao incremental..."
if ! python -m extracao.carga >>"$LOG_FILE" 2>&1; then
    falhar "extracao incremental terminou com erro — ver $LOG_FILE e ouro.controle_cargas (status='erro')"
fi
log "extracao ok."

log "dbt build..."
[ -n "$CICLO_ID" ] && registrar_ciclo etapa "$CICLO_ID" dbt
cd transformacao || falhar "pasta transformacao/ nao encontrada"
export DBT_PROFILES_DIR=.
dotenv -f ../.env run -- dbt build >>"$LOG_FILE" 2>&1
DBT_RC=$?
[ -n "$CICLO_ID" ] && registrar_ciclo resultado "$CICLO_ID"   # grava PASS/WARN/ERROR do build, mesmo se falhou
if [ "$DBT_RC" -ne 0 ]; then
    falhar "dbt build terminou com erro — ver $LOG_FILE"
fi
log "dbt build ok."

CICLO_STATUS="sucesso"
log "===== ciclo concluido com sucesso ====="
