# alles-dataplatform

Data warehouse da Alles Alimentos: Protheus → Postgres em três camadas →
dashboards no **Oryon Board**.

O documento de referência do projeto é **`docs/arquitetura.md`**. Leia-o antes
de mexer em qualquer coisa aqui.

## Camadas

| Camada | O que é | O que **não** faz |
|--------|---------|-------------------|
| `bronze` | Espelho fiel das tabelas do Protheus | Não filtra, não converte, não faz join, não decide nada |
| `prata` | Conformação técnica + regras de negócio explícitas | Não agrega, não calcula métrica |
| `ouro` | Modelo dimensional e marts por dashboard | Não limpa dado |

O bronze espelha **tabelas**, não queries de domínio: cada tabela do Protheus é
extraída uma única vez e serve aos nove domínios. É isso que acaba com o problema
de o `SB1010` ser lido por doze lugares diferentes, cada um com sua tratativa.

## Estrutura

```
extracao/        extrator incremental (Protheus -> bronze)
  conexao.py       engines de origem e destino
  watermark.py     janela de extração e registro em ouro.controle_cargas
  carga.py         extração, staging e MERGE
  fontes.yml       uma entrada por tabela do Protheus
transformacao/   projeto dbt (bronze -> prata -> ouro)
  models/          bronze (sources), prata (stg_*), ouro (dim_/fato_/mart_)
  seeds/           regras de negócio versionadas em CSV
  macros/          conformação do Protheus (TRIM, datas)
infra/           docker-compose e DDL das camadas
docs/            arquitetura, inventários e plano de execução
legado/          código anterior, preservado como referência
```

## Início rápido

```bash
cp .env.example .env            # e preencha
python -m venv .venv && .venv/Scripts/activate     # Windows
pip install -r requirements.txt

docker compose -f infra/docker-compose.yml up -d
psql -f infra/sql/00_schemas.sql
psql -f infra/sql/01_controle_cargas.sql

python -m extracao.carga --listar          # confere o plano
python -m extracao.carga --fonte SB1010    # primeira carga, tabela pequena

cd transformacao && dbt deps && dbt seed && dbt build
```

Passo a passo completo e o que fazer quando algo falha: `docs/execucao.md`.

## Regra que vale sempre

**Nada do que está rodando hoje é alterado.** O `atualizador_1.9.xlsm`, os
workbooks de `P:\T.I\01. BASES`, os relatórios do Power BI e os pipelines de
relatório seguem intocados. Este DW nasce ao lado, não por cima.
