"""Testa as duas pontas do DW a partir do .env: Protheus (origem) e Postgres (destino).

Uso (na raiz do projeto, com o venv):
    .venv/bin/python infra/scripts/testar_conexoes.py

So faz SELECT de leitura e nunca imprime credenciais. Cada ponta e testada
separadamente, entao uma falha no Protheus nao esconde o resultado do Postgres.
Codigo de saida 0 = as duas OK; 1 = alguma falhou.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from sqlalchemy import text  # noqa: E402

from extracao import conexao  # noqa: E402


def testar(nome: str, abrir, consulta: str) -> bool:
    try:
        with abrir().connect() as c:
            valor = c.execute(text(consulta)).scalar()
        print(f"[OK]    {nome}: {valor}")
        return True
    except Exception as exc:  # noqa: BLE001 - queremos o motivo, qualquer que seja
        # So o tipo e a primeira linha: o texto completo do driver pode ecoar host/usuario.
        primeira_linha = str(exc).strip().splitlines()[0][:160]
        print(f"[FALHA] {nome}: {type(exc).__name__}: {primeira_linha}")
        return False


def main() -> int:
    ok_protheus = testar(
        "Protheus (SA4010, transportadoras ativas)",
        conexao.protheus,
        "select count(*) from SA4010 where D_E_L_E_T_ <> '*'",
    )
    ok_postgres = testar(
        "Postgres DW (versao)",
        conexao.postgres,
        "select split_part(version(), ' ', 2)",
    )
    return 0 if (ok_protheus and ok_postgres) else 1


if __name__ == "__main__":
    raise SystemExit(main())
