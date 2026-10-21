-- =====================================================================
-- Grants da role de leitura do Oryon Board (oryon_ro) no DW.
--
-- O backend do Oryon conecta como oryon_ro (DW_POSTGRES_USER) e le
-- EXCLUSIVAMENTE o schema `ouro`. Idempotente: rodar uma vez na VM depois
-- de criar a role.
--
-- A role e criada fora do git (a senha vive no .env do backend do Oryon):
--   CREATE ROLE oryon_ro LOGIN PASSWORD 'defina_a_senha';
-- =====================================================================

-- Leitura do ouro (dimensional + marts que o Board consome).
GRANT USAGE ON SCHEMA ouro TO oryon_ro;
GRANT SELECT ON ALL TABLES IN SCHEMA ouro TO oryon_ro;

-- Objetos novos criados pelo dbt (role `alles`) ja nascem legiveis p/ oryon_ro.
-- Sem isto, cada `dbt build` (que recria as tabelas do ouro) revogaria o acesso
-- e o Board pararia de ler ate um GRANT manual.
ALTER DEFAULT PRIVILEGES FOR ROLE alles IN SCHEMA ouro
    GRANT SELECT ON TABLES TO oryon_ro;
