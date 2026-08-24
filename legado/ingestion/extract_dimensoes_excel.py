"""
Extração das fontes MANUAIS (que não existem no Protheus) das planilhas Excel
-> camada raw do Postgres.

IMPORTANTE: produto, cliente e vendedor NÃO vêm mais daqui — vêm do Protheus,
via ingestion/extract_protheus.py. Este script cobre só o que é genuinamente
manual: família (classificação comercial), calendário e o de-para estado->região.

Fase de transformação (dimensões). Rode DEPOIS que o Postgres estiver de pé e o
sql/01_modelo_faturamento.sql já tiver criado os schemas.

Uso:
    python ingestion/extract_dimensoes_excel.py
"""
import os

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine

load_dotenv()

BASES_DIR = os.getenv("EXCEL_BASES_DIR", r"P:\T.I\01. BASES")

RENAME_PRODUTO = {
    "_CODPRODUTO": "cod_produto",
    "_DESCPRODUTO": "descricao",
    "_TIPOPRDUTO": "tipo",
    "_UNIDADEMEDIDAPRODUTO": "um",
    "_GRUPOESTOQUE": "grupo_estoque",
    "_CONTA": "conta_contabil",
    "B1_X_AGRUP": "agrupamento",
    "Ult. Preco Comp.": "ult_preco_compra",
    "_DTAULTCOMPRA": "dt_ult_compra",
}

RENAME_FAMILIA = {
    "COD": "cod",
    "DESCRICAO": "descricao",
    "FAMILIA": "familia",
    "DESCRIÇÃO LOUSINHA": "descricao_comercial",
    "Marca": "marca",
    "Sub-Recorte": "sub_recorte",
}

RENAME_CLIENTE = {
    "_CHAVECLIENTE": "chave_cliente",
    "_PFJ": "pfj",
    "_NOMECLIENTE": "nome",
    "_NREDUZCLIENTE": "nome_reduzido",
    "_CGCCLIENTE": "cgc",
    "_ENDCLIENTE": "endereco",
    "_BAIRROCLIENTE": "bairro",
    "_MUNCLIENTE": "municipio",
    "_ESTCLIENTE": "estado",
    "_ESTCLIENTEDESCR": "estado_desc",
    "_REGIAOCLIENTE": "regiao",
    "_CONDPGTO": "cond_pgto",
    "_CONTACONTABIL": "conta_contabil",
    "_GERENTE": "gerente",
    "_CODVEND": "cod_vendedor",
    "_%COMISCLIENTE": "pct_comissao",
    "_%DESCCLIENTE": "pct_desconto",
    "_SITUACAO": "situacao",
    "CEP": "cep",
    "DTCADASTRO": "dt_cadastro",
    "_DTAULTCOMPRA": "dt_ult_compra",
}

RENAME_VENDEDOR = {
    "_CODVEND": "cod_vendedor",
    "_NOMEVEND": "nome",
    "_GERENVEND": "cod_gerente",
    "_COMISVEND": "pct_comissao",
    "_NOMEGERENTE": "nome_gerente",
    "_COMISGERENTE": "pct_comissao_gerente",
    "_ALIAS": "alias",
}

RENAME_CALENDARIO = {
    "Data": "data",
    "Ano": "ano",
    "MesNumero": "mes",
    "MesNome": "mes_nome",
    "TrimestreNumero": "trimestre",
    "DiaDoMes": "dia",
    "DiaDaSemanaNome": "dia_semana_nome",
    "DiaUtilNumero": "dia_util",
    "Feriado": "feriado",
    "AnoFiscal": "ano_fiscal",
    "MesFiscalNumero": "mes_fiscal",
}

# de-para UF -> região (aba dRegiao do fManual). O cabeçalho da tabela no Excel
# são literalmente "Coluna 1/2/3": nome do estado, sigla (UF) e região.
RENAME_REGIAO = {
    "Coluna 1": "estado_desc",
    "Coluna 2": "sigla",
    "Coluna 3": "regiao",
}

# destino da devolução (aba dDestino): sigla -> descrição.
RENAME_DESTINO = {
    "Coluna 1": "sigla",
    "Coluna 2": "descricao",
}

# motivo da devolução (aba dMotivoDev): sigla, motivo e categoria.
RENAME_MOTIVODEV = {
    "SIGLA": "sigla",
    "MOTIVO": "motivo",
    "Coluna 1": "categoria",
}

DATE_COLS = {
    "produtos": ["dt_ult_compra"],
    "clientes": ["dt_cadastro", "dt_ult_compra"],
    "calendario": ["data"],
}


def _postgres_engine():
    host = os.getenv("POSTGRES_HOST", "localhost")
    port = os.getenv("POSTGRES_PORT", "5432")
    db = os.getenv("POSTGRES_DB")
    user = os.getenv("POSTGRES_USER")
    pwd = os.getenv("POSTGRES_PASSWORD")
    return create_engine(f"postgresql+psycopg2://{user}:{pwd}@{host}:{port}/{db}")


def _limpar(df: pd.DataFrame) -> pd.DataFrame:
    for col in df.select_dtypes(include="object").columns:
        df[col] = df[col].str.strip()
    return df


def _zfill_documento(row) -> str | None:
    """CEP e CNPJ/CPF chegam do Excel como numero e perdem o zero a esquerda.
    CPF (pessoa fisica) tem 11 digitos, CNPJ (juridica) tem 14."""
    if pd.isna(row["cgc"]):
        return None
    largura = 11 if row["pfj"] == "F" else 14
    return str(int(row["cgc"])).zfill(largura)


def extrair(dominio: str, arquivo: str, aba: str, rename: dict, tabela_destino: str) -> None:
    caminho = os.path.join(BASES_DIR, arquivo)
    print(f"[{dominio}] lendo {caminho} (aba {aba})...")
    df = pd.read_excel(caminho, sheet_name=aba)
    df = df[list(rename.keys())].rename(columns=rename)
    df = _limpar(df)

    for col in DATE_COLS.get(tabela_destino.split(".")[1], []):
        if col in df.columns:
            df[col] = pd.to_datetime(df[col], errors="coerce")

    if "dia_util" in df.columns:
        df["dia_util"] = df["dia_util"] == 1

    if {"cgc", "pfj"}.issubset(df.columns):
        df["cgc"] = df.apply(_zfill_documento, axis=1)
    if "cep" in df.columns:
        df["cep"] = df["cep"].apply(lambda v: None if pd.isna(v) else str(int(v)).zfill(8))

    print(f"[{dominio}] {len(df):,} linhas lidas. Gravando em {tabela_destino}...")
    schema, table = tabela_destino.split(".")
    df.to_sql(table, _postgres_engine(), schema=schema, if_exists="replace", index=False)
    print(f"[{dominio}] concluido.")


if __name__ == "__main__":
    # Apenas fontes manuais. Produto/cliente/vendedor vêm do Protheus
    # (extract_protheus.py) — não recarregue-os daqui, senão sobrescreve o raw.
    extrair("familia", "fManual.xlsx", "dFamilia", RENAME_FAMILIA, "raw.familia")
    extrair("regiao", "fManual.xlsx", "dRegiao", RENAME_REGIAO, "raw.regiao")
    extrair("destino", "fManual.xlsx", "dDestino", RENAME_DESTINO, "raw.destino")
    extrair("motivo_dev", "fManual.xlsx", "dMotivoDev", RENAME_MOTIVODEV, "raw.motivo_dev")
    extrair("calendario", "dCalendario.xlsx", "dCalendar", RENAME_CALENDARIO, "raw.calendario")
