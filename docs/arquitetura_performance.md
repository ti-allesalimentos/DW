# Arquitetura-alvo — Performance, Estrutura e Robustez do DW

> Complementa `docs/arquitetura.md`. Define o estado-alvo do projeto dbt
> **antes do deploy em produção** (VM Linux). Cada item tem: o que é hoje,
> o alvo, e por que fazer agora (pré-produção) e não depois.
>
> Decisões tomadas com o Lucas em 19/10/2026.

---

## 1. Princípio

O gargalo não é modelagem (está madura) — é **performance de consulta** (as
telas do Oryon leem os fatos direto) e **custo do ciclo** (o `dbt build` roda a
cada 2h). As correções abaixo são baratas agora e **caras de fazer com dado e
usuário em produção**. Por isso, pré-deploy.

---

## 2. Schemas — nomes limpos (`bronze` / `prata` / `ouro`)

**Hoje:** o dbt materializa em `prata_prata` e `prata_ouro` (concatenação padrão
do dbt-postgres: schema do profile `prata` + `+schema` do modelo). Desvia da
própria `arquitetura.md` (cap. 4), que define `bronze/prata/ouro`. Funciona só
porque o backend do Oryon tem `DW = "prata_ouro"` hardcoded.

**Alvo:** schemas limpos **`prata`** e **`ouro`**, via macro
`generate_schema_name` que usa o `+schema` verbatim:

```sql
-- macros/generate_schema_name.sql
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
```

**Blast radius (coordenado):** ao renomear, atualizar no `oryon-dw-integracao`
as constantes `DW = "prata_ouro"` / `_DW_SCHEMA = "prata_ouro"`
(`modulos/bi/dw_util.py`, `dw_filtros.py`, `bi_faturamento.py`, `gp_extract.py`)
para `"ouro"`, e **rebuild** do backend. Fazer num passo só (DW + backend)
para o Board não quebrar.

**Por que agora:** renomear schema com usuários em produção = janela de
indisponibilidade + risco. Pré-produção é de graça.

---

## 3. Organização dos models — por domínio

**Hoje:** pastas achatadas — `models/prata/` (54 .sql) e `models/ouro/` (74
.sql), cada uma com **um `_models.yml` gigante**.

**Alvo:** subpastas por domínio (os 9 da `arquitetura.md` cap. 8), com um
`_models.yml` por domínio. O dbt resolve modelo **por nome**, não por caminho —
mover arquivo não quebra referência.

```
models/
  bronze/              _sources.yml por dominio (ou mantido unico, ver nota)
  prata/
    comercial/  financeiro/  fiscal/  industrial/  custo/
    compras/    logistica/   gestao_pessoas/
  ouro/
    _dimensoes/        dims conformadas, compartilhadas entre dominios
    comercial/  financeiro/  fiscal/  industrial/  custo/
    compras/    logistica/   gestao_pessoas/
```

**Ganhos:** navegação; `dbt build --select comercial` (rodar/testar um domínio);
PRs menores; `_models.yml` legíveis.

---

## 4. Materialização — regra por tipo de objeto

| Objeto | Hoje | Alvo | Estratégia |
|--------|------|------|-----------|
| `bronze.*` | tabela (extrator) | igual | MERGE + watermark (já correto) |
| `prata.stg_*` | view | **view** | leve, recomputa on-the-fly |
| `ouro.dim_*` | tabela (full) | **tabela (full)** | dimensões são baratas (segundos) |
| `ouro.agg_*` | tabela (full) | **tabela (full)** | pré-agregado pequeno |
| `ouro.fato_*` **pequeno** | tabela (full) | **tabela (full)** | reprocessar inteiro é ok |
| `ouro.fato_*` **grande** | tabela (full) | **incremental** | ver §5 |

Fatos "grandes" (grão item de NF / alto volume) a tornar incrementais:
`fato_faturamento`, `fato_devolucoes`, `fato_bonificacao`, `fato_refaturamento`,
`fato_acordo_comercial`, `fato_coopeval_remessa`, `fato_remessa_industrializacao`,
`fato_contas_areceber`, `fato_contas_apagar`, `fato_apontamento_producao`,
`fato_pedidos`. (Lista final confirmada por volume real na implementação.)

---

## 5. Incrementalidade dos fatos grandes

**Hoje:** todo `ouro.fato_*` é reconstruído do zero a cada `dbt build` (a cada
2h). Com a **carga inicial do histórico completo** (ver `arquitetura.md` cap. 11),
reconstruir `fato_faturamento` (milhões de linhas) de 2 em 2h fica inviável.

**Implementado (estratégia B):** `incremental_strategy='append'` + um `pre_hook`
que **apaga a janela recente** antes de o SELECT reinseri-la. Diferente de
`delete+insert` (que deleta só pela `unique_key` do lote e **deixa órfãos** quando
uma linha some da origem), o `pre_hook` apaga a janela **por coluna de corte** —
então cancelamentos (linhas que sumiram do prata por `D_E_L_E_T_='*'`) também somem
do fato. O corte usa `current_date`/`current_timestamp` nos dois lados (estável:
não depende do estado da própria tabela, evitando o bug do `max()` pós-delete).

**A janela de corte segue o watermark da fonte** (`extracao/fontes.yml`) — tem que
ser do mesmo tipo, senão o incremental fica inconsistente com o extrator:

- **Variante A — janela por data de emissão (60d).** Fontes com watermark de data
  de negócio (`D2_EMISSAO`, `D1_EMISSAO`, `C5_EMISSAO`). O extrator só relê a janela
  de emissão, então o fato também. Fatos: `fato_faturamento`, `devolucoes`,
  `bonificacao`, `refaturamento`, `coopeval_remessa`, `acordo_comercial`,
  `remessa_industrializacao`.
  ```sql
  {{ config(materialized='incremental', incremental_strategy='append',
      pre_hook="{% if is_incremental() %}delete from {{ this }}
               where data_emissao >= current_date - interval '60 days'{% endif %}") }}
  select ... from {{ ref('stg_faturamento') }} f
  {% if is_incremental() %} where f.dt_emissao >= current_date - interval '60 days' {% endif %}
  ```

- **Variante B — janela por `_carregado_em` (7d).** Fontes com watermark
  `S_T_A_M_P_` (que pega alteração em registro **antigo** — ex.: baixa num título
  velho). Uma janela por emissão **perderia** essas alterações; por isso o corte é
  pelo `_carregado_em` (que o extrator atualiza junto do `S_T_A_M_P_`). Fatos:
  `fato_contas_areceber`, `contas_apagar`, `apontamento_producao`, `pedidos`
  (`SE1`/`SE2`/`SC6`/`SD3`). Corte: `_carregado_em >= current_timestamp - interval '7 days'`.

A janela do rebuild deve ser **≥ a janela do extrator** (45d de emissão / 3d de
S_T_A_M_P_). Fora da janela, imutável. Primeira carga / `--full-refresh` é full.

**Validado (19/10/2026):** full-refresh `PASS=632/ERROR=0`; incremental reprocessa
só a janela na variante A (faturamento 4455, acordo 441, devoluções 391…) e é no-op
na B sem carga recente; totais idênticos antes/depois nos 11 fatos; teste de
cancelamento (recno marcado `D_E_L_E_T_='*'` some e volta ao reativar) — reversível.

---

## 6. Índices — o maior ganho de consulta

**Hoje:** **nenhum índice** nas tabelas de modelo (`prata_ouro`). Só
`controle_cargas`/`execucoes_manuais`. As telas do Oryon filtram por data,
filial, natureza e FKs de dimensão → *full scan*.

**Alvo:** índices via config nativa do dbt-postgres (`+indexes`), aplicados no
build. Padrão:

- **Fatos:** índice na **data** (recorte principal das telas) + nas **FKs de
  dimensão** mais filtradas (`sk_cliente`, `sk_produto`, `sk_vendedor`,
  `sk_natureza`, `filial`); **unique** na chave de negócio.
- **Dimensões:** **unique** na chave de negócio + na `sk_` (surrogate).

Exemplo (`fato_faturamento`):
```yaml
# em dbt_project.yml (por pasta) ou config() no modelo
+indexes:
  - columns: ['data_emissao']
  - columns: ['sk_cliente']
  - columns: ['sk_produto']
  - columns: ['filial', 'data_emissao']
  - columns: ['recno_origem'], unique: true
```

Validar com `EXPLAIN (ANALYZE)` numa query típica de tela antes/depois.

---

## 7. Robustez

- **`unique` no banco** na chave de negócio dos fatos (além do teste dbt) —
  ajuda o *planner* e blinda contra duplicata silenciosa. Via `+indexes ...
  unique: true`.
- **Membro "não identificado"** nos fatos já existe (coalesce +
  `generate_surrogate_key`) — **manter**; é boa prática.
- **Testes dbt** (unique/not_null/relationships) — manter cobertura; virar
  **gate de CI** na Fase de orquestração.
- **SCD (histórico de dimensão):** hoje não há (rebuild full). Tradeoff
  consciente para a v1; `snapshots` entram se/quando "como era" (ex.: vendedor
  do cliente em jan/25) virar requisito.

---

## 8. Plano de implementação (incrementos validados)

Cada passo: aplica → valida → commit na branch `deploy/prep-producao-vm`.
**Pré-requisito: Docker/Postgres do DW no ar** (para `dbt build`).

1. **Macro `generate_schema_name`** → `dbt build` gera `prata`/`ouro` limpos →
   atualizar constantes do backend Oryon + rebuild → conferir Board.
2. **Reorganizar models por domínio** + quebrar `_models.yml` → `dbt parse`/`build`.
3. **Índices** (`+indexes`) nos fatos/dims → `dbt build` + `EXPLAIN`.
4. **Incremental** nos fatos grandes → `dbt build` 2x + teste de cancelamento.
5. **`unique` no banco** nas chaves de negócio → `dbt build`.
6. **Atualizar `arquitetura.md`** e este doc com o estado final.

### Estado atual vs alvo (resumo)
| Dimensão | Hoje | Alvo |
|----------|------|------|
| Schemas | `prata_ouro`/`prata_prata` | `ouro`/`prata` |
| Organização | pastas achatadas | por domínio |
| Materialização fatos grandes | full rebuild | incremental (janela) |
| Índices | nenhum (nos modelos) | data + FKs + unique |
| Constraints | só testes dbt | + unique no banco |
| Documentação | arquitetura.md | + este doc |
