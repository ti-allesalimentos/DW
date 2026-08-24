# Fase 1 — Fundação do DW

> Plano de execução detalhado. Cada tarefa tem critério de aceite verificável.
> Referência de arquitetura: `docs/arquitetura.md` (v1.2).
> Executado pelo Claude Code local, na pasta `C:\Projetos\alles-dataplatform`.
> 20/08/2026.

**Meta da fase:** repositório versionado, camadas bronze/prata/ouro criadas, projeto
dbt configurado, extrator incremental funcionando e o bronze do comercial populado com
o histórico completo do Protheus.

**Não faz parte desta fase:** modelo dimensional do ouro, marts, dashboards. A Fase 1
entrega a fundação sobre a qual a Fase 2 constrói o comercial.

---

## T1 — Git e higiene do repositório

O projeto não tem histórico. Nada mais começa antes disso.

1. `git init` na raiz de `alles-dataplatform`.
2. `.gitignore` cobrindo: `.venv/`, `venv/`, `__pycache__/`, `*.pyc`, `.env`,
   `logs/`, `dados/`, `*.xlsx` de trabalho.
3. Commit inicial com o estado atual (serve de marco de "antes da reconstrução").
4. Criar repositório remoto **privado** e fazer o push.
5. **Verificação de segurança:** conferir se algum dos seis repositórios de relatório
   tem `.env` versionado — todos têm credenciais do Protheus no arquivo. Se houver,
   remover do histórico e rotacionar a senha do usuário de leitura.

**Aceite:** `git log` mostra o commit inicial; `git status` limpo; `git check-ignore .env`
retorna o arquivo; push no remoto concluído; nenhum `.env` rastreado em nenhum repo.

---

## T2 — Estrutura de pastas e schemas

Reorganizar o repositório para refletir as três camadas:

```
alles-dataplatform/
├── extracao/          # extrator incremental (substitui ingestion/)
│   ├── conexao.py
│   ├── watermark.py
│   ├── carga.py
│   ├── dominios.yml   # config por domínio
│   └── queries/       # SQL de origem, fiel, sem regra de negócio
├── transformacao/     # projeto dbt (bronze -> prata -> ouro)
├── infra/             # docker-compose, systemd units, scripts de manutenção
├── docs/
└── legado/            # sql/, dashboards/, ingestion/ antigos, preservados
```

No Postgres: criar `bronze`, `prata`, `ouro`. **Manter `raw` e `dw` intactos** — são a
referência de comparação durante a Fase 2 e só serão removidos quando o comercial
estiver reconciliado.

**Aceite:** `\dn` lista os cinco schemas; a estrutura de pastas acima existe; o código
antigo está em `legado/` e ainda roda.

---

## T3 — Tabela de controle de cargas

```sql
CREATE TABLE ouro.controle_cargas (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dominio         text NOT NULL,
    inicio          timestamptz NOT NULL DEFAULT now(),
    fim             timestamptz,
    watermark_de    date,
    watermark_ate   date,
    linhas_lidas    bigint,
    linhas_gravadas bigint,
    status          text NOT NULL,   -- 'rodando' | 'sucesso' | 'erro'
    mensagem_erro   text
);
CREATE INDEX ix_controle_dominio ON ouro.controle_cargas (dominio, inicio DESC);
```

O watermark de cada domínio é lido da última execução com `status = 'sucesso'`.

**Aceite:** tabela criada; uma execução de teste registra linha com `status='rodando'`
e a atualiza para `'sucesso'` ao final; consulta do watermark devolve a data correta.

---

## T4 — Extrator incremental

Substitui `ingestion/extract_protheus.py`. Comportamento por domínio:

1. Lê o watermark da última carga com sucesso.
2. Extrai do Protheus de `watermark − janela_movel` até hoje (janela padrão: 45 dias).
3. Grava em tabela de staging no bronze.
4. `MERGE` do staging para a tabela definitiva pela chave de negócio.
5. Marca como ausentes as linhas que sumiram da janela (cancelamentos de NF).
6. Registra o resultado em `ouro.controle_cargas`.

Configuração declarativa em `extracao/dominios.yml`:

```yaml
dominios:
  - nome: faturamento
    query: queries/faturamento.sql
    destino: bronze.faturamento
    chave_negocio: [filial, nfe, serie, item_nf]
    coluna_watermark: dt_emissao
    janela_movel_dias: 45
  - nome: clientes
    query: queries/clientes.sql
    destino: bronze.clientes
    modo: full          # dimensões: carga completa
```

Requisitos não-funcionais:

- **Idempotência:** rodar duas vezes seguidas não altera a contagem de linhas.
- **Atomicidade:** o MERGE roda em transação — falha no meio não deixa bronze parcial.
- **Modo carga inicial:** `--carga-inicial --de 2015 --ate 2026` processa por lotes
  anuais, avançando o watermark a cada lote concluído.

**Aceite:** duas execuções consecutivas do domínio faturamento produzem a mesma
contagem; interromper o processo no meio não deixa dados parciais; uma NF alterada no
Protheus dentro da janela aparece atualizada no bronze; `controle_cargas` registra
todas as execuções.

---

## T5 — Queries do bronze, sem regra de negócio

Reescrever as 11 queries de `ingestion/queries/` removendo tudo que é decisão:

| Remover | Motivo |
|---------|--------|
| Lista das 38 NFs excluídas | Vira `seed` versionado, aplicado na prata |
| `D2_CLIENTE <> '97316293'` | Vira exceção documentada, aplicada na prata |
| `D2_EMISSAO > '20250131'` | Não é regra — era o alcance da planilha. Sai de vez |
| Filtro de CFOP | Regra de negócio: vai para a prata, como seed de CFOPs de venda |
| Filtro de filial | Idem — seed de filiais ativas |

Manter: os joins estruturais (SD2←SF2, SC5, SA1) e **trazer `D_E_L_E_T_` como coluna**,
sem filtrar. Isso encerra a divergência `= ''` versus `<> '*'` descrita no capítulo 9 da
arquitetura: o bronze traz tudo, e a prata decide — uma vez só, documentadamente.

O `CLAUDE.md` do `relatorio-clevel-protheus-semanal` já lista os campos confirmados por
tabela e serve de referência para completar as queries.

**Aceite:** `count(*)` do bronze ≥ `count(*)` do `raw` atual para cada domínio; a
coluna `D_E_L_E_T_` existe e tem valores distintos; nenhuma query contém número de NF,
código de cliente ou CFOP literal.

---

## T6 — Carga inicial do histórico completo

A operação mais pesada do projeto. Ler todo o `SD2010` do Protheus de produção.

1. Rodar **fora do horário comercial**, um lote anual por vez.
2. Medir e registrar duração e impacto de cada lote antes de seguir para o próximo.
3. Abortar e reavaliar se algum lote degradar o ERP de forma perceptível.

**Aceite:** `bronze.faturamento` com todo o histórico disponível; duração por lote
registrada em `controle_cargas`; nenhuma reclamação de lentidão do ERP durante a janela.

---

## T7 — Projeto dbt

1. `dbt init` dentro de `transformacao/`, adaptador `dbt-postgres`.
2. `profiles.yml` lendo credenciais do `.env` — nunca com senha em arquivo versionado.
3. Declarar as tabelas do bronze como `sources`, com testes de frescor
   (`freshness`) para detectar carga que parou.
4. Um modelo de prata de referência — `stg_faturamento` — aplicando TRIM, casts de
   data, sentinela `1900-01-01` → NULL e a chave de cliente. Serve de padrão para os
   demais.
5. Seeds versionados: `map_produto_cx`, `excecoes_nf`, `excecoes_cliente`,
   `cfops_venda`, `cfops_devolucao`, `filiais_ativas`, `regiao`, `destino`,
   `motivo_dev`, `familia`.
6. Testes em `stg_faturamento`: unicidade da chave de negócio, `not_null` nas colunas
   obrigatórias, `accepted_values` no CFOP.

**Aceite:** `dbt build` termina verde; `dbt docs generate` produz o grafo de linhagem;
os seeds estão em CSV no git; nenhum seed vem de `P:\`.

---

## T8 — Calendário gerado por código

O `dCalendario.xlsx` deixa de ser fonte. Um modelo dbt gera a dimensão com:
ano/mês/trimestre/dia, nome de mês e dia da semana em português, dia útil,
**ano fiscal Abr–Mar**, mês fiscal e feriados (nacionais, estaduais e os municipais que
afetam as filiais).

**Aceite:** amostragem de 24 meses bate integralmente com o `dCalendario.xlsx` atual —
ano fiscal, dia útil e feriado inclusive. Divergência encontrada é investigada e
documentada antes de o gerado substituir a planilha.

---

## T9 — Documentação

`README.md` reescrito para o novo desenho e `docs/execucao.md` com o passo a passo
operacional: subir o ambiente, rodar carga inicial, rodar carga incremental, consultar
o controle de cargas, o que fazer quando uma carga falha.

**Aceite:** alguém que nunca viu o projeto consegue subir o ambiente e rodar uma carga
seguindo só a documentação.

---

## Verificação de fechamento da fase

Antes de declarar a Fase 1 concluída:

1. `dbt build` verde do zero, em ambiente limpo.
2. Duas cargas incrementais consecutivas sem alterar contagem.
3. `bronze.faturamento` com histórico completo e contagem ≥ `raw.faturamento`.
4. Comparação bronze × raw: divergências identificadas e explicadas — devem ser
   exatamente as linhas que o `raw` filtrava por regra de negócio, nada além.
5. Nenhuma credencial versionada em nenhum repositório.

---

## Dependências e riscos desta fase

- **`P:\T.I\01. BASES`** ainda precisa estar acessível para T7 (conversão das fontes
  manuais em seeds) e T8 (validação do calendário).
- **Janela de carga inicial (T6)** precisa ser combinada com quem opera o ERP.
- **Rotação de senha (T1)** pode exigir ajuste nos seis pipelines de relatório em
  produção — planejar para não derrubar o farol diário.
