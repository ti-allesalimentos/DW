/* =====================================================================
   ALLES — Controle de cargas
   ---------------------------------------------------------------------
   Uma linha por execucao de extracao. E daqui que sai o watermark:
   a proxima carga comeca em (ultima carga com sucesso - janela movel).
   ===================================================================== */

CREATE TABLE IF NOT EXISTS ouro.controle_cargas (
    id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fonte            text        NOT NULL,   -- ex.: 'protheus.SD2010'
    inicio           timestamptz NOT NULL DEFAULT now(),
    fim              timestamptz,
    watermark_de     date,                   -- inicio da janela extraida
    watermark_ate    date,                   -- fim da janela extraida
    linhas_lidas     bigint,
    linhas_gravadas  bigint,
    modo             text,                   -- 'incremental' | 'full' | 'carga_inicial'
    status           text        NOT NULL,   -- 'rodando' | 'sucesso' | 'erro'
    mensagem_erro    text
);

CREATE INDEX IF NOT EXISTS ix_controle_fonte
    ON ouro.controle_cargas (fonte, inicio DESC);

CREATE INDEX IF NOT EXISTS ix_controle_status
    ON ouro.controle_cargas (status)
    WHERE status <> 'sucesso';

COMMENT ON TABLE ouro.controle_cargas IS
    'Historico de execucoes da extracao. Fonte do watermark e base do monitoramento.';

/* ---------------------------------------------------------------------
   Visao de saude: ultima carga de cada fonte e ha quanto tempo.
   Serve de alerta operacional e de teste de frescor no dbt.
   --------------------------------------------------------------------- */
CREATE OR REPLACE VIEW ouro.vw_saude_cargas AS
SELECT DISTINCT ON (fonte)
       fonte,
       status,
       inicio,
       fim,
       linhas_gravadas,
       watermark_ate,
       now() - inicio AS desde_ultima_carga
FROM ouro.controle_cargas
ORDER BY fonte, inicio DESC;
