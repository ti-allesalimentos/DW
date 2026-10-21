#!/usr/bin/env bash
# =====================================================================
# Backup do DW: pg_dump do Postgres (container alles_dw_postgres) para
# arquivo comprimido, com retencao. Rodar via systemd timer
# (alles-dw-backup.timer) ou cron. Restauravel com --clean --if-exists.
#
# Restaurar:
#   gunzip -c backups/alles_dw_AAAAMMDD_HHMMSS.sql.gz \
#     | docker exec -i alles_dw_postgres psql -U alles -d alles_dw
#
# Variaveis (opcionais, via .env ou ambiente):
#   DW_BACKUP_DIR           destino (padrao: <projeto>/backups)
#   DW_BACKUP_RETENCAO_DIAS dias a manter (padrao: 14)
# =====================================================================
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
set -a; . "$PROJECT_DIR/.env" 2>/dev/null; set +a

BACKUP_DIR="${DW_BACKUP_DIR:-$PROJECT_DIR/backups}"
RETENCAO_DIAS="${DW_BACKUP_RETENCAO_DIAS:-14}"
LOG_FILE="$PROJECT_DIR/logs/backup.log"
CONTAINER="alles_dw_postgres"
mkdir -p "$BACKUP_DIR" "$(dirname "$LOG_FILE")"

log() { printf '%s [backup_dw] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" | tee -a "$LOG_FILE"; }

TS="$(date '+%Y%m%d_%H%M%S')"
OUT="$BACKUP_DIR/alles_dw_${TS}.sql.gz"

log "iniciando pg_dump -> $OUT"
if docker exec "$CONTAINER" pg_dump -U "${POSTGRES_USER:-alles}" -d "${POSTGRES_DB:-alles_dw}" \
        --no-owner --clean --if-exists | gzip > "$OUT"; then
    log "ok ($(du -h "$OUT" | cut -f1))"
else
    log "FALHA no pg_dump — removendo arquivo parcial"
    rm -f "$OUT"
    exit 1
fi

# Retencao: remove backups mais antigos que RETENCAO_DIAS.
while IFS= read -r f; do
    log "removido (retencao): $f"
done < <(find "$BACKUP_DIR" -name 'alles_dw_*.sql.gz' -type f -mtime +"$RETENCAO_DIAS" -print -delete)

log "concluido."
