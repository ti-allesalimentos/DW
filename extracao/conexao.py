"""Conexoes com as duas pontas: Protheus (origem) e Postgres (destino)."""
import os

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.engine import Engine

load_dotenv()


def protheus() -> Engine:
    """SQL Server do Protheus. Usuario somente leitura.

    Exige o ODBC Driver 18 for SQL Server instalado na maquina.
    """
    usuario = os.environ["PROTHEUS_USER"]
    senha = os.environ["PROTHEUS_PASSWORD"]
    host = os.environ["PROTHEUS_HOST"]
    porta = os.getenv("PROTHEUS_PORT", "1433")
    base = os.environ["PROTHEUS_DB"]
    url = (
        f"mssql+pyodbc://{usuario}:{senha}@{host}:{porta}/{base}"
        "?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes"
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
