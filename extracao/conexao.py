"""Conexoes com as duas pontas: Protheus (origem) e Postgres (destino)."""
import os

from dotenv import load_dotenv
from sqlalchemy import URL, create_engine
from sqlalchemy.engine import Engine

load_dotenv()


def protheus() -> Engine:
    """SQL Server do Protheus. Usuario somente leitura.

    Usa o dialeto mssql+pytds (driver python-tds, puro Python) — nao exige
    nenhum ODBC Driver instalado na maquina, o que torna o deploy na VM e a
    portabilidade entre maquinas muito mais simples.
    """
    url = URL.create(
        "mssql+pytds",
        username=os.environ["PROTHEUS_USER"],
        password=os.environ["PROTHEUS_PASSWORD"],
        host=os.environ["PROTHEUS_HOST"],
        port=int(os.getenv("PROTHEUS_PORT", "1433")),
        database=os.environ["PROTHEUS_DB"],
    )
    # pool_pre_ping evita erro em conexao ociosa durante cargas longas.
    return create_engine(url, pool_pre_ping=True)


def postgres() -> Engine:
    """Data warehouse."""
    usuario = os.environ["POSTGRES_USER"]
    senha = os.environ["POSTGRES_PASSWORD"]
    host = os.getenv("POSTGRES_HOST", "localhost")
    porta = os.getenv("POSTGRES_PORT", "5433")
    base = os.environ["POSTGRES_DB"]
    return create_engine(
        f"postgresql+psycopg2://{usuario}:{senha}@{host}:{porta}/{base}",
        pool_pre_ping=True,
    )
