/* =====================================================================
   ALLES — Data Platform | Criacao das camadas
   ---------------------------------------------------------------------
   bronze  espelho fiel das tabelas de origem, sem nenhuma regra
   prata   conformado: tipos, TRIM, chaves de negocio, regras explicitas
   ouro    modelo dimensional e marts por dashboard

   Os schemas antigos (raw, dw) NAO sao tocados: continuam servindo de
   referencia de comparacao ate o comercial estar reconciliado.
   ===================================================================== */

CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS prata;
CREATE SCHEMA IF NOT EXISTS ouro;

COMMENT ON SCHEMA bronze IS 'Pouso fiel da origem. Sem filtro, sem TRIM, sem regra de negocio.';
COMMENT ON SCHEMA prata  IS 'Conformacao tecnica e aplicacao das regras de negocio explicitas.';
COMMENT ON SCHEMA ouro   IS 'Modelo dimensional (dim_/fato_) e marts (mart_) consumidos pelo Oryon Board.';
