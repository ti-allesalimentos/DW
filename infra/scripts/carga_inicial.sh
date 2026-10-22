#!/usr/bin/env bash
# =====================================================================
# Carga inicial do historico: resiliente e retomavel.
#
# O extrator (`python -m extracao.carga`) PARA na primeira fonte que falha
# (registra o erro em ouro.controle_cargas e relanca a excecao). Numa carga
# de varias horas isso deixaria o resto sem carregar por causa de um unico
# timeout de rede. Este runner chama o extrator UMA fonte por vez, segue
# adiante quando uma falha e lista as que falharam no fim.
#
# Retomavel: pula as fontes que ja tem carga com sucesso cobrindo o ano
# corrente (ouro.controle_cargas). Rodar de novo so refaz o que faltou. As
# cargas sao MERGE idempotente, entao repetir uma fonte nao duplica nada.
#
# Uso:
#   infra/scripts/carga_inicial.sh                  # todas as fontes
#   infra/scripts/carga_inicial.sh SD2010 SE1010    # so estas
#   FORCAR=1 infra/scripts/carga_inicial.sh SD2010  # ignora o "ja carregada"
#   DRY_RUN=1 infra/scripts/carga_inicial.sh        # so mostra o plano
#
# Em producao rode desacoplado do terminal SSH (a carga leva horas):
#   sudo -u alles-dw nohup infra/scripts/carga_inicial.sh >/dev/null 2>&1 &
#   tail -f logs/carga_inicial.log
#
# Codigo de saida: 0 = tudo ok; 1 = alguma fonte falhou (veja o final do log).
# =====================================================================
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_DIR" || exit 1
PY="$PROJECT_DIR/.venv/bin/python"
LOG_FILE="$PROJECT_DIR/logs/carga_inicial.log"
CONTAINER="${DW_CONTAINER:-alles_dw_postgres}"
mkdir -p "$PROJECT_DIR/logs"

# Le valores crus do .env (a conexao do extrator o carrega por conta propria).
le() { grep -E "^$1=" "$PROJECT_DIR/.env" 2>/dev/null | head -1 | cut -d= -f2-; }
PGUSER_DW="$(le POSTGRES_USER)"
PGDB_DW="$(le POSTGRES_DB)"

log() { printf '%s [carga_inicial] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" | tee -a "$LOG_FILE"; }

[ -x "$PY" ] || { echo "venv nao encontrado em $PY (rode: python3 -m venv .venv e instale requirements.txt)" >&2; exit 1; }

if [ "$#" -gt 0 ]; then
    FONTES=("$@")
else
    mapfile -t FONTES < <("$PY" -m extracao.carga --listar | awk '{print $1}')
fi
TOTAL=${#FONTES[@]}
[ "$TOTAL" -gt 0 ] || { log "nenhuma fonte encontrada (--listar vazio)"; exit 1; }

# Fonte "ja carregada" = existe carga com sucesso cobrindo o ano corrente. Nas
# fontes por data (lotes anuais) o lote do ano corrente e o ultimo a rodar, entao
# a presenca dele indica que os anteriores tambem terminaram. Nas fontes full,
# watermark_ate e a data da carga.
ja_carregada() {
    local r
    r=$(docker exec "$CONTAINER" psql -U "$PGUSER_DW" -d "$PGDB_DW" -tAc \
        "select 1 from ouro.controle_cargas where fonte='$1' and status='sucesso' \
         and (watermark_ate is null or watermark_ate >= date_trunc('year', now())::date) limit 1" 2>/dev/null)
    [ "$r" = "1" ]
}

log "inicio: $TOTAL fonte(s) | FORCAR=${FORCAR:-0} DRY_RUN=${DRY_RUN:-0}"
INICIO_GERAL=$(date +%s)
FALHAS=(); OK=0; PULADAS=0; i=0

for f in "${FONTES[@]}"; do
    i=$((i + 1))
    # O nome entra numa consulta SQL; aceita so identificadores simples.
    if ! [[ "$f" =~ ^[A-Za-z0-9_]+$ ]]; then
        log "[$i/$TOTAL] nome de fonte invalido: '$f'"; FALHAS+=("$f"); continue
    fi
    if [ "${FORCAR:-0}" != "1" ] && ja_carregada "$f"; then
        log "[$i/$TOTAL] $f ja carregada — pulando"; PULADAS=$((PULADAS + 1)); continue
    fi
    if [ "${DRY_RUN:-0}" = "1" ]; then
        log "[$i/$TOTAL] $f seria carregada"; continue
    fi

    log "[$i/$TOTAL] $f iniciando"
    t0=$(date +%s)
    if "$PY" -m extracao.carga --carga-inicial --fonte "$f" >>"$LOG_FILE" 2>&1; then
        OK=$((OK + 1)); log "[$i/$TOTAL] $f ok ($(( ($(date +%s) - t0) / 60 )) min)"
    else
        FALHAS+=("$f")
        log "[$i/$TOTAL] $f FALHOU ($(( ($(date +%s) - t0) / 60 )) min) — seguindo; detalhes acima no log e em ouro.controle_cargas"
    fi
done

log "fim em $(( ($(date +%s) - INICIO_GERAL) / 60 )) min: ok=$OK puladas=$PULADAS falhas=${#FALHAS[@]}"
if [ "${#FALHAS[@]}" -gt 0 ]; then
    log "FALHARAM: ${FALHAS[*]}"
    log "para refazer so as que falharam: infra/scripts/carga_inicial.sh ${FALHAS[*]}"
    exit 1
fi
exit 0
