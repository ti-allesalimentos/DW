"""Watermark e registro de execucoes em ouro.controle_cargas.

O watermark de uma fonte e a maior data ja extraida com sucesso. A proxima
carga volta uma janela movel a partir dele, porque nota fiscal e cancelada,
corrigida e lancada com data retroativa — sem a janela, essas alteracoes
nunca chegariam ao bronze.
"""
from __future__ import annotations

from datetime import date, timedelta

from sqlalchemy import text
from sqlalchemy.engine import Engine


def ultimo_watermark(engine: Engine, fonte: str) -> date | None:
    """Maior data extraida com sucesso para a fonte, ou None se nunca rodou."""
    sql = text("""
        SELECT max(watermark_ate) AS ate
        FROM ouro.controle_cargas
        WHERE fonte = :fonte AND status = 'sucesso'
    """)
    with engine.connect() as conexao:
        return conexao.execute(sql, {"fonte": fonte}).scalar()


def janela(engine: Engine, fonte: str, janela_dias: int,
           inicio_padrao: date, ate: date) -> tuple[date, date]:
    """Intervalo a extrair: (watermark - janela_dias, ate).

    Na primeira execucao usa `inicio_padrao` — a data de entrada do Protheus.
    """
    marca = ultimo_watermark(engine, fonte)
    if marca is None:
        return inicio_padrao, ate
    de = marca - timedelta(days=janela_dias)
    return max(de, inicio_padrao), ate


def abrir(engine: Engine, fonte: str, modo: str,
          de: date | None, ate: date | None) -> int:
    """Registra o inicio da carga e devolve o id da execucao."""
    sql = text("""
        INSERT INTO ouro.controle_cargas (fonte, modo, watermark_de, watermark_ate, status)
        VALUES (:fonte, :modo, :de, :ate, 'rodando')
        RETURNING id
    """)
    with engine.begin() as conexao:
        return conexao.execute(
            sql, {"fonte": fonte, "modo": modo, "de": de, "ate": ate}
        ).scalar_one()


def fechar(engine: Engine, execucao_id: int, *, lidas: int, gravadas: int) -> None:
    sql = text("""
        UPDATE ouro.controle_cargas
        SET fim = now(), linhas_lidas = :lidas,
            linhas_gravadas = :gravadas, status = 'sucesso'
        WHERE id = :id
    """)
    with engine.begin() as conexao:
        conexao.execute(sql, {"id": execucao_id, "lidas": lidas, "gravadas": gravadas})


def falhar(engine: Engine, execucao_id: int, erro: str) -> None:
    sql = text("""
        UPDATE ouro.controle_cargas
        SET fim = now(), status = 'erro', mensagem_erro = :erro
        WHERE id = :id
    """)
    with engine.begin() as conexao:
        # trunca para nao estourar o campo com stack trace gigante
        conexao.execute(sql, {"id": execucao_id, "erro": erro[:4000]})
