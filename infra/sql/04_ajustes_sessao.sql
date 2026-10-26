-- =====================================================================
-- Ajustes de sessao do usuario `alles` (dbt, extrator e backup) no DW.
-- Idempotente; vale para NOVAS sessoes. Nao afeta o oryon_ro.
--
-- Por que existe (incidente de 26/10/2026): os pipelines travaram por horas.
-- As views da prata juntam bronze com `trim(a) = trim(b)`: expressao sem
-- estatistica, entao o planner estima mal e, conforme o volume muda, escolhe
-- nested loop sobre tabelas grandes (a consulta de teste do dbt em
-- prata.stg_comissao passou de 1h39 sem terminar; sem nested loop termina em
-- segundos). O dbt morto pelo timeout do systemd deixava a consulta ORFA no
-- Postgres, segurando bloqueio, e o ALTER TABLE do extrator do ciclo seguinte
-- ficava esperando indefinidamente.
--
--   enable_nestloop = off ...... remove o plano catastrofico (paliativo; a cura
--                                estrutural e tirar trim() das chaves de join).
--   statement_timeout .......... o servidor cancela sozinho consulta presa.
--   lock_timeout ............... espera de bloqueio falha com erro claro.
--   idle_in_transaction... ..... derruba sessao esquecida dentro de transacao.
-- =====================================================================
ALTER ROLE alles IN DATABASE alles_dw SET enable_nestloop = off;
ALTER ROLE alles IN DATABASE alles_dw SET statement_timeout = '60min';
ALTER ROLE alles IN DATABASE alles_dw SET lock_timeout = '10min';
ALTER ROLE alles IN DATABASE alles_dw SET idle_in_transaction_session_timeout = '30min';
