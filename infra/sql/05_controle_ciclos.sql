/* =====================================================================
   ALLES — Controle de ciclos automaticos
   ---------------------------------------------------------------------
   Uma linha por execucao do rodar_pipeline.sh (extracao + dbt). Existe
   pra quem consulta o DW (ex.: o portal) saber que um ciclo esta em
   andamento tambem durante a etapa do dbt, quando ja nao ha linhas
   'rodando' em ouro.controle_cargas.
   ===================================================================== */
CREATE TABLE IF NOT EXISTS ouro.controle_ciclos (
    id      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    inicio  timestamptz NOT NULL DEFAULT now(),
    fim     timestamptz,
    etapa   text        NOT NULL DEFAULT 'extracao',   -- 'extracao' | 'dbt' | 'concluido'
    status  text        NOT NULL DEFAULT 'rodando'     -- 'rodando' | 'sucesso' | 'erro'
);

CREATE INDEX IF NOT EXISTS ix_ciclos_status
    ON ouro.controle_ciclos (status)
    WHERE status = 'rodando';

COMMENT ON TABLE ouro.controle_ciclos IS
    'Historico dos ciclos automaticos (extracao + dbt). Linha em ''rodando'' ha muito tempo = ciclo morto.';

/* Resultado do dbt build do ciclo (lido de target/run_results.json ao fim do build). */
ALTER TABLE ouro.controle_ciclos
    ADD COLUMN IF NOT EXISTS dbt_ok        integer,
    ADD COLUMN IF NOT EXISTS dbt_aviso     integer,
    ADD COLUMN IF NOT EXISTS dbt_erro      integer,
    ADD COLUMN IF NOT EXISTS dbt_ignorado  integer,
    ADD COLUMN IF NOT EXISTS dbt_problemas jsonb;   -- [{no, status, mensagem}] so de aviso/erro

/* Quem disparou o ciclo: 'systemd' (timer ou systemctl start) ou 'terminal:<usuario>' (rodado na mao). */
ALTER TABLE ouro.controle_ciclos ADD COLUMN IF NOT EXISTS origem text;
