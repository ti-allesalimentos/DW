"""Confere, fonte a fonte, a contagem do Protheus contra a do bronze.

O "ok" do extrator so diz que ele leu e gravou sem erro; nao prova que a carga
esta COMPLETA. Este script compara, para cada fonte do fontes.yml, quantas
linhas o Protheus tem hoje com quantas linhas ATIVAS (_deletado = false) o
bronze tem, no mesmo recorte que o extrator le:

  - fonte cheia ou por S_T_A_M_P_ ......... a tabela inteira
  - fonte por data (YYYYMMDD) ............. de DATA_INICIO_PROTHEUS ate hoje

Uso (na raiz do projeto, com o venv):
    .venv/bin/python infra/scripts/conferir_carga.py                 # todas as fontes
    .venv/bin/python infra/scripts/conferir_carga.py --fonte SD2010  # so estas (repetivel)

Somente leitura. No Protheus faz um COUNT(*) por fonte com NOLOCK (nao bloqueia
nem espera o ERP; para contagem, a leitura suja e aceitavel). Rode fora do pico
se puder: nas tabelas grandes por data o COUNT varre a tabela.

Como ler a coluna STATUS (dif = bronze - protheus):
  OK           contagens iguais.
  DIF PEQUENA  diferenca de ate 1%. Esperado em tabela viva: o Protheus recebeu
               linhas depois da carga e o proximo ciclo incremental as traz.
  DIVERGE      diferenca acima de 1%. Investigar (carga incompleta ou linhas
               apagadas fisicamente na origem).
  ERRO         nao foi possivel contar (tabela ausente no bronze, falha de rede...).

Codigo de saida: 0 se nao houver DIVERGE nem ERRO; 1 caso contrario.
"""
import argparse
import sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from sqlalchemy import text  # noqa: E402

from extracao import conexao  # noqa: E402
from extracao.carga import INICIO_PROTHEUS, carregar_config  # noqa: E402

TOLERANCIA = 0.01  # 1%


def _recorte(fonte: dict, hoje: date) -> tuple[str, str, str]:
    """(where no Protheus, where no bronze, rotulo) — o mesmo recorte do extrator."""
    col = fonte.get("coluna_watermark")
    if not col or fonte.get("tipo_watermark") == "timestamp":
        return "", "", "tabela inteira"
    ini, fim = f"{INICIO_PROTHEUS:%Y%m%d}", f"{hoje:%Y%m%d}"
    return (
        f" WHERE {col} >= '{ini}' AND {col} <= '{fim}'",
        f' WHERE "{col.lower()}" >= \'{ini}\' AND "{col.lower()}" <= \'{fim}\'',
        f"{INICIO_PROTHEUS:%d/%m/%Y} em diante",
    )


def _status(bronze: int, protheus: int) -> str:
    dif = bronze - protheus
    if dif == 0:
        return "OK"
    if abs(dif) / max(protheus, 1) <= TOLERANCIA:
        return "DIF PEQUENA"
    return "DIVERGE"


def main() -> int:
    ap = argparse.ArgumentParser(description="Confere contagem Protheus x bronze")
    ap.add_argument("--fonte", action="append", help="so esta(s) fonte(s); repetivel")
    args = ap.parse_args()

    fontes = carregar_config()
    if args.fonte:
        pedidas = set(args.fonte)
        faltando = pedidas - {f["nome"] for f in fontes}
        if faltando:
            print(f"Fonte(s) inexistente(s): {', '.join(sorted(faltando))}")
            return 1
        fontes = [f for f in fontes if f["nome"] in pedidas]

    hoje = date.today()
    pr, pg = conexao.protheus(), conexao.postgres()
    linhas, resumo = [], {}

    for f in fontes:
        nome = f["nome"]
        where_pr, where_pg, rotulo = _recorte(f, hoje)
        try:
            with pr.connect() as c:
                protheus = c.execute(text(
                    f"SELECT COUNT(*) FROM {f['tabela']} WITH (NOLOCK){where_pr}")).scalar()
            with pg.connect() as c:
                ativas, apagadas = c.execute(text(
                    f'SELECT count(*) FILTER (WHERE NOT "_deletado"), '
                    f'count(*) FILTER (WHERE "_deletado") FROM {f["destino"]}{where_pg}')).one()
            status = _status(ativas, protheus)
            linhas.append((nome, rotulo, protheus, ativas, ativas - protheus, apagadas, status))
        except Exception as exc:  # noqa: BLE001 - queremos o motivo de cada fonte
            motivo = str(exc).strip().splitlines()[0][:70] if str(exc).strip() else type(exc).__name__
            linhas.append((nome, rotulo, None, None, None, None, f"ERRO: {motivo}"))
            status = "ERRO"
        resumo[status] = resumo.get(status, 0) + 1

    print(f"{'FONTE':<9} {'RECORTE':<22} {'PROTHEUS':>11} {'BRONZE':>11} {'DIF':>8} {'_DELET':>7}  STATUS")
    for nome, rotulo, p, b, d, a, st in linhas:
        if p is None:
            print(f"{nome:<9} {rotulo:<22} {'-':>11} {'-':>11} {'-':>8} {'-':>7}  {st}")
        else:
            print(f"{nome:<9} {rotulo:<22} {p:>11,} {b:>11,} {d:>+8,} {a:>7,}  {st}")

    print()
    print("RESUMO: " + " | ".join(f"{k}={v}" for k, v in sorted(resumo.items())))
    problema = any(k == "DIVERGE" or k == "ERRO" for k in resumo)
    return 1 if problema else 0


if __name__ == "__main__":
    raise SystemExit(main())
