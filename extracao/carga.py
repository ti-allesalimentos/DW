"""Extracao incremental do Protheus para a camada bronze.

Principio: o bronze e um espelho fiel das tabelas de origem. Nao filtra
CFOP, nao exclui nota, nao converte unidade, nao aplica TRIM e nao faz
join — inclusive porque um INNER JOIN e uma decisao de negocio disfarcada
(descarta silenciosamente linhas sem correspondencia). Toda regra vive na
camada prata, em SQL versionado.

Cada tabela do Protheus e extraida UMA vez e serve a todos os dominios.

Uso:
    python -m extracao.carga                      # todas as fontes, incremental
    python -m extracao.carga --fonte SD2010       # uma fonte
    python -m extracao.carga --carga-inicial      # historico completo, por lotes anuais
    python -m extracao.carga --listar             # so mostra o plano, nao executa
"""
from __future__ import annotations

import argparse
import os
import sys
import traceback
from datetime import date
from pathlib import Path

import pandas as pd
import yaml
from dotenv import load_dotenv
from sqlalchemy import text
from sqlalchemy.engine import Engine

from extracao import conexao, watermark

load_dotenv()

RAIZ = Path(__file__).resolve().parent
CONFIG = RAIZ / "fontes.yml"

JANELA_PADRAO = int(os.getenv("JANELA_MOVEL_DIAS", "45"))
INICIO_PROTHEUS = date.fromisoformat(os.getenv("DATA_INICIO_PROTHEUS", "2025-02-01"))
TAMANHO_LOTE = 50_000


def carregar_config() -> list[dict]:
    with open(CONFIG, encoding="utf-8") as arquivo:
        return yaml.safe_load(arquivo)["fontes"]


def montar_sql(fonte: dict, de: date | None, ate: date | None) -> str:
    """SELECT sobre a tabela de origem, sem nenhuma regra de negocio.

    `colunas: '*'` e o padrao — pouso fiel, e traz de graca os campos
    customizados (_X_) que a Alles criou. Uma lista explicita so deve ser
    usada quando a largura da tabela justificar.
    """
    colunas = fonte.get("colunas", "*")
    if isinstance(colunas, list):
        colunas = ", ".join(colunas)
    sql = f"SELECT {colunas} FROM {fonte['tabela']}"
    coluna_data = fonte.get("coluna_watermark")
    if coluna_data and de and ate:
        # Datas no Protheus sao texto YYYYMMDD.
        sql += (f" WHERE {coluna_data} >= '{de:%Y%m%d}'"
                f" AND {coluna_data} <= '{ate:%Y%m%d}'")
    return sql


def _normalizar(df: pd.DataFrame) -> pd.DataFrame:
    """Ajuste minimo e puramente tecnico: nomes de coluna em minusculo.

    Nenhum valor e alterado — TRIM, cast e tratamento de sentinela sao
    responsabilidade da prata.
    """
    df.columns = [c.strip().lower() for c in df.columns]
    df["_carregado_em"] = pd.Timestamp.now(tz="UTC")
    return df


def _garantir_tabela(cx, schema: str, tabela: str, staging: str, chave: str) -> None:
    """Cria a tabela definitiva (espelhando o staging) e a PK, se faltarem.

    Fazer isso aqui — e nao num DDL fixo — deixa o bronze acompanhar a
    evolucao do schema do Protheus sem manutencao manual.
    """
    cx.execute(text(f"""
        CREATE TABLE IF NOT EXISTS {schema}.{tabela}
        (LIKE {schema}.{staging} INCLUDING DEFAULTS)
    """))
    tem_pk = cx.execute(text("""
        SELECT 1 FROM pg_constraint c
        JOIN pg_class t ON t.oid = c.conrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE n.nspname = :schema AND t.relname = :tabela AND c.contype = 'p'
    """), {"schema": schema, "tabela": tabela}).scalar()
    if not tem_pk:
        cx.execute(text(
            f'ALTER TABLE {schema}.{tabela} ADD PRIMARY KEY ("{chave}")'))

    # Colunas novas na origem (campos customizados criados depois) entram
    # sem quebrar a carga.
    existentes = {r[0] for r in cx.execute(text("""
        SELECT column_name FROM information_schema.columns
        WHERE table_schema = :schema AND table_name = :tabela
    """), {"schema": schema, "tabela": tabela})}
    novas = cx.execute(text("""
        SELECT column_name, data_type FROM information_schema.columns
        WHERE table_schema = :schema AND table_name = :staging
    """), {"schema": schema, "staging": staging})
    for coluna, tipo in novas:
        if coluna not in existentes:
            cx.execute(text(
                f'ALTER TABLE {schema}.{tabela} ADD COLUMN "{coluna}" {tipo}'))
            print(f"    coluna nova em {tabela}: {coluna} ({tipo})")


def _gravar(pg: Engine, df: pd.DataFrame, destino: str, chave: str) -> int:
    """Grava em staging e faz MERGE na tabela definitiva do bronze.

    O MERGE roda em transacao unica: falha no meio nao deixa bronze parcial,
    e rodar duas vezes seguidas produz exatamente o mesmo resultado.
    """
    schema, tabela = destino.split(".")
    staging = f"{tabela}__staging"

    df.to_sql(staging, pg, schema=schema, if_exists="replace",
              index=False, chunksize=TAMANHO_LOTE, method="multi")

    colunas = list(df.columns)
    lista = ", ".join(f'"{c}"' for c in colunas)
    atualiza = ", ".join(f'"{c}" = EXCLUDED."{c}"' for c in colunas if c != chave)

    with pg.begin() as cx:
        _garantir_tabela(cx, schema, tabela, staging, chave)
        resultado = cx.execute(text(f"""
            INSERT INTO {schema}.{tabela} ({lista})
            SELECT {lista} FROM {schema}.{staging}
            ON CONFLICT ("{chave}") DO UPDATE SET {atualiza}
        """))
        cx.execute(text(f"DROP TABLE IF EXISTS {schema}.{staging}"))
    return resultado.rowcount or len(df)


def extrair(fonte: dict, *, modo: str, de: date | None, ate: date | None,
            pr: Engine, pg: Engine) -> None:
    nome = fonte["nome"]
    execucao = watermark.abrir(pg, nome, modo, de, ate)
    try:
        sql = montar_sql(fonte, de, ate)
        print(f"  [{nome}] lendo do Protheus...", flush=True)
        df = pd.read_sql(sql, pr)
        lidas = len(df)
        if lidas == 0:
            print(f"  [{nome}] nada a gravar.")
            watermark.fechar(pg, execucao, lidas=0, gravadas=0)
            return
        df = _normalizar(df)
        gravadas = _gravar(pg, df, fonte["destino"], fonte["chave"].lower())
        watermark.fechar(pg, execucao, lidas=lidas, gravadas=gravadas)
        print(f"  [{nome}] {lidas:,} lidas / {gravadas:,} gravadas.")
    except Exception:
        watermark.falhar(pg, execucao, traceback.format_exc())
        raise


def main() -> int:
    ap = argparse.ArgumentParser(description="Extracao Protheus -> bronze")
    ap.add_argument("--fonte", help="extrai apenas esta fonte (nome do fontes.yml)")
    ap.add_argument("--carga-inicial", action="store_true",
                    help="historico completo, em lotes anuais")
    ap.add_argument("--listar", action="store_true",
                    help="mostra o plano de execucao sem tocar em nada")
    args = ap.parse_args()

    fontes = carregar_config()
    if args.fonte:
        fontes = [f for f in fontes if f["nome"] == args.fonte]
        if not fontes:
            print(f"Fonte '{args.fonte}' nao existe em {CONFIG.name}.")
            return 1

    if args.listar:
        for f in fontes:
            tipo = "incremental" if f.get("coluna_watermark") else "full"
            print(f"{f['nome']:12s} -> {f['destino']:28s} ({tipo}, chave {f['chave']})")
        return 0

    pr, pg = conexao.protheus(), conexao.postgres()
    hoje = date.today()

    for fonte in fontes:
        nome = fonte["nome"]
        print(f"[{nome}] iniciando.")
        if not fonte.get("coluna_watermark"):
            extrair(fonte, modo="full", de=None, ate=None, pr=pr, pg=pg)
            continue

        if args.carga_inicial:
            # Lote anual: a operacao mais pesada do projeto. Medir cada lote
            # antes de seguir para o proximo (ver docs/execucao.md).
            for ano in range(INICIO_PROTHEUS.year, hoje.year + 1):
                de = max(date(ano, 1, 1), INICIO_PROTHEUS)
                ate = min(date(ano, 12, 31), hoje)
                if de > ate:
                    continue
                print(f"  lote {ano}: {de} a {ate}")
                extrair(fonte, modo="carga_inicial", de=de, ate=ate, pr=pr, pg=pg)
        else:
            de, ate = watermark.janela(
                pg, nome, fonte.get("janela_movel_dias", JANELA_PADRAO),
                INICIO_PROTHEUS, hoje)
            print(f"  janela: {de} a {ate}")
            extrair(fonte, modo="incremental", de=de, ate=ate, pr=pr, pg=pg)

    return 0


if __name__ == "__main__":
    sys.exit(main())
