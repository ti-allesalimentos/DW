"""Registra o ciclo automatico em ouro.controle_ciclos (chamado pelo rodar_pipeline.sh).

    python -m extracao.ciclo inicio <origem>   -> imprime o id do ciclo ('systemd' ou 'terminal:<usuario>')
    python -m extracao.ciclo etapa <id> dbt
    python -m extracao.ciclo resultado <id>    (le transformacao/target/run_results.json)
    python -m extracao.ciclo fim <id> sucesso|erro

Best effort: o registro serve so de sinalizacao, entao qualquer falha aqui
e silenciada (exit 0) e nunca derruba o pipeline.
"""
import json
import sys
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import text

from extracao import conexao

load_dotenv()

RUN_RESULTS = Path(__file__).resolve().parents[1] / "transformacao" / "target" / "run_results.json"


def _resumo_dbt() -> dict:
    cont = {"dbt_ok": 0, "dbt_aviso": 0, "dbt_erro": 0, "dbt_ignorado": 0}
    problemas = []
    for r in json.loads(RUN_RESULTS.read_text())["results"]:
        st = r["status"]
        if st in ("pass", "success"):
            cont["dbt_ok"] += 1
        elif st == "warn":
            cont["dbt_aviso"] += 1
        elif st in ("error", "fail"):
            cont["dbt_erro"] += 1
        else:
            cont["dbt_ignorado"] += 1
        if st in ("warn", "error", "fail"):
            problemas.append({"no": r["unique_id"], "status": st, "mensagem": (r.get("message") or "")[:300]})
    return {**cont, "dbt_problemas": json.dumps(problemas)}


def main(args: list[str]) -> None:
    engine = conexao.postgres()
    with engine.begin() as conn:
        if args[0] == "inicio":
            origem = args[1] if len(args) > 1 else None
            print(conn.execute(text("INSERT INTO ouro.controle_ciclos (origem) VALUES (:o) RETURNING id"),
                               {"o": origem}).scalar_one())
        elif args[0] == "etapa":
            conn.execute(text("UPDATE ouro.controle_ciclos SET etapa = :e WHERE id = :i"), {"e": args[2], "i": int(args[1])})
        elif args[0] == "resultado":
            conn.execute(
                text("UPDATE ouro.controle_ciclos SET dbt_ok=:dbt_ok, dbt_aviso=:dbt_aviso, dbt_erro=:dbt_erro, "
                     "dbt_ignorado=:dbt_ignorado, dbt_problemas=CAST(:dbt_problemas AS jsonb) WHERE id=:i"),
                {**_resumo_dbt(), "i": int(args[1])},
            )
        elif args[0] == "fim":
            conn.execute(
                text("UPDATE ouro.controle_ciclos SET fim = now(), status = :s, "
                     "etapa = CASE WHEN :s = 'sucesso' THEN 'concluido' ELSE etapa END WHERE id = :i"),
                {"s": args[2], "i": int(args[1])},
            )


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except Exception:
        pass
