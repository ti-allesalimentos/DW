"""Mapeamento remessa -> retorno -> venda das armazenagens de terceiros (Protheus, leitura)."""
import pickle
import statistics
from collections import defaultdict
from datetime import date

import pandas as pd

from extracao.conexao import protheus

eng = protheus()


def q(sql):
    with eng.connect() as c:
        return c.exec_driver_sql(sql).fetchall()


D = "CONVERT(varchar(8),DATEADD(month,-24,GETDATE()),112)"
roots = {
    '26227949': 'COMERCIAL LAGOS', '20874253': 'JDR', '07087793': 'E.H. SATO', '32345292': 'FREZZE',
    '69220226': 'BOXFRIO', '81894255': 'DUSNEI', '60203918': 'GHL', '83690339': 'DIFRISUL',
    '22520690': 'TRANSFRIO', '07682631': 'REAL RIO PRETO', '43066386': 'ALTO DA MOGIANA', '30745289': 'IMPERIAL',
}
R = ",".join(f"'{k}'" for k in roots)
carr = {
    'E.H. SATO': ['000044'], 'COMERCIAL LAGOS': ['000035'], 'JDR': ['000033'], 'FREZZE': ['00055'],
    'ALTO DA MOGIANA': ['000163'], 'TRANSFRIO': ['000010'],
}


def dt(s):
    return date(int(s[:4]), int(s[4:6]), int(s[6:]))


F4 = ("OUTER APPLY (SELECT TOP 1 F4_TEXTO,F4_DUPLIC,F4_ESTOQUE FROM SF4010 z "
      "WHERE z.F4_CODIGO={tes} AND z.D_E_L_E_T_<>'*' ORDER BY z.F4_FILIAL) f")

# ---------- REMESSAS (saidas p/ armazem)
rem = q(f"""
SELECT LEFT(a.A1_CGC,8) raiz, d.D2_FILIAL fil, RTRIM(d.D2_CF) cf, RTRIM(d.D2_TES) tes, RTRIM(f.F4_TEXTO) txt, f.F4_DUPLIC dup, f.F4_ESTOQUE est,
 COUNT(DISTINCT d.D2_DOC) nfs,
 SUM(CASE WHEN d.D2_UM='KG' THEN d.D2_QUANT ELSE 0 END) kg,
 SUM(CASE WHEN d.D2_UM='KG' AND b.B1_TIPO='PA' THEN d.D2_QUANT ELSE 0 END) kg_pa,
 ROUND(SUM(d.D2_TOTAL),0) v, MIN(d.D2_EMISSAO) pri, MAX(d.D2_EMISSAO) ult
FROM SD2010 d
JOIN SA1010 a ON a.A1_COD=d.D2_CLIENTE AND a.A1_LOJA=d.D2_LOJA AND a.D_E_L_E_T_<>'*'
JOIN SB1010 b ON b.B1_COD=d.D2_COD AND b.D_E_L_E_T_<>'*'
{F4.format(tes='d.D2_TES')}
WHERE d.D_E_L_E_T_<>'*' AND d.D2_EMISSAO>={D} AND LEFT(a.A1_CGC,8) IN ({R})
GROUP BY LEFT(a.A1_CGC,8), d.D2_FILIAL, d.D2_CF, d.D2_TES, f.F4_TEXTO, f.F4_DUPLIC, f.F4_ESTOQUE""")
df_rem = pd.DataFrame([{
    'Armazém': roots[r[0]], 'Filial Alles (remetente)': r[1], 'CFOP remessa': r[2], 'TES': r[3], 'Finalidade (SF4)': r[4],
    'Gera duplicata': r[5], 'Atualiza estoque': r[6],
    'Tipo': 'REMESSA (sem duplicata)' if r[5] == 'N' else 'VENDA/COBRANÇA ao armazém (com duplicata)',
    'NFs': r[7], 'kg': round(r[8] or 0), 'kg PA': round(r[9] or 0), 'Valor R$': int(r[10] or 0), '1ª NF': r[11], 'Última NF': r[12],
} for r in rem]).sort_values(['Armazém', 'Tipo', 'kg'], ascending=[True, True, False])

# ---------- PARES remessa -> retorno (vinculo D1_NFORI)
ret = pickle.load(open('docs/_ret.pkl', 'rb'))
g = defaultdict(lambda: {'docs': set(), 'kg': 0, 'kgpa': 0, 'v': 0, 'lags': []})
for r in ret:
    k = (roots[r[0]], r[1], r[5] or '(sem NF de origem)', r[6] or '', r[7] or '', r[8] or '', r[2], r[3], r[4] or '')
    a = g[k]
    a['docs'].add(r[9])
    if r[14] == 'KG':
        a['kg'] += r[13]
        if r[16] == 'PA':
            a['kgpa'] += r[13]
    a['v'] += r[15] or 0
    if r[10] and r[12]:
        a['lags'].append((dt(r[10]) - dt(r[12])).days)
rows = []
for k, a in g.items():
    L = a['lags']
    rows.append({
        'Armazém': k[0], 'Filial Alles (recebe retorno)': k[1], 'Filial da remessa': k[2], 'CFOP remessa': k[3],
        'TES remessa': k[4], 'Finalidade remessa': k[5], 'CFOP retorno (entrada)': k[6], 'TES retorno': k[7],
        'Finalidade retorno': k[8], 'NFs de retorno': len(a['docs']), 'kg': round(a['kg']), 'kg PA': round(a['kgpa']),
        'Valor R$': int(a['v']),
        'Prazo remessa→retorno mediano (dias)': statistics.median(L) if L else None,
        'Prazo mín': min(L) if L else None, 'Prazo máx': max(L) if L else None})
df_par = pd.DataFrame(rows).sort_values(['Armazém', 'kg'], ascending=[True, False])

# ---------- VENDAS emitidas via transportadora ligada ao armazem
vend = []
for arm, codes in carr.items():
    cl = ",".join(f"'{c}'" for c in codes)
    v = q(f"""
SELECT RTRIM(f.F2_TRANSP) tr, MAX(RTRIM(t.A4_NOME)) trn, s.D2_FILIAL fil, RTRIM(s.D2_CF) cf, RTRIM(s.D2_TES) tes,
 MAX(RTRIM(tf.F4_TEXTO)) txt, COUNT(DISTINCT s.D2_DOC) nfs,
 SUM(CASE WHEN s.D2_UM='KG' THEN s.D2_QUANT ELSE 0 END) kg, ROUND(SUM(s.D2_TOTAL),0) v, MAX(s.D2_EMISSAO) ult
FROM SD2010 s
JOIN SF2010 f ON f.D_E_L_E_T_<>'*' AND f.F2_FILIAL=s.D2_FILIAL AND f.F2_DOC=s.D2_DOC AND f.F2_SERIE=s.D2_SERIE
JOIN SA4010 t ON t.A4_COD=f.F2_TRANSP AND t.D_E_L_E_T_<>'*'
{F4.format(tes='s.D2_TES').replace(' f', ' tf')}
WHERE s.D_E_L_E_T_<>'*' AND s.D2_EMISSAO>={D} AND RTRIM(f.F2_TRANSP) IN ({cl}) AND tf.F4_DUPLIC='S'
GROUP BY f.F2_TRANSP, s.D2_FILIAL, s.D2_CF, s.D2_TES""")
    for r in v:
        vend.append({
            'Armazém': arm, 'Transportadora (SA4)': f"{r[0].strip()} - {r[1]}", 'Filial Alles (emite a venda)': r[2],
            'CFOP venda': r[3], 'TES venda': r[4], 'Finalidade (SF4)': r[5], 'NFs': r[6], 'kg': round(r[7] or 0),
            'Valor R$': int(r[8] or 0), 'Última venda': r[9]})
df_ven = pd.DataFrame(vend).sort_values(['Armazém', 'kg'], ascending=[True, False])

# ---------- evidencia: vendas casadas com retorno (filial+produto+qtd+data +-3d) por transportadora
co = q(f"""
WITH ret AS (
 SELECT LEFT(a.A2_CGC,8) raiz, d.D1_FILIAL fil, d.D1_COD cod, d.D1_QUANT qt, d.D1_DTDIGIT dt, d.D1_DOC doc
 FROM SD1010 d JOIN SA2010 a ON a.A2_COD=d.D1_FORNECE AND a.A2_LOJA=d.D1_LOJA AND a.D_E_L_E_T_<>'*'
 WHERE d.D_E_L_E_T_<>'*' AND d.D1_DTDIGIT>={D} AND LEFT(a.A2_CGC,8) IN ({R})
   AND d.D1_CF IN ('2949','1949','2906','1906') AND d.D1_QUANT>0)
SELECT ret.raiz, RTRIM(f.F2_TRANSP) tr, MAX(RTRIM(t.A4_NOME)) nome, COUNT(DISTINCT ret.doc) n_ret, COUNT(DISTINCT s.D2_DOC) n_v
FROM ret
JOIN SD2010 s ON s.D_E_L_E_T_<>'*' AND s.D2_FILIAL=ret.fil AND s.D2_COD=ret.cod AND s.D2_QUANT=ret.qt
 AND ABS(DATEDIFF(day, CONVERT(date,s.D2_EMISSAO), CONVERT(date,ret.dt)))<=3
JOIN SF2010 f ON f.D_E_L_E_T_<>'*' AND f.F2_FILIAL=s.D2_FILIAL AND f.F2_DOC=s.D2_DOC AND f.F2_SERIE=s.D2_SERIE
OUTER APPLY (SELECT TOP 1 F4_DUPLIC FROM SF4010 z WHERE z.F4_CODIGO=s.D2_TES AND z.D_E_L_E_T_<>'*' ORDER BY z.F4_FILIAL) tf
LEFT JOIN SA4010 t ON t.A4_COD=f.F2_TRANSP AND t.D_E_L_E_T_<>'*'
WHERE tf.F4_DUPLIC='S'
GROUP BY ret.raiz, f.F2_TRANSP""")
df_co = pd.DataFrame([{
    'Armazém': roots[r[0]],
    'Transportadora na venda': f"{(r[1] or '(sem transportadora)').strip()} - {(r[2] or '').strip()}",
    'Vendas casadas com retorno (produto+qtd+data ±3d)': r[4], 'Retornos casados': r[3]} for r in co]
).sort_values(['Armazém', 'Vendas casadas com retorno (produto+qtd+data ±3d)'], ascending=[True, False])

# ---------- resumo por armazem
res = []
for raiz, arm in roots.items():
    p = df_par[df_par['Armazém'] == arm]
    r_ = df_rem[(df_rem['Armazém'] == arm) & (df_rem['Tipo'].str.startswith('REMESSA'))]
    cf_rem = ", ".join(f"{a}/{b}" for a, b in
                       r_.groupby(['CFOP remessa', 'TES'])['kg'].sum().sort_values(ascending=False).head(3).index)
    cf_ret = ", ".join(f"{a}/{b}" for a, b in
                       p.groupby(['CFOP retorno (entrada)', 'TES retorno'])['kg'].sum().sort_values(ascending=False).head(3).index)
    lag = p['Prazo remessa→retorno mediano (dias)'].dropna()
    cv = df_co[df_co['Armazém'] == arm].head(3)
    dc = df_ven[df_ven['Armazém'] == arm] if len(df_ven) else df_ven
    res.append({
        'Armazém': arm, 'CNPJ (raiz)': raiz, 'Filial remetente': ", ".join(sorted(set(r_['Filial Alles (remetente)']))),
        'Remessa: CFOP/TES (principais)': cf_rem, 'Retorno: CFOP/TES (principais)': cf_ret,
        'NFs remessa': int(r_['NFs'].sum()) if len(r_) else 0, 'kg remessa': int(r_['kg'].sum()) if len(r_) else 0,
        'NFs retorno': int(p['NFs de retorno'].sum()), 'kg retorno': int(p['kg'].sum()),
        'Prazo mediano remessa→retorno (dias)': float(lag.median()) if len(lag) else None,
        'Transportadora da venda (cadastro SA4)': ", ".join(sorted(set(dc['Transportadora (SA4)']))) if len(dc) else '(sem transportadora própria identificada)',
        'NFs de venda pela transportadora': int(dc['NFs'].sum()) if len(dc) else 0,
        'Transportadoras casadas com o retorno (top 3)': "; ".join(
            f"{x['Transportadora na venda']} ({int(x['Vendas casadas com retorno (produto+qtd+data ±3d)'])})" for _, x in cv.iterrows())})
df_res = pd.DataFrame(res)

# ---------- por filial
fil = []
rem_only = df_rem[df_rem['Tipo'].str.startswith('REMESSA')]
for f_ in sorted(set(rem_only['Filial Alles (remetente)']) | set(df_par['Filial Alles (recebe retorno)']) | set(df_ven['Filial Alles (emite a venda)'])):
    a = rem_only[rem_only['Filial Alles (remetente)'] == f_]
    b = df_par[df_par['Filial Alles (recebe retorno)'] == f_]
    c = df_ven[df_ven['Filial Alles (emite a venda)'] == f_]
    fil.append({
        'Filial Alles': f_, 'Remessas: NFs': int(a['NFs'].sum()), 'Remessas: kg': int(a['kg'].sum()),
        'Armazéns que recebem': ", ".join(sorted(set(a['Armazém']))), 'Retornos: NFs': int(b['NFs de retorno'].sum()),
        'Retornos: kg': int(b['kg'].sum()), 'Vendas via transp. do armazém: NFs': int(c['NFs'].sum()),
        'Vendas: kg': int(c['kg'].sum())})
df_fil = pd.DataFrame(fil)
fa = []
for (arm, f_), a in rem_only.groupby(['Armazém', 'Filial Alles (remetente)']):
    b = df_par[(df_par['Armazém'] == arm) & (df_par['Filial Alles (recebe retorno)'] == f_)]
    c = df_ven[(df_ven['Armazém'] == arm) & (df_ven['Filial Alles (emite a venda)'] == f_)] if len(df_ven) else df_ven
    fa.append({
        'Filial Alles': f_, 'Armazém': arm, 'Remessa NFs': int(a['NFs'].sum()), 'Remessa kg': int(a['kg'].sum()),
        'Retorno NFs': int(b['NFs de retorno'].sum()), 'Retorno kg': int(b['kg'].sum()),
        'Saldo kg (remessa − retorno)': int(a['kg'].sum() - b['kg'].sum()),
        'Venda NFs (transp. do armazém)': int(c['NFs'].sum()) if len(c) else 0, 'Venda kg': int(c['kg'].sum()) if len(c) else 0})
df_fa = pd.DataFrame(fa).sort_values(['Filial Alles', 'Remessa kg'], ascending=[True, False])

leia = [
    'Mapeamento das 12 armazenagens de terceiros (Protheus, empresa 010, últimos 24 meses) — gerado em 2026-10-08.',
    'Ciclo: REMESSA (saída da filial Alles ao armazém, CFOP 6905/6949) -> RETORNO (entrada 2949/2906, TES 226/210/311/244, vinculada à remessa pela NF de origem D1_NFORI) -> VENDA (saída do estoque no armazém ao cliente final, que destaca a transportadora ligada ao armazém).',
    'Transportadora da venda: (1) código SA4 do armazém/parceiro; (2) evidência por casamento — venda com mesma filial, produto e quantidade, até 3 dias do retorno (aba Venda - evidência).',
    'Kg considera só itens em unidade KG; kg PA = produto acabado (B1_TIPO = PA).',
    'Armazéns sem transportadora própria identificada: a venda sai por transportadoras gerais da Alles, não distinguível pela transportadora.',
]
with pd.ExcelWriter('docs/mapeamento_armazens_terceiros.xlsx', engine='openpyxl') as w:
    pd.DataFrame({'Leia-me': leia}).to_excel(w, sheet_name='Leia-me', index=False)
    df_res.to_excel(w, sheet_name='Resumo por armazém', index=False)
    df_fa.to_excel(w, sheet_name='Por filial x armazém', index=False)
    df_fil.to_excel(w, sheet_name='Por filial', index=False)
    df_rem.to_excel(w, sheet_name='Remessas (saídas)', index=False)
    df_par.to_excel(w, sheet_name='Remessa -> Retorno', index=False)
    df_ven.to_excel(w, sheet_name='Venda - transp. do armazém', index=False)
    df_co.to_excel(w, sheet_name='Venda - evidência', index=False)
    for ws in w.book.worksheets:
        for col in ws.columns:
            m = max((len(str(c.value)) if c.value is not None else 0) for c in col)
            ws.column_dimensions[col[0].column_letter].width = min(max(12, m + 2), 70)
        ws.freeze_panes = 'A2'

pd.set_option('display.width', 250)
pd.set_option('display.max_columns', 30)
pd.set_option('display.max_colwidth', 70)
print(df_res.to_string(index=False))
print()
print(df_fil.to_string(index=False))
print()
print(df_fa.to_string(index=False))
