#!/usr/bin/env bash
# =====================================================================
# Chamado pelo systemd via OnFailure= quando o alles-dw-pipeline.service
# termina com erro. Recebe o nome da unit que falhou como $1.
#
# Hoje so grava um alerta bem visivel no log e no journal (jornalctl -p
# err mostra). Quando existir um canal real (e-mail, Slack), plugar
# aqui -- e so um script, sem acoplamento com o resto do pipeline.
# =====================================================================
set -uo pipefail

UNIT="${1:-desconhecida}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_FILE="$PROJECT_DIR/logs/pipeline.log"

MSG="ALERTA: $UNIT falhou em $(date '+%Y-%m-%d %H:%M:%S'). Ver: journalctl -u $UNIT -n 100 --no-pager"

echo "$MSG" | tee -a "$LOG_FILE" >&2
logger -p user.err -t alles-dw "$MSG" 2>/dev/null || true
