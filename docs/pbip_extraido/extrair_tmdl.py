"""Le os modelos semanticos .pbip em formato TMDL e consolida
tabelas, colunas, medidas DAX e relacionamentos em markdown.

Uso: python extrair_tmdl.py <pasta_PBIP> <pasta_destino>
"""
import os
import re
import sys

PROPS = ("formatString", "lineageTag", "displayFolder", "description",
         "isHidden", "annotation", "changedProperty", "formatStringDefinition",
         "dataType", "sourceColumn", "summarizeBy", "isDataTypeInferred",
         "variation", "relatedColumnDetails", "extendedProperty", "isKey",
         "sortByColumn", "dataCategory", "encodingHint")


def _e_propriedade(linha):
    nu = linha.strip()
    return any(nu.startswith(p) for p in PROPS)


def ler_tabela(caminho):
    """Devolve (nome_tabela, colunas, medidas, particoes)."""
    linhas = open(caminho, encoding="utf-8").read().splitlines()
    nome = os.path.splitext(os.path.basename(caminho))[0]
    colunas, medidas, particoes = [], [], []
    i = 0
    while i < len(linhas):
        linha = linhas[i]
        nu = linha.strip()
        m = re.match(r"^measure\s+(.+?)\s*=\s*(.*)$", nu)
        if m:
            nome_m = m.group(1).strip().strip("'")
            expr = [m.group(2)] if m.group(2).strip() else []
            recuo = len(linha) - len(linha.lstrip())
            i += 1
            while i < len(linhas):
                prox = linhas[i]
                if not prox.strip():
                    i += 1
                    continue
                r = len(prox) - len(prox.lstrip())
                if r <= recuo or _e_propriedade(prox):
                    break
                expr.append(prox.strip())
                i += 1
            medidas.append((nome_m, " ".join(expr).strip()))
            continue
        c = re.match(r"^column\s+(.+?)\s*$", nu)
        if c:
            colunas.append(c.group(1).strip().strip("'"))
        p = re.match(r"^partition\s+(.+?)\s*=\s*(\w+)", nu)
        if p:
            particoes.append(p.group(2))
        i += 1
    return nome, colunas, medidas, particoes


def ler_relacionamentos(caminho):
    if not os.path.exists(caminho):
        return []
    texto = open(caminho, encoding="utf-8").read()
    rels = []
    for bloco in re.split(r"\nrelationship ", texto):
        de = re.search(r"fromColumn:\s*(.+)", bloco)
        para = re.search(r"toColumn:\s*(.+)", bloco)
        if not (de and para):
            continue
        cross = re.search(r"crossFilteringBehavior:\s*(\w+)", bloco)
        card_de = re.search(r"fromCardinality:\s*(\w+)", bloco)
        card_para = re.search(r"toCardinality:\s*(\w+)", bloco)
        inativo = "isActive: false" in bloco
        rels.append({
            "de": de.group(1).strip(),
            "para": para.group(1).strip(),
            "cross": cross.group(1) if cross else "singleDirection",
            "card": f"{card_de.group(1) if card_de else 'many'}->{card_para.group(1) if card_para else 'one'}",
            "inativo": inativo,
        })
    return rels


def processar(modelo_dir, destino):
    nome_modelo = os.path.basename(modelo_dir).replace(".SemanticModel", "")
    tabelas_dir = os.path.join(modelo_dir, "definition", "tables")
    tabelas = []
    if os.path.isdir(tabelas_dir):
        for arq in sorted(os.listdir(tabelas_dir)):
            if arq.endswith(".tmdl"):
                tabelas.append(ler_tabela(os.path.join(tabelas_dir, arq)))
    rels = ler_relacionamentos(
        os.path.join(modelo_dir, "definition", "relationships.tmdl"))

    total_medidas = sum(len(t[2]) for t in tabelas)
    total_colunas = sum(len(t[1]) for t in tabelas)

    linhas = [f"# Modelo semantico: {nome_modelo}", ""]
    linhas.append(f"- Tabelas: {len(tabelas)}")
    linhas.append(f"- Colunas: {total_colunas}")
    linhas.append(f"- Medidas DAX: {total_medidas}")
    linhas.append(f"- Relacionamentos: {len(rels)}"
                  f" ({sum(1 for r in rels if r['inativo'])} inativos,"
                  f" {sum(1 for r in rels if r['cross'] == 'bothDirections')} bidirecionais)")
    linhas += ["", "## Tabelas", "", "| Tabela | Colunas | Medidas |",
               "|--------|--------:|--------:|"]
    for n, c, med, _ in tabelas:
        linhas.append(f"| {n} | {len(c)} | {len(med)} |")

    linhas += ["", "## Relacionamentos", "",
               "| De | Para | Cardinalidade | Filtro | Ativo |",
               "|----|------|---------------|--------|-------|"]
    for r in rels:
        linhas.append(f"| {r['de']} | {r['para']} | {r['card']} | {r['cross']} |"
                      f" {'nao' if r['inativo'] else 'sim'} |")

    linhas += ["", "## Medidas DAX", ""]
    for n, _, med, _ in tabelas:
        if not med:
            continue
        linhas.append(f"### {n}")
        linhas.append("")
        for nome_m, expr in med:
            linhas.append(f"**{nome_m}**")
            linhas.append("")
            linhas.append("```dax")
            linhas.append(expr if expr else "(vazia)")
            linhas.append("```")
            linhas.append("")

    saida = os.path.join(destino, nome_modelo.replace(" ", "_") + ".md")
    open(saida, "w", encoding="utf-8").write("\n".join(linhas))
    return nome_modelo, len(tabelas), total_colunas, total_medidas, len(rels)


if __name__ == "__main__":
    raiz, destino = sys.argv[1], sys.argv[2]
    os.makedirs(destino, exist_ok=True)
    resumo = []
    for item in sorted(os.listdir(raiz)):
        if item.endswith(".SemanticModel"):
            resumo.append(processar(os.path.join(raiz, item), destino))
    print(f"{'MODELO':28s} {'TAB':>5s} {'COL':>6s} {'MED':>5s} {'REL':>5s}")
    for n, t, c, m, r in resumo:
        print(f"{n:28s} {t:5d} {c:6d} {m:5d} {r:5d}")
    print(f"{'TOTAL':28s} {sum(x[1] for x in resumo):5d}"
          f" {sum(x[2] for x in resumo):6d} {sum(x[3] for x in resumo):5d}"
          f" {sum(x[4] for x in resumo):5d}")
