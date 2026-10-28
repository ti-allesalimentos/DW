# Portal externo Alles — arquitetura (proposta v0.1)

> Portal web de dashboards para **representantes, clientes e fornecedores**, separado
> do Oryon. Complementa `docs/arquitetura.md` (DW) e `docs/operacao_warehouse.md`.
> Itens marcados **⏳** são decisões a confirmar; cada um traz a recomendação.
> Decidido em 26/10/2026: público externo => portal separado.

---

## 1. Objetivo e princípios

- **Público:** fase 1 representantes; fase 2 clientes; fase 3 fornecedores. Gestores
  internos entram no mesmo portal com perfil próprio.
- **Separar resultado de operação:** o Oryon segue como sistema operacional (balança,
  pátio, fiscal). O portal é analítico e só lê do DW.
- **Privacidade por padrão:** cada perfil vê o mínimo necessário (nunca custo, margem
  ou dados de outro cliente).
- **Isolamento em duas camadas:** o filtro por usuário vive na API **e** no banco, e a
  falha de uma não vaza dados (ver §4).
- **Uma fonte da verdade:** os marts do DW. O portal não calcula regra de negócio.

## 2. Perfis e escopo de dados

| Perfil | Enxerga | Não enxerga |
|---|---|---|
| **Representante** | sua carteira (clientes do seu código de vendedor): vendas, mix, positivação, meta x realizado, sua comissão, títulos dos seus clientes ⏳ | custo, margem, comissão de outros, outras carteiras |
| **Cliente** | seus pedidos, notas, títulos em aberto e histórico, devoluções, acordos | preço de outros clientes, custo, margem |
| **Fornecedor** | seus pedidos de compra, recebimentos, pagamentos | outros fornecedores, preços de terceiros |
| **Gestor interno** | conforme alçada (equipe, região, empresa) | — |
| **Admin do portal** | cadastro de usuários e escopos, auditoria | dados de negócio por padrão |

⏳ *Se o representante vê inadimplência dos clientes da carteira* e *se vê a própria
comissão* são regras comerciais: validar com a área antes da fase 1.

## 3. Arquitetura

```
 Internet ──443──> [ Proxy reverso + TLS + WAF/rate limit ]
                              │
                ┌─────────────▼──────────────┐        Microsoft Entra (OIDC)
                │  VM PORTAL (DMZ)           │◄────── login interno (SSO) e
                │  web (React, estático)     │        externo (convidados, MFA)
                │  API (FastAPI, só SELECT)  │
                └─────────────┬──────────────┘
                              │ 5433, somente deste IP
                ┌─────────────▼──────────────┐
                │  VM DW (192.168.66.11)     │   schema `portal` (views de escopo)
                │  Postgres: bronze/prata/   │   role `portal_ro` => SÓ `portal.*`
                │  ouro + portal             │   sem entrada da internet
                └────────────────────────────┘
```

- **A VM do DW nunca é exposta.** Ela guarda as credenciais do Protheus e todos os dados
  fiscais e financeiros.
- **VM própria para o portal, na DMZ** ⏳ (recomendado). Interino aceitável só para a fase
  interna: container na VM do DW, sem exposição externa; mover antes de abrir a externos.
- O portal não alcança o Protheus nem outras redes internas.

## 4. Camada de dados: schema `portal`

**Marts por perfil**, construídos pelo dbt do próprio repo do DW (`models/portal/`), no
mesmo ciclo do pipeline. Toda view carrega a **chave de escopo** (`cod_vendedor`,
`cod_cliente` ou `cod_fornecedor`) e só as colunas que o perfil pode ver.

**Role `portal_ro`:** `USAGE` no schema `portal` e `SELECT` nas suas views. **Nada** em
`bronze`, `prata` ou `ouro`.

**Escopo que falha fechado (a decisão central de segurança):**

1. Tabela `portal.escopo_usuario (user_id, tipo, codigo)`: quem enxerga o quê.
2. A API, a cada requisição e dentro da transação, executa
   `SET LOCAL portal.user_id = '<id do token>'`.
3. As views (`security_barrier`) fazem *join* com `escopo_usuario` usando
   `current_setting('portal.user_id', true)`.
4. **Sem o `SET` a view devolve zero linhas.** Uma rota que esquecer o filtro retorna
   vazio, e não o banco inteiro. Isso corrige a fraqueza apontada na `arquitetura.md` §7
   (alçada só no backend), que não serve para público externo.

**Mapas:** dimensão `dim_municipio_ibge` (código IBGE x UF/município do cadastro
Protheus) e malhas IBGE simplificadas, servidas como arquivos estáticos pelo portal.

**Frescor:** os dados refletem o último ciclo (até 2h). Toda tela mostra **"atualizado em"**.

## 5. Identidade e autorização

- **Login:** Microsoft Entra ⏳ (a empresa já usa Microsoft 365): SSO para internos e
  contas convidadas / External ID para externos, **MFA obrigatório**. Alternativa se houver
  restrição de licença: Keycloak.
- **Token OIDC** validado pela API; sessão curta com *refresh*; bloqueio e *rate limit* de
  tentativas.
- **Papéis** (rep, cliente, fornecedor, gestor, admin) controlam telas e endpoints; o
  **escopo de dados** vem do banco (§4).
- **Onboarding:** o admin do portal vincula o usuário ao código (vendedor SA3, cliente SA1
  ou rede, fornecedor SA2) em `escopo_usuario`, com trilha de auditoria.

## 6. Rede e hospedagem

| Origem | Destino | Porta | Regra |
|---|---|---|---|
| Internet | Proxy do portal | 443 | liberada (WAF + rate limit) |
| VM Portal | VM DW | 5433 | só o IP do portal |
| VM Portal | Entra / DNS / pacotes | 443 | saída |
| Internet | VM DW | — | **bloqueada** |
| VM Portal | Protheus / rede interna | — | **bloqueada** |

⚠ O Docker publica portas por fora do `ufw`: a restrição da 5433 precisa estar no
**firewall de rede**, e não só no host. Domínio e certificado (ex.: `portal.allesalimentos.com.br`) ⏳.

## 7. Stack (a que o time já domina)

- **Web:** React + Vite + TypeScript; **ECharts** (gráficos); **MapLibre GL** + malhas IBGE (mapas);
  design system próprio (tokens de cor, cards, filtros).
- **API:** FastAPI, SQLAlchemy somente leitura, Pydantic.
- **Repositório:** `ti-allesalimentos/alles-portal` (`/web`, `/api`, `/docs`); CI com testes.
- **Reaproveitamento:** as consultas das ~16 telas feitas (branch `feat/dw-integracao-gp` do
  Oryon, `modulos/bi`) viram a base da API, apontando para as views `portal.*`; os componentes
  React (cards, gráficos, funil de filtros) saem de `modulos/bi/components`.

## 8. Segurança e LGPD

- **Minimização:** sem CPF, sem custo, sem margem; nomes só do próprio escopo.
- **Auditoria:** log de acesso (quem viu o quê e quando), com retenção definida ⏳.
- **Base legal e termos de uso** com o jurídico ⏳ (execução de contrato / legítimo interesse).
- **Teste de isolamento no CI (bloqueante):** o usuário A nunca enxerga dado do B, em todas
  as telas e endpoints. É o teste mais importante do projeto.
- **Pentest** antes de abrir para externos; dependências atualizadas; segredos fora do git;
  monitoramento de falhas de login e de saúde.

## 9. Plano em fases

| Fase | Entrega | Saída |
|---|---|---|
| **0. Fundação** | repo, VM própria, Entra, domínio, tokens de design, esqueleto web + API | pronto para construir |
| **1. Portal interno** | as **50 telas da v1** (ver `docs/portal_produto.md`), login Entra, escopo por perfil, exportação | gestores e diretoria usando |
| **2. Endurecimento** | auditoria, LGPD, observabilidade, pentest | pronto para abrir a externos |
| **3. Representantes** | carteira, vendas, positivação, meta, comissão própria, em **mapa** | representantes piloto |
| **4. Clientes e fornecedores** | extrato, pedidos, títulos; pedidos de compra e pagamentos | externos piloto |

Prazos serão estimados após a Fase 0 (dependem de VM, Entra e jurídico).

## 10. Decisões abertas

| # | Decisão | Recomendação |
|---|---|---|
| 1 | VM própria para o portal (DMZ) | **Sim** |
| 2 | Provedor de login | **Microsoft Entra** |
| 3 | Primeiro público | **Representantes** |
| 4 | Representante vê comissão própria e inadimplência da carteira | validar com Comercial |
| 5 | Domínio, certificado e WAF | definir com a infra |
| 6 | Base legal, termos de uso e retenção de logs | validar com o jurídico |
| 7 | Quem mantém e dá suporte aos usuários externos | definir (SLA) |

## 11. Riscos

- **Vazamento entre clientes:** escopo que falha fechado + teste de isolamento no CI.
- **Carga no DW:** marts já agregados, cache e limites; réplica de leitura se crescer.
- **Defasagem de até 2h:** exibida em toda tela.
- **Suporte a externos:** processo e canal definidos antes da abertura.
- **Escopo crescente:** só entra tela que tenha dono de negócio e perfil definidos.
