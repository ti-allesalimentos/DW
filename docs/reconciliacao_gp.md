# Reconciliação — Gestão de Pessoas (Fase 12, integração Oryon Board)

> Diferente de `docs/reconciliacao_comercial.md`, este documento **não fecha**
> ainda com "divergência zero" — registra o que foi comparado, o que foi
> corrigido no `ouro`, e o que falta rodar ao vivo (Docker/Postgres
> indisponíveis no momento desta análise) antes de repontar
> `modulos/bi/gp_dashboard.py` do Oryon pro DW.

## Por que este documento existe

O Lucas confirmou: **os números do Oryon Board — GP já foram 100%
reconferidos** contra a planilha do RH. Isso inverte a relação de
confiança de uma migração normal — aqui o Oryon é a referência, e é o
`ouro` do DW que precisa provar que bate com ele, não o contrário.
Comparei regra a regra `modulos/bi/gp_extract.py` +
`gp_headcount.py`/`gp_turnover.py`/`gp_banco_horas.py`/`gp_hora_extra.py`
(Oryon) contra o `ouro` da Fase 10 (`alles-dataplatform`) antes de tocar
em qualquer conexão.

## O que já existia no `ouro` e batia

- `dim_funcionario` (SRA010): admissão/demissão, situação, salário,
  jornada, periculosidade/insalubridade — mesmas colunas e mesma
  fórmula que `SQL_FUNCIONARIOS`. A sentinela de demissão `19000101` já
  virava `NULL` via `data_protheus()`, igual ao `> DATE '1901-01-01'`
  do Oryon.
- `fato_dupla_funcao` (RG1010, verba 174 sem data fim) — regra idêntica
  a `SQL_DUPLA_FUNCAO`.
- `fato_historico_salarial` (SR3010) — histórico completo; o Oryon
  filtra `data > 2023-12-01`, mas isso é um corte de janela, não uma
  regra de dado — fica pro consumidor.

## Divergências encontradas e corrigidas

1. **`dim_funcionario` não excluía sócio (matrícula `1xxxxx`) nem PJ
   (`9xxxxx`).** O Oryon exclui de propósito — "sem isso o headcount
   conta ~9 a mais por mês" (comentário do próprio `gp_extract.py`).
   **Corrigido**: adicionado `ra_mat not like '1%' and ra_mat not like
   '9%'` no `dim_funcionario.sql`. Verificado que os dois consumidores
   existentes (`fato_dupla_funcao`, `fato_historico_salarial`) fazem
   `left join` com fallback `NAO_IDENTIFICADO` — não perdem linha, só
   deixam de resolver o `sk_funcionario` pra esse recorte residual, que
   o Oryon também não usa.

2. **`fato_motivo_rescisao` existente não serve o Turnover.** Ele junta
   SRG010+SRA010+RCC010+SRR010 (inner join) pra trazer o **valor pago**
   da rescisão — é a fonte de `MOTIVORESCISAO.m`, um relatório
   diferente. O Turnover do Oryon usa uma population mais simples
   (SRG010+SRA010, sem RCC010/SRR010) e uma classificação
   Voluntário/Involuntário por um mapa fixo de 18 códigos
   (`MOTIVOS_RESCISAO` em `gp_turnover.py`) — o próprio docstring do
   `stg_motivo_rescisao.sql` já sinalizava que esse "subconjunto
   estrito" nunca tinha sido construído à parte.
   **Corrigido**: novo par `stg_rescisao_rh.sql` (prata, SRG010 cru) +
   `fato_rescisao_rh.sql` (ouro, inner join em `dim_funcionario` — que já
   exclui sócio/PJ e resolve nome/CC, equivalente ao `INNER JOIN SRA010`
   do Oryon) + seed `motivos_rescisao_rh.csv` (cópia literal do mapa
   fixo validado, incluindo o código 18 classificado por decisão do
   Lucas). `fato_motivo_rescisao` não foi tocado — continua servindo
   quem já o usa.

3. **Três fontes não tinham NENHUM modelo prata/ouro** (existiam só no
   bronze): ausências (`SR8010`), banco de horas (`SPI010`) e
   apontamento de hora extra (`SPC010`+`SPH010`). Sem elas, headcount
   (regra de "afastado"), Banco de Horas e Hora Extra do Board não têm
   como sair do `ouro`.
   **Construído**:
   - `stg_ausencias` / `fato_ausencia` — conforma as colunas
     (`tipo_afastamento`, `dt_inicio`, `dt_fim`, `duracao_dias`); a
     avaliação "está afastado numa data X" é ponto-no-tempo e fica pro
     consumidor (mesmo desenho do `_AFASTADO` do Oryon, que é um
     fragmento de SQL parametrizado, não uma coluna).
   - `stg_banco_horas` / `fato_banco_horas` — agregação por funcionário
     já com a conversão base-60→decimal (`FLOOR + resto/0,6`), crédito
     (verba `010`) e débito (verba `014`), só lançamentos em aberto
     (`PI_DTBAIX` vazio). Inner join em `dim_funcionario` (não left +
     `NAO_IDENTIFICADO`) — replica o `JOIN` (não `LEFT JOIN`) do Oryon.
   - `stg_apontamento_hora_extra` / `fato_hora_extra` — união
     SPC010+SPH010, mesma conversão base-60, mesmos códigos de verba
     (001/003/007/008/009) e mesma classificação por tipo. **O valor em
     R$ não entra no `ouro`**: depende de `gp_salario_minimo`, um
     cadastro manual do RH sem nenhuma origem no Protheus — colocá-lo
     no DW seria forçar um dado que não é do ERP pra dentro da camada
     errada. O Oryon continua calculando o valor (agora lendo
     salário/periculosidade/insalubridade/dupla-função do `ouro`, e o
     salário mínimo do seu próprio cadastro).

## O que **não** mudou (de propósito)

- `gp_colaboradores_manuais` e `gp_salario_minimo` continuam no Postgres
  do Oryon — são cadastro manual do RH, sem origem no Protheus. Não há
  o que "integrar ao DW" aqui.
- `modulos/bi/gp_extract.py`, `gp_worker.py` e as tabelas `gp_src_*`
  **não foram removidos nem alterados**. O corte de chave só acontece
  depois que os números baterem ao vivo (próxima seção).

## `dbt build` — rodado (14/09/2026)

Assim que o Docker voltou: **`dbt build` completo, 617 PASS / 0 ERROR**
(1 warning pré-existente e sem relação, em `stg_faturamento_datavale`).
Os 9 modelos novos/alterados desta rodada passaram limpos, incluindo os
testes de unicidade/not-null.

## Verificação por plausibilidade (rodada no `ouro`, hoje)

Sem acesso ao Postgres do Oryon (ver limitação abaixo), conferi que os
números saem em ordem de grandeza plausível e sem sujeira:

- `dim_funcionario`: 880 linhas em `bronze.sra010` → 14 excluídas por
  matrícula sócio/PJ → 866 em `dim_funcionario`. Bate exato (880−14=866).
- `fato_rescisao_rh`: 505 rescisões, **zero** código sem classificação
  (todo `RG_TIPORES` encontrado nos dados bateu com um dos 18 da seed) —
  313 INVOLUNTÁRIO + 192 VOLUNTÁRIO.
- `fato_ausencia`: 2.262 registros; 77 qualificam a regra bruta de
  "afastado" (tipo≠'001' e duração>15).
- `fato_banco_horas`: 320 funcionários, saldo entre -70,67 e +35,45 h,
  média -15,97 h.
- `fato_hora_extra`: 4.910 linhas de HE 50% (49.031,9 h) e 625 de HE DSR
  100% (7.366,7 h). Nenhuma linha de HE DIA NT 100% no período — não é
  erro, só não ocorreu apontamento desse tipo.

Nada disso pega o tipo de erro que mais importa aqui: **se o `ouro`
bate exatamente com o que a tela do Oryon mostra hoje.** Isso só se
confirma comparando com o Oryon rodando.

## Limitação encontrada: não alcanço o Postgres do Oryon

O container `maestro_postgres` (Oryon) **não existe nesta máquina** —
roda em outro ambiente. Não dá pra cruzar `gp_src_*` direto daqui. Pra
fechar a reconciliação, comparem os números abaixo (calculados no `ouro`
agora, replicando exatamente as regras de `gp_headcount.py`/
`gp_turnover.py`/`gp_banco_horas.py`) contra os cartões da tela GP do
Oryon Board **ao vivo**:

| Métrica (DW, hoje 14/09/2026, ref = fim do mês corrente 30/09) | Valor |
|---|---|
| Com vínculo (sem PJ) | 358 |
| Afastados | 14 |
| **Headcount base (sem PJ)** — comparar com `headcount_atual` **menos** o número de PJ/sócios ativos no cadastro manual | **344** |
| Admitidos em setembro (sem PJ) | 0 |
| Demitidos em setembro (sem PJ) | 0 |
| Saldo banco de horas (soma de todos) | -5.111,25 h (crédito 4.781,53 − débito 9.892,78) |

Query pra reproduzir o headcount (mesma lógica de `_COM_VINCULO`/`_AFASTADO`
de `gp_headcount.py`, contra `alles_dw`):

```sql
with ref as (select (date_trunc('month', now()) + interval '1 month - 1 day')::date as eom),
com_vinculo as (
  select f.sk_funcionario
  from prata_ouro.dim_funcionario f, ref
  where f.chave_funcionario <> 'NAO_IDENTIFICADO'
    and f.dt_admissao <= ref.eom
    and (f.dt_demissao is null or f.dt_demissao > ref.eom)
),
afastados as (
  select distinct cv.sk_funcionario
  from com_vinculo cv
  join prata_ouro.fato_ausencia a on a.sk_funcionario = cv.sk_funcionario, ref
  where a.tipo_afastamento <> '001' and coalesce(a.duracao_dias,0) > 15
    and a.dt_inicio <= ref.eom
    and (case when a.dt_fim > a.dt_inicio then a.dt_fim end is null
         or (case when a.dt_fim > a.dt_inicio then a.dt_fim end) >= ref.eom)
)
select (select count(*) from com_vinculo) as com_vinculo,
       (select count(*) from afastados) as afastados,
       (select count(*) from com_vinculo) - (select count(*) from afastados) as headcount_base;
```

**Passo final, ainda pendente à época**: abrir a tela GP do Oryon Board (com o
backend/Protheus reais) e comparar `headcount_atual − PJ ativos` contra
`344`, e os KPIs de Turnover/Banco de Horas/Hora Extra contra a tabela
acima. Isso foi feito depois (screenshots ao vivo do Oryon, ver histórico da
conversa) e bateu exato — headcount, turnover e banco de horas idênticos.

## Decisão de arquitetura do cutover (2026-09-21)

Em vez de reescrever `gp_headcount.py`/`gp_turnover.py`/`gp_banco_horas.py`/
`gp_hora_extra.py` pra ler direto do `ouro` (como o plano original acima
sugeria), a estratégia adotada foi **trocar só a fonte de `gp_extract.py`**:

- `gp_extract.py` agora faz `SELECT` no DW (schema `ouro`, materializado como
  `prata_ouro` no Postgres físico — usuário `oryon_ro`, só leitura) em vez do
  Protheus via `pymssql`, mas **grava exatamente nas mesmas tabelas staging**
  (`gp_src_funcionarios`, `gp_src_cc`, `gp_src_ausencias`, `gp_src_banco_horas`,
  `gp_src_rescisoes`, `gp_src_he_apontamentos`, `gp_src_salario_hist`,
  `gp_src_dupla_funcao`), com as mesmas colunas de sempre.
- `gp_headcount.py`, `gp_turnover.py`, `gp_banco_horas.py`, `gp_hora_extra.py`,
  `gp_worker.py` e `gp_dashboard.py` **não mudam uma linha** — continuam lendo
  só a staging local do Oryon, sem saber que a origem trocou.
- Motivo: evita reimplementar a mesma regra de negócio (predicado de afastado,
  dedup por CPF, overlay de PJ, valoração de HE) em dois lugares — a lógica
  já validada fica onde sempre esteve, só a fonte de dado crú muda.
- `dim_funcionario` ganhou a coluna `cpf` (`ra_cic`), que faltava — o Oryon
  usa CPF pra desduplicar pessoa com mais de uma matrícula (transferência/
  readmissão); sem ela, o dedup do `gp_headcount.py` (`_PESSOA`) quebraria.
- Criado o usuário `oryon_ro` no Postgres do DW: `SELECT` em `prata_ouro` e
  `ouro`, sem `INSERT`/`UPDATE`/`DELETE` — testado (leitura ok, escrita nega
  com `permission denied`).

**Verificação rodada em 2026-09-21** (branch `feat/dw-integracao-gp`, worktree
`oryon-dw-integracao`), com as queries exatas de `gp_extract.py` executadas
contra o DW via `oryon_ro`:

| Métrica | DW (agora) | Validado ao vivo anteriormente | Nota |
|---|---|---|---|
| Saldo banco de horas — crédito | 4.763,93 h (4763:56) | 4763:56 | **idêntico** |
| Saldo banco de horas — débito | 9.837,90 h (9837:54) | 9837:54 | **idêntico** |
| Saldo banco de horas — líquido | -5.073,97 h (-5073:58) | -5073:58 | **idêntico** |
| Admitidos no mês corrente (sem PJ) | 16 | 16 | idêntico |
| Demitidos no mês corrente (sem PJ) | 4 | 4 | idêntico |
| Com vínculo (sem PJ, ref = fim do mês corrente) | 370 | 358 (draft antigo, não é o número final validado) | diverge — **esperado**, são 7 dias de admissões/afastamentos reais a mais |
| Afastados | 15 | — | — |

O banco de horas e admitidos/demitidos batem exato — forte sinal de que o
mapeamento de coluna em `gp_extract.py` está correto (essas métricas não têm
motivo pra mudar sozinhas). O headcount mudou porque o tempo passou (dados
reais de RH mudam todo dia), não por causa da troca de fonte — confirmado
rodando a MESMA query dos dois jeitos (com e sem dedup por pessoa) contra o
dado de hoje: os dois métodos dão 370, sem nenhuma matrícula duplicada por
CPF no momento. **Falta**: abrir o Oryon Board ao vivo agora e comparar
headcount/turnover/banco de horas atuais contra estes números antes de
considerar o cutover pronto pra produção.

**Status**: código escrito e commitado na branch `feat/dw-integracao-gp`
(worktree isolado, `main` do Oryon intocado). **Ainda não deployado** — falta
(1) configurar `DW_POSTGRES_*` no `.env` real do Oryon com as credenciais do
usuário `oryon_ro`, (2) comparar os números acima contra a tela ao vivo, (3)
decisão do Lucas pra fazer merge/deploy.
