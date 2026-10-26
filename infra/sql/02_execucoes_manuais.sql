/* =====================================================================
   ALLES — Execucoes manuais (trigger sob demanda)
   ---------------------------------------------------------------------
   Uma linha por clique em "rodar agora" no painel do Oryon. Cada
   execucao manual e extracao (de uma fonte ou de todas) seguida de
   `dbt build` — mesmo par que o ciclo automatico do systemd faz, so que
   disparado por fora em vez de esperar o timer de 2h.

   Nao substitui `ouro.controle_cargas` (que continua sendo o log por
   FONTE, tanto do ciclo automatico quanto do manual) — esta tabela loga
   a EXECUCAO como um todo (pode cobrir varias fontes + o dbt build).
   ===================================================================== */

CREATE TABLE IF NOT EXISTS ouro.controle_execucoes_manuais (
    id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fonte            text,                   -- NULL = todas as fontes
    solicitado_por   text,                   -- identificacao de quem pediu (vem do Oryon)
    solicitado_em    timestamptz NOT NULL DEFAULT now(),
    etapa            text        NOT NULL DEFAULT 'extracao', -- 'extracao' | 'dbt' | 'concluido' | 'erro'
    status           text        NOT NULL DEFAULT 'rodando',  -- 'rodando' | 'sucesso' | 'erro'
    mensagem_erro    text,
    concluido_em     timestamptz
);

CREATE INDEX IF NOT EXISTS ix_execucoes_manuais_status
    ON ouro.controle_execucoes_manuais (status)
    WHERE status = 'rodando';

COMMENT ON TABLE ouro.controle_execucoes_manuais IS
    'Historico de execucoes disparadas sob demanda pelo painel do Oryon (extracao + dbt build).';
