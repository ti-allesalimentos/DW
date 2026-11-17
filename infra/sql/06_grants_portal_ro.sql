-- =====================================================================
-- Grants da role de leitura do Portal Alles (portal_ro) no DW.
--
-- A API do portal conecta como portal_ro e le EXCLUSIVAMENTE o schema `ouro`
-- (controle de cargas/ciclos/execucoes + tabelas ouro dos paineis). Idempotente.
-- A role e criada fora do git (a senha vive no .env do portal):
--   CREATE ROLE portal_ro LOGIN PASSWORD 'defina_a_senha';
--   GRANT CONNECT ON DATABASE alles_dw TO portal_ro;
-- =====================================================================
GRANT USAGE ON SCHEMA ouro TO portal_ro;
GRANT SELECT ON ALL TABLES IN SCHEMA ouro TO portal_ro;

-- Tabelas recriadas pelo dbt (role `alles`) ja nascem legiveis p/ portal_ro.
ALTER DEFAULT PRIVILEGES FOR ROLE alles IN SCHEMA ouro
    GRANT SELECT ON TABLES TO portal_ro;
