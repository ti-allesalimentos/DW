# Fase 1 — Fundação do DW

> Plano de **execução**. O código da fundação já está no repositório desde 24/08/2026;
> o que resta é rodar, conferir e fechar cada critério de aceite.
> Referência de arquitetura: `docs/arquitetura.md` (v1.5).
> Operação passo a passo: `docs/execucao.md`.
> Executado pelo Claude Code local, em `C:\Projetos\alles-dataplatform`.
> Versão 2 — 24/08/2026.

**Meta da fase:** repositório versionado, camadas `bronze`/`prata`/`ouro` criadas,
extrator incremental funcionando, `dbt build` verde e o `bronze.sd2010` populado com
todo o histórico do Protheus.

**Não faz parte desta fase:** modelo dimensional do ouro, marts, dashboards.

---

## O que já está no repositório

| Componente | Arquivos |
|---|---|
| Extrator | `extracao/conexao.py`, `watermark.py`, `carga.py`, `fontes.yml` |
| DDL | `infra/sql/00_schemas.sql`, `01_controle_cargas.sql` |
| Ambiente | `infra/docker-compose.yml`, `.env.example`, `requirements.txt` |
| dbt | `transformacao/` — projeto, macros, sources, `stg_faturamento`, 6 seeds |
| Documentação | `README.md`, `docs/execucao.md` |
| Legado preservado | `legado/` — ingestion, sql, dashboards, dagster, dbt, config |

**Nada foi executado ainda.** Não há git, o Postgres novo não subiu, nenhuma carga rodou.

---

## Decisões de desenho que o código já reflete

**O bronze espelha tabelas do Protheus, não queries de domínio.** A query de referência
usava `INNER JOIN` com `SC5010` e `SA1010` — e um INNER JOIN é decisão de negócio
disfarçada de detalhe técnico: descarta silenciosamente todo item sem pedido ou sem
cliente. No pouso fiel isso não pode existir. Cada tabela é extraída uma vez e serve aos
nove domínios; os joins acontecem na prata.

**`R_E_C_N_O_` é a chave do MERGE.** É único por tabela no Protheus, o que dispensa
chave de negócio composta e torna o incremental trivial.

**`SELECT *` no bronze.** Pouso fiel de verdade, e traz de graça os campos customizados
(`_X_`) que a Alles criou — que nenhum inventário mapeou por completo.

---

## T1 — Git e segurança *(pré-requisito de tudo)*

O projeto não tem histórico. Nada mais começa antes disso.

1. `git init` na raiz.
2. Conferir o `.gitignore` já entregue: deve cobrir `.env`, `.venv/`, `__pycache__/`,
   `target/`, `dbt_packages/`, `profiles.yml`, `*.tgz`.
3. Commit inicial — marco do "antes da reconstrução".
4. Criar repositório remoto **privado** e fazer o push.
5. **Verificação de segurança:** conferir se algum dos seis repositórios em
   `C:\Projetos\relatorio-*` tem `.env` versionado. Todos têm credenciais do Protheus
   dentro. Se algum estiver no histórico do git, a senha do usuário de leitura está
   exposta.

**Aceite:** `git log` mostra o commit inicial; `git status` limpo;
`git check-ignore .env` retorna o arquivo; push concluído; nenhum `.env` rastreado em
nenhum repositório.

**Atenção:** rotacionar a senha exige ajustar os seis pipelines em produção. Planejar
para não derrubar o farol diário — é o único ponto desta fase que toca no que roda hoje.

---

## T2 — Ambiente e camadas

```bash
cp .env.example .env      # preencher; usuário do Protheus SOMENTE LEITURA
python -m venv .venv && .venv\Scripts\activate
pip install -r requirements.txt
docker compose -f infra/docker-compose.yml up -d
psql ... -f infra/sql/00_schemas.sql
psql ... -f infra/sql/01_controle_cargas.sql
```

O extrator exige o **ODBC Driver 18 for SQL Server**.

Os schemas `raw` e `dw` do piloto anterior **ficam intactos** — são a referência de
comparação da T7 e só saem quando o comercial estiver reconciliado.

**Aceite:** `\dn` lista `bronze`, `prata`, `ouro`, `raw`, `dw`;
`select * from ouro.vw_saude_cargas` responde (vazia).

---

## T3 — Primeira carga e prova de idempotência

Começar pequeno. `SB1010` é cadastro de produtos: rápido, e exercita conexão, criação
de tabela, MERGE e registro de controle.

```bash
python -m extracao.carga --listar          # só imprime o plano, não toca em nada
python -m extracao.carga --fonte SB1010
python -m extracao.carga --fonte SB1010    # de novo — a contagem não pode mudar
```

**Aceite:** `bronze.sb1010` populada com PK em `r_e_c_n_o_`; duas execuções seguidas
produzem contagem idêntica; `ouro.controle_cargas` tem duas linhas com
`status = 'sucesso'`.

Este é o teste que importa antes de qualquer coisa pesada. Se a idempotência falhar
aqui, falha em escala no `SD2010`.

---

## T4 — Demais cadastros

```bash
python -m extracao.carga --fonte SA1010    # clientes
python -m extracao.carga --fonte SA3010    # vendedores
python -m extracao.carga --fonte SA2010    # fornecedores
python -m extracao.carga --fonte SE4010    # condições de pagamento
python -m extracao.carga --fonte SC6010    # itens de pedido
```

Todos em carga full — são pequenos e mutáveis.

**Aceite:** cada tabela do bronze com contagem plausível contra o `raw` correspondente;
nenhuma carga com `status = 'erro'`.

---

## T5 — dbt

```bash
cd transformacao
dbt deps
dbt seed        # carrega as regras versionadas
dbt build       # modelos + testes
dbt docs generate
```

O `stg_faturamento` depende do `bronze.sd2010`, então só ficará verde depois da T6 —
até lá, rodar `dbt seed` e `dbt build --select seeds` para validar as regras.

**Aceite dos seeds:** `prata.map_produto_cx` com **10 linhas** (não 8);
`prata.excecoes_nf` com 38; testes de unicidade verdes.

---

## T6 — Carga inicial do histórico

A operação mais pesada do projeto: ler todo o `SD2010` do Protheus **de produção**.
O histórico começa em **01/02/2025**, data de entrada do ERP — nada antes disso é
faturamento.

```bash
python -m extracao.carga --fonte SD2010 --carga-inicial
```

Regras, não sugestões:

1. **Fora do horário comercial**, combinado com quem opera o ERP.
2. Lote anual. **Medir cada lote antes de seguir** — a duração fica em
   `ouro.controle_cargas`.
3. Se um lote degradar o ERP de forma perceptível, **parar**. O watermark preserva o
   que já entrou; retomar é seguro.

Depois: `SF2010`, `SD1010`, `SF1010`, `SC5010` — mesma mecânica, volumes menores.

**Aceite:** `bronze.sd2010` com o histórico completo; duração por lote registrada;
nenhuma reclamação de lentidão do ERP.

---

## T7 — Conferência contra o legado

Agora o `dbt build` completo deve fechar.

```sql
-- Bronze traz MAIS que o raw: ele não filtra regra de negócio.
select count(*) from bronze.sd2010;
select count(*) from raw.faturamento;

-- A prata, com as regras aplicadas, deve se aproximar do raw.
select count(*), sum(total) from prata.stg_faturamento;
```

A diferença entre `bronze` e `prata` tem que ser **exatamente** o que os seeds filtram:
CFOP fora da lista, filial inativa, cliente excluído, nota na lista de exceções,
`d_e_l_e_t_ = '*'`. Nada além.

```sql
-- Quanto cada regra descarta — se algum número surpreender, investigar antes de seguir.
select
    count(*) filter (where d_e_l_e_t_ = '*')                                as deletados,
    count(*) filter (where btrim(d2_cf) not in (select cfop from prata.cfops_venda))   as fora_cfop,
    count(*) filter (where btrim(d2_filial) not in (select filial from prata.filiais_ativas)) as fora_filial
from bronze.sd2010;
```

**Aceite:** toda divergência entre `prata.stg_faturamento` e `raw.faturamento`
identificada e explicada, registrada em `docs/reconciliacao_comercial.md`.

---

## T8 — Calendário gerado por código *(ainda a escrever)*

O `dCalendario.xlsx` deixa de ser fonte. Um modelo dbt gera a dimensão: ano, mês,
trimestre, dia, nomes em português, dia útil, **ano fiscal Abr–Mar**, mês fiscal e
feriados (nacionais, estaduais e os municipais que afetam as filiais).

**Aceite:** amostragem de 24 meses bate integralmente com o `dCalendario.xlsx` —
ano fiscal, dia útil e feriado inclusive. Divergência é investigada e documentada
antes de o gerado substituir a planilha.

---

## T9 — Seeds das demais fontes manuais *(ainda a escrever)*

Converter em CSV versionado, a partir do `fManual.xlsx` (`P:\T.I\01. BASES`, já
acessível): `familia`, `regiao`, `destino`, `motivo_dev`, `grupos`, `contas`.

**Aceite:** nenhum seed lê de `P:\` em tempo de execução; todos versionados no git.

---

## Fechamento da fase

1. `dbt build` verde do zero, em ambiente limpo.
2. Duas cargas incrementais consecutivas sem alterar contagem.
3. `bronze.sd2010` com histórico completo desde 01/02/2025.
4. Divergências `prata` × `raw` explicadas uma a uma — só as regras dos seeds.
5. Nenhuma credencial versionada em nenhum repositório.

---

## Riscos desta fase

- **Janela da carga inicial (T6)** precisa ser combinada com quem opera o ERP.
- **Rotação de senha (T1)** pode exigir ajuste nos seis pipelines em produção.
- **`SELECT *` no bronze** traz tabelas largas (o `SD2010` tem centenas de colunas).
  Se o volume incomodar, `fontes.yml` aceita lista explícita de colunas — mas isso
  troca fidelidade por espaço, e a decisão deve ser consciente.

---

## Regra permanente

**Nada do que está rodando é alterado.** `atualizador_1.9.xlsm`, os workbooks de
`P:\T.I\01. BASES`, os relatórios do Power BI e os seis pipelines seguem intocados.
Este DW nasce ao lado. A única exceção prevista é a rotação de senha da T1, e ela é
planejada, não incidental.
