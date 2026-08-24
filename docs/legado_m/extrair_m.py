"""Extrai o codigo Power Query (M) de dentro de workbooks Excel.

O M fica no DataMashup: customXml/itemN.xml (UTF-16) contem um blob base64
que e um zip com Formulas/Section1.m dentro.

Uso: python extrair_m.py <destino> <arquivo.xlsx> [arquivo2.xlsx ...]
"""
import base64
import io
import os
import re
import struct
import sys
import zipfile


def extrair(caminho):
    z = zipfile.ZipFile(caminho)
    alvos = [n for n in z.namelist()
             if re.match(r"customXml/item\d+\.xml$", n)]
    for nome in alvos:
        bruto = z.read(nome)
        try:
            texto = bruto.decode("utf-16")
        except UnicodeError:
            texto = bruto.decode("utf-8", "ignore")
        if "DataMashup" not in texto:
            continue
        m = re.search(r">([A-Za-z0-9+/=\s]{200,})<", texto)
        if not m:
            continue
        blob = base64.b64decode(re.sub(r"\s", "", m.group(1)))
        _versao, tamanho = struct.unpack("<II", blob[:8])
        interno = zipfile.ZipFile(io.BytesIO(blob[8:8 + tamanho]))
        if "Formulas/Section1.m" in interno.namelist():
            return interno.read("Formulas/Section1.m").decode("utf-8", "ignore")
    return None


if __name__ == "__main__":
    destino = sys.argv[1]
    os.makedirs(destino, exist_ok=True)
    for caminho in sys.argv[2:]:
        base = os.path.splitext(os.path.basename(caminho))[0]
        try:
            codigo = extrair(caminho)
        except Exception as erro:
            print(f"ERRO   | {base:32s} | {erro}")
            continue
        if codigo is None:
            print(f"VAZIO  | {base:32s} | sem DataMashup")
            continue
        saida = os.path.join(destino, base + ".m")
        with open(saida, "w", encoding="utf-8") as fh:
            fh.write(codigo)
        n_consultas = len(re.findall(r"^shared ", codigo, re.M))
        print(f"OK     | {base:32s} | {len(codigo):8d} bytes | {n_consultas:3d} consultas")
