# Roadmap — migração do DW (piloto: faturamento)

Regra de ouro: **uma ferramenta nova por vez**, e cada fase termina com
algo funcionando antes de adicionar a próxima.

1. **Ambiente.** Docker Desktop no Windows (homologação) + VM Linux (produção),
   sincronizados por GitHub. Meta: `docker run hello-world` funcionando.
2. **Warehouse no ar.** `docker compose up -d` (Postgres + Adminer).
   Rodar `sql/01_modelo_faturamento.sql`. Meta: schemas `raw` e `dw` criados.
3. **Ingestão do piloto.** Configurar Protheus no `.env` e rodar
   `ingestion/extract_protheus.py`. Meta: `raw.faturamento` populado.
4. **Transformação.** Popular as dimensões e rodar o povoamento do fato.
   Meta: `dw.fato_faturamento` preenchido, com a conversão -CX via `map_produto_cx`.
5. **Dashboard.** `streamlit run dashboards/faturamento_app.py`.
   Meta: números iguais aos do Excel.
6. **Validação.** Reconciliar `sum(total)` do fato contra o `fFaturamento` da planilha.
7. **Automação.** Introduzir Dagster para orquestrar ingestão → dbt → dashboard.
8. **Expansão e template.** Repetir para as outras áreas e extrair o template replicável.
