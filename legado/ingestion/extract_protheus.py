"""
Extração do Protheus (SQL Server) para a camada raw do Postgres.

Fase de ingestão. Rode DEPOIS que o Postgres estiver de pé e o
sql/01_modelo_faturamento.sql já tiver criado os schemas.

Uso:
    python ingestion/extract_protheus.py
"""
import os
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine

load_dotenv()


def _protheus_engine():
    """Conexão com o Protheus (SQL Server). Requer ODBC Driver 18."""
    host = os.getenv("PROTHEUS_HOST")
    port = os.getenv("PROTHEUS_PORT", "1433")
    db = os.getenv("PROTHEUS_DB")
    user = os.getenv("PROTHEUS_USER")
    pwd = os.getenv("PROTHEUS_PASSWORD")
    url = (
        f"mssql+pyodbc://{user}:{pwd}@{host}:{port}/{db}"
        "?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes"
    )
    return create_engine(url)


def _postgres_engine():
    """Conexão com o data warehouse (Postgres)."""
    host = os.getenv("POSTGRES_HOST", "localhost")
    port = os.getenv("POSTGRES_PORT", "5432")
    db = os.getenv("POSTGRES_DB")
    user = os.getenv("POSTGRES_USER")
    pwd = os.getenv("POSTGRES_PASSWORD")
    return create_engine(f"postgresql+psycopg2://{user}:{pwd}@{host}:{port}/{db}")


def extrair(dominio: str, query_path: str, tabela_destino: str) -> None:
    sql = Path(query_path).read_text(encoding="utf-8")
    print(f"[{dominio}] lendo do Protheus...")
    df = pd.read_sql(sql, _protheus_engine())
    print(f"[{dominio}] {len(df):,} linhas lidas. Gravando em {tabela_destino}...")
    schema, table = tabela_destino.split(".")
    df.to_sql(table, _postgres_engine(), schema=schema,
              if_exists="replace", index=False)
    print(f"[{dominio}] concluído.")


# Domínios extraídos do Protheus para a camada raw (bronze).
# Cada query vive em ingestion/queries/ e é o SQL nativo validado contra o SGBD.
# As tratativas (renome, chave_cliente, join estado->região, conversão -CX)
# ficam para a camada dw, não aqui: raw é o pouso fiel do extrato.
DOMINIOS = [
    ("faturamento", "ingestion/queries/faturamento.sql", "raw.faturamento"),
    ("produtos",    "ingestion/queries/produtos.sql",    "raw.produtos"),
    ("clientes",    "ingestion/queries/clientes.sql",    "raw.clientes"),
    ("vendedores",  "ingestion/queries/vendedores.sql",  "raw.vendedores"),
    # Fatos comerciais adicionais (espelho das abas da fFaturamento.xlsx).
    # A conversão -CX fica EMBUTIDA em cada query (cada uma tem sua lista).
    ("devolucoes",           "ingestion/queries/devolucoes.sql",           "raw.devolucoes"),
    ("bonificacao",          "ingestion/queries/bonificacao.sql",          "raw.bonificacao"),
    ("refaturamento",        "ingestion/queries/refaturamento.sql",        "raw.refaturamento"),
    ("rem_industrializacao", "ingestion/queries/rem_industrializacao.sql", "raw.rem_industrializacao"),
    ("rem_triangular",       "ingestion/queries/rem_triangular.sql",       "raw.rem_triangular"),
    ("acordo_comercial",     "ingestion/queries/acordo_comercial.sql",     "raw.acordo_comercial"),
    ("coopeval_remessa",     "ingestion/queries/coopeval_remessa.sql",     "raw.coopeval_remessa"),
]


if __name__ == "__main__":
    for dominio, query_path, tabela_destino in DOMINIOS:
        extrair(dominio, query_path, tabela_destino)
