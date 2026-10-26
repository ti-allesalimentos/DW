"""Conexoes com as duas pontas: Protheus (origem) e Postgres (destino)."""
import codecs
import os

from dotenv import load_dotenv
from pytds import collate as _collate
from sqlalchemy import URL, create_engine
from sqlalchemy.engine import Engine

load_dotenv()


def _decodificacao_tolerante() -> None:
    """Faz o pytds decodificar varchar de forma tolerante, como o pyodbc fazia.

    Os campos de auditoria do Protheus (*_USERGI / *_USERGA) guardam bytes
    ofuscados, entre eles valores que nao existem na tabela cp1252 (ex.: 0x81). O
    pytds decodifica em modo estrito: o UnicodeDecodeError estoura no MEIO do
    fluxo TDS, o fluxo fica desalinhado e a carga morre com `InterfaceError:
    Invalid TDS marker` (derrubou 19 fontes na primeira carga na VM).

    Cada byte indefinido vira o ponto de codigo de mesmo valor (0x81 -> U+0081),
    exatamente o que o pyodbc/ODBC devolvia. O bronze segue sendo espelho sem
    perda, em vez de trocar por U+FFFD.

    Mexe em API interna do pytds (Collation.get_codec): por isso o python-tds
    esta fixado em 1.17.x no requirements.txt.
    """
    if getattr(_collate.Collation, "_alles_tolerante", False):
        return

    def _byte_para_codepoint(exc):
        if isinstance(exc, UnicodeDecodeError):
            ruim = exc.object[exc.start:exc.end]
            return "".join(chr(b) for b in ruim), exc.end
        raise exc

    codecs.register_error("protheus_codepoint", _byte_para_codepoint)
    original = _collate.Collation.get_codec

    def get_codec(self):
        base = original(self)
        return codecs.CodecInfo(
            encode=base.encode,
            decode=lambda dados, errors="strict": base.decode(dados, "protheus_codepoint"),
            incrementalencoder=base.incrementalencoder,
            incrementaldecoder=lambda errors="strict": base.incrementaldecoder("protheus_codepoint"),
            streamreader=base.streamreader,
            streamwriter=base.streamwriter,
            name=base.name,
        )

    _collate.Collation.get_codec = get_codec
    _collate.Collation._alles_tolerante = True


_decodificacao_tolerante()


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
