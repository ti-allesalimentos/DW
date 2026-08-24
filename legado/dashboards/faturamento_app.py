"""
Dashboard de faturamento (Streamlit) — lê de dw.fato_faturamento + dimensões.

Abas: Visão geral (curva diária + projeção), Produto (família/marca),
Geografia (estados/região). Filtro de período global no topo.

Uso:
    streamlit run dashboards/faturamento_app.py
"""
import json
import os
import urllib.request

import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import streamlit as st
from dotenv import load_dotenv
from sqlalchemy import create_engine

load_dotenv()

CordeMarca = "#c0392b"  # vermelho Alles (aproximado) para acentos
GEOJSON_UF_URL = (
    "https://raw.githubusercontent.com/codeforgermany/click_that_hood/"
    "main/public/data/brazil-states.geojson"
)


# --------------------------------------------------------------------------- #
# Conexão e carga
# --------------------------------------------------------------------------- #
@st.cache_resource
def _engine():
    u = os.getenv("POSTGRES_USER")
    p = os.getenv("POSTGRES_PASSWORD")
    h = os.getenv("POSTGRES_HOST", "localhost")
    pt = os.getenv("POSTGRES_PORT", "5432")
    d = os.getenv("POSTGRES_DB")
    return create_engine(f"postgresql+psycopg2://{u}:{p}@{h}:{pt}/{d}")


@st.cache_data(ttl=600)
def carregar() -> pd.DataFrame:
    sql = """
        SELECT
            f.dt_emissao, f.total, f.qtd, f.nfe,
            fam.familia, fam.marca, fam.sub_recorte,
            cli.estado, cli.estado_desc, cli.regiao,
            cal.dia_util
        FROM dw.fato_faturamento f
        LEFT JOIN dw.dim_familia    fam ON fam.cod = f.cod_produto
        LEFT JOIN dw.dim_cliente    cli ON cli.chave_cliente = f.chave_cliente
        LEFT JOIN dw.dim_calendario cal ON cal.data = f.dt_emissao
    """
    df = pd.read_sql(sql, _engine())
    df["dt_emissao"] = pd.to_datetime(df["dt_emissao"])
    df["ym"] = df["dt_emissao"].dt.to_period("M").astype(str)
    for col in ["familia", "marca", "sub_recorte", "regiao", "estado"]:
        df[col] = df[col].fillna("(não classificado)")
    return df


@st.cache_data(ttl=600)
def dias_uteis_por_mes() -> pd.DataFrame:
    """Total de dias úteis por mês, do calendário completo (não só dias com venda)."""
    sql = """
        SELECT to_char(data,'YYYY-MM') AS ym,
               count(*) FILTER (WHERE dia_util) AS dias_uteis_mes
        FROM dw.dim_calendario
        GROUP BY 1
    """
    return pd.read_sql(sql, _engine())


@st.cache_data(ttl=600)
def carregar_devolucoes() -> pd.DataFrame:
    sql = """
        SELECT d.dt_emissao, d.total, d.qtd,
               md.motivo, md.categoria,
               fam.familia
        FROM dw.fato_devolucoes d
        LEFT JOIN dw.dim_motivo_dev md ON md.sigla = d.motivo_dev
        LEFT JOIN dw.dim_familia    fam ON fam.cod = d.cod_produto
    """
    df = pd.read_sql(sql, _engine())
    df["dt_emissao"] = pd.to_datetime(df["dt_emissao"])
    df["ym"] = df["dt_emissao"].dt.to_period("M").astype(str)
    df["motivo"] = df["motivo"].fillna("(sem motivo)")
    df["categoria"] = df["categoria"].fillna("(sem categoria)")
    return df


@st.cache_data(ttl=600)
def carregar_bonificacao() -> pd.DataFrame:
    sql = """
        SELECT b.dt_emissao, b.total, b.qtd, fam.familia
        FROM dw.fato_bonificacao b
        LEFT JOIN dw.dim_familia fam ON fam.cod = b.cod_produto
    """
    df = pd.read_sql(sql, _engine())
    df["dt_emissao"] = pd.to_datetime(df["dt_emissao"])
    df["ym"] = df["dt_emissao"].dt.to_period("M").astype(str)
    df["familia"] = df["familia"].fillna("(não classificado)")
    return df


@st.cache_data(ttl=86400)
def geojson_uf():
    try:
        with urllib.request.urlopen(GEOJSON_UF_URL, timeout=8) as r:
            return json.load(r)
    except Exception:
        return None


def brl(v: float) -> str:
    """Formata em R$ pt-BR sem depender de locale."""
    return "R$ " + f"{v:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")


def milhar(v: float) -> str:
    return f"{v:,.0f}".replace(",", ".")


# --------------------------------------------------------------------------- #
# App
# --------------------------------------------------------------------------- #
st.set_page_config(page_title="Faturamento — Alles", layout="wide")

try:
    df = carregar()
    du_mes = dias_uteis_por_mes()
    dev = carregar_devolucoes()
    bonif = carregar_bonificacao()
except Exception as e:  # noqa: BLE001
    st.warning(
        "Ainda não há dados. Suba o Postgres, rode o SQL do modelo e a "
        f"ingestão antes de abrir o dashboard.\n\nDetalhe técnico: {e}"
    )
    st.stop()

st.title("Faturamento — Alles")

# ---- Filtro de período global ----
meses = sorted(df["ym"].unique())
c_ini, c_fim, _ = st.columns([1, 1, 3])
ini = c_ini.selectbox("De", meses, index=0)
fim = c_fim.selectbox("Até", meses, index=len(meses) - 1)
if ini > fim:
    st.error("O mês inicial é maior que o final.")
    st.stop()

dff = df[(df["ym"] >= ini) & (df["ym"] <= fim)].copy()
devf = dev[(dev["ym"] >= ini) & (dev["ym"] <= fim)].copy()
bonf = bonif[(bonif["ym"] >= ini) & (bonif["ym"] <= fim)].copy()

# ---- KPIs ----
k1, k2, k3, k4 = st.columns(4)
k1.metric("Faturamento total", brl(dff["total"].sum()))
k2.metric("Notas fiscais", milhar(dff["nfe"].nunique()))
k3.metric("Itens", milhar(len(dff)))
k4.metric("Volume (kg)", milhar(dff["qtd"].sum()))

aba_geral, aba_produto, aba_geo, aba_comercial = st.tabs(
    ["📈 Visão geral", "📦 Produto", "🗺️ Geografia", "💼 Comercial"]
)

# =========================================================================== #
# Aba 1 — Visão geral: curva diária + projeção do mês de referência
# =========================================================================== #
with aba_geral:
    ref = fim  # mês de referência para a projeção = último do período
    st.subheader(f"Curva diária acumulada — {ref}")

    dref = dff[dff["ym"] == ref].copy()
    if dref.empty:
        st.info("Sem faturamento no mês de referência.")
    else:
        diario = (
            dref.groupby(dref["dt_emissao"].dt.date, as_index=False)["total"]
            .sum()
            .rename(columns={"dt_emissao": "dia"})
            .sort_values("dia")
        )
        diario["acumulado"] = diario["total"].cumsum()

        realizado = diario["acumulado"].iloc[-1]

        # projeção linear por dias úteis
        dias_uteis_mes = int(
            du_mes.loc[du_mes["ym"] == ref, "dias_uteis_mes"].iloc[0]
        )
        dias_uteis_decorridos = dref.loc[dref["dia_util"] == True, "dt_emissao"].dt.date.nunique()
        if dias_uteis_decorridos > 0:
            projetado = realizado / dias_uteis_decorridos * dias_uteis_mes
        else:
            projetado = realizado

        p1, p2, p3 = st.columns(3)
        p1.metric("Realizado no mês", brl(realizado))
        p2.metric(
            "Projeção de fechamento",
            brl(projetado),
            delta=f"+{brl(projetado - realizado)}",
        )
        p3.metric(
            "Dias úteis",
            f"{dias_uteis_decorridos} / {dias_uteis_mes}",
        )

        fig = go.Figure()
        fig.add_trace(
            go.Scatter(
                x=diario["dia"], y=diario["acumulado"],
                mode="lines+markers", name="Realizado",
                line=dict(color=CordeMarca, width=3),
            )
        )
        # linha tracejada até a projeção de fechamento
        fig.add_trace(
            go.Scatter(
                x=[diario["dia"].iloc[-1]],
                y=[projetado],
                mode="markers+text", name="Projeção",
                marker=dict(color="gray", size=10, symbol="star"),
                text=["projeção"], textposition="top center",
            )
        )
        fig.update_layout(
            height=420, yaxis_title="R$ acumulado", xaxis_title="dia",
            hovermode="x unified", margin=dict(t=20),
        )
        st.plotly_chart(fig, use_container_width=True)

    # faturamento mensal no período todo
    st.subheader("Faturamento por mês (período selecionado)")
    serie = dff.groupby("ym", as_index=False)["total"].sum()
    fig_m = px.bar(serie, x="ym", y="total", color_discrete_sequence=[CordeMarca])
    fig_m.update_layout(height=320, yaxis_title="R$", xaxis_title="mês", margin=dict(t=20))
    st.plotly_chart(fig_m, use_container_width=True)

# =========================================================================== #
# Aba 2 — Produto: família / marca / sub-recorte
# =========================================================================== #
with aba_produto:
    c1, c2 = st.columns(2)

    fam = (
        dff.groupby("familia", as_index=False)["total"].sum()
        .sort_values("total", ascending=True)
    )
    fig_fam = px.bar(
        fam.tail(15), x="total", y="familia", orientation="h",
        color_discrete_sequence=[CordeMarca],
    )
    fig_fam.update_layout(height=500, xaxis_title="R$", yaxis_title="", margin=dict(t=20))
    c1.subheader("Faturamento por família")
    c1.plotly_chart(fig_fam, use_container_width=True)

    marca = (
        dff.groupby("marca", as_index=False)["total"].sum()
        .sort_values("total", ascending=False)
    )
    fig_marca = px.pie(marca, values="total", names="marca", hole=0.45)
    fig_marca.update_layout(height=500, margin=dict(t=20))
    c2.subheader("Participação por marca")
    c2.plotly_chart(fig_marca, use_container_width=True)

    st.subheader("Família × Sub-recorte (treemap)")
    tree = dff.groupby(["familia", "sub_recorte"], as_index=False)["total"].sum()
    fig_tree = px.treemap(
        tree, path=["familia", "sub_recorte"], values="total",
        color="total", color_continuous_scale="Reds",
    )
    fig_tree.update_layout(height=500, margin=dict(t=20))
    st.plotly_chart(fig_tree, use_container_width=True)

# =========================================================================== #
# Aba 3 — Geografia: mapa de UF + barras por região
# =========================================================================== #
with aba_geo:
    por_uf = dff.groupby("estado", as_index=False)["total"].sum()
    gj = geojson_uf()

    c1, c2 = st.columns([3, 2])
    if gj is not None:
        fig_map = px.choropleth(
            por_uf, geojson=gj, locations="estado",
            featureidkey="properties.sigla", color="total",
            color_continuous_scale="Reds", scope="south america",
        )
        fig_map.update_geos(fitbounds="locations", visible=False)
        fig_map.update_layout(height=520, margin=dict(t=20, b=0, l=0, r=0))
        c1.subheader("Faturamento por estado")
        c1.plotly_chart(fig_map, use_container_width=True)
    else:
        c1.subheader("Faturamento por estado")
        c1.info("Mapa indisponível (sem acesso ao geojson). Exibindo ranking.")
        fig_uf = px.bar(
            por_uf.sort_values("total"), x="total", y="estado", orientation="h",
            color_discrete_sequence=[CordeMarca],
        )
        fig_uf.update_layout(height=520, margin=dict(t=20))
        c1.plotly_chart(fig_uf, use_container_width=True)

    reg = (
        dff.groupby("regiao", as_index=False)["total"].sum()
        .sort_values("total", ascending=True)
    )
    fig_reg = px.bar(
        reg, x="total", y="regiao", orientation="h",
        color_discrete_sequence=[CordeMarca],
    )
    fig_reg.update_layout(height=520, xaxis_title="R$", yaxis_title="", margin=dict(t=20))
    c2.subheader("Por região")
    c2.plotly_chart(fig_reg, use_container_width=True)

# =========================================================================== #
# Aba 4 — Comercial: venda líquida, devoluções, bonificações
# =========================================================================== #
with aba_comercial:
    bruto = dff["total"].sum()
    devolucao = devf["total"].sum()
    liquida = bruto - devolucao
    bonificacao = bonf["total"].sum()

    m1, m2, m3, m4 = st.columns(4)
    m1.metric("Faturamento bruto", brl(bruto))
    m2.metric(
        "Devoluções", brl(devolucao),
        delta=f"-{(devolucao / bruto * 100 if bruto else 0):.1f}%",
        delta_color="inverse",
    )
    m3.metric("Venda líquida", brl(liquida))
    m4.metric("Bonificações", brl(bonificacao))

    st.divider()
    c1, c2 = st.columns(2)

    # devoluções por motivo (colorido por categoria)
    mot = (
        devf.groupby(["categoria", "motivo"], as_index=False)["total"].sum()
        .sort_values("total", ascending=True)
    )
    fig_mot = px.bar(
        mot.tail(12), x="total", y="motivo", orientation="h", color="categoria",
    )
    fig_mot.update_layout(height=480, xaxis_title="R$", yaxis_title="",
                          margin=dict(t=20), legend_title="categoria")
    c1.subheader("Devoluções por motivo")
    c1.plotly_chart(fig_mot, use_container_width=True)

    # bruto vs líquida por mês
    fb = dff.groupby("ym", as_index=False)["total"].sum().rename(columns={"total": "bruto"})
    fd = devf.groupby("ym", as_index=False)["total"].sum().rename(columns={"total": "devolucao"})
    comp = fb.merge(fd, on="ym", how="left").fillna(0)
    comp["liquida"] = comp["bruto"] - comp["devolucao"]
    fig_cmp = go.Figure()
    fig_cmp.add_bar(x=comp["ym"], y=comp["bruto"], name="Bruto",
                    marker_color="#95a5a6")
    fig_cmp.add_bar(x=comp["ym"], y=comp["liquida"], name="Líquida",
                    marker_color=CordeMarca)
    fig_cmp.update_layout(height=480, barmode="overlay", yaxis_title="R$",
                          xaxis_title="mês", margin=dict(t=20))
    c2.subheader("Bruto × Líquida por mês")
    c2.plotly_chart(fig_cmp, use_container_width=True)

    # devoluções por categoria
    st.subheader("Devoluções por categoria")
    cat = devf.groupby("categoria", as_index=False)["total"].sum().sort_values("total")
    fig_cat = px.bar(cat, x="total", y="categoria", orientation="h",
                     color_discrete_sequence=[CordeMarca])
    fig_cat.update_layout(height=320, xaxis_title="R$", yaxis_title="", margin=dict(t=20))
    st.plotly_chart(fig_cat, use_container_width=True)
