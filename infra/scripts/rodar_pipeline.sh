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

log "extracao incremental..."
if ! python -m extracao.carga >>"$LOG_FILE" 2>&1; then
    falhar "extracao incremental terminou com erro — ver $LOG_FILE e ouro.controle_cargas (status='erro')"
fi
log "extracao ok."

log "dbt build..."
cd transformacao || falhar "pasta transformacao/ nao encontrada"
export DBT_PROFILES_DIR=.
if ! dotenv -f ../.env run -- dbt build >>"$LOG_FILE" 2>&1; then
    falhar "dbt build terminou com erro — ver $LOG_FILE"
fi
log "dbt build ok."

log "===== ciclo concluido com sucesso ====="
