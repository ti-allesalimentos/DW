#!/usr/bin/env bash
# =====================================================================
# Chamado pelo systemd via OnFailure= quando o alles-dw-pipeline.service
# termina com erro. Recebe o nome da unit que falhou como $1.
#
# Sempre registra o alerta no log e no journal (journalctl -p err). Se
# houver SMTP configurado no .env (SMTP_HOST + ALERTA_EMAIL_TO), tambem
# envia e-mail — usando o smtplib do Python do venv, sem dependencia nova.
# =====================================================================
set -uo pipefail

UNIT="${1:-desconhecida}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_FILE="$PROJECT_DIR/logs/pipeline.log"
ENV_FILE="$PROJECT_DIR/.env"
PY="$PROJECT_DIR/.venv/bin/python"

QUANDO="$(date '+%Y-%m-%d %H:%M:%S')"
MSG="ALERTA: $UNIT falhou em $QUANDO. Ver: journalctl -u $UNIT -n 100 --no-pager"

# 1) Sempre: log + journal (nao depende de e-mail nem de rede).
echo "$MSG" | tee -a "$LOG_FILE" >&2
logger -p user.err -t alles-dw "$MSG" 2>/dev/null || true

# 2) E-mail, se configurado no .env.
le() { grep -E "^$1=" "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2-; }
SMTP_HOST="$(le SMTP_HOST)"
EMAIL_TO="$(le ALERTA_EMAIL_TO)"
if [ -n "$SMTP_HOST" ] && [ -n "$EMAIL_TO" ] && [ -x "$PY" ]; then
    CORPO="$(journalctl -u "$UNIT" -n 40 --no-pager 2>/dev/null || tail -n 40 "$LOG_FILE" 2>/dev/null)"
    ASSUNTO="[Alles DW] Falha no pipeline — $UNIT ($QUANDO)"
    MSG="$MSG" ASSUNTO="$ASSUNTO" CORPO="$CORPO" ENV_FILE="$ENV_FILE" "$PY" - <<'PY' 2>>"$LOG_FILE" \
        || echo "$(date '+%Y-%m-%d %H:%M:%S') [alertar_falha] envio de e-mail falhou (ver acima)" >>"$LOG_FILE"
import os, smtplib, ssl
from email.message import EmailMessage

env = {}
for ln in open(os.environ["ENV_FILE"]):
    ln = ln.strip()
    if ln and not ln.startswith("#") and "=" in ln:
        k, v = ln.split("=", 1)
        env[k] = v

host = env["SMTP_HOST"]
port = int(env.get("SMTP_PORT", "587"))
user = env.get("SMTP_USER", "")
pw = env.get("SMTP_PASSWORD", "")
frm = env.get("ALERTA_EMAIL_FROM", user or "alles-dw@localhost")
to = [e.strip() for e in env["ALERTA_EMAIL_TO"].split(",") if e.strip()]

m = EmailMessage()
m["Subject"] = os.environ["ASSUNTO"]
m["From"] = frm
m["To"] = ", ".join(to)
m.set_content(os.environ["MSG"] + "\n\n--- ultimas linhas do journal ---\n" + os.environ.get("CORPO", ""))

ctx = ssl.create_default_context()
if port == 465:
    with smtplib.SMTP_SSL(host, port, context=ctx, timeout=30) as s:
        if user:
            s.login(user, pw)
        s.send_message(m)
else:
    with smtplib.SMTP(host, port, timeout=30) as s:
        s.ehlo()
        try:
            s.starttls(context=ctx)
            s.ehlo()
        except smtplib.SMTPException:
            pass  # servidor sem STARTTLS (ex.: relay interno)
        if user:
            s.login(user, pw)
        s.send_message(m)
print("e-mail de alerta enviado para " + ", ".join(to))
PY
fi
