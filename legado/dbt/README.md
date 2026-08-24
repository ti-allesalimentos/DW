# dbt (fase de transformação)

Nesta fase o bloco de povoamento do fato (hoje em `sql/01_modelo_faturamento.sql`)
vira modelos dbt versionados e testados, nas camadas bronze → silver → gold.

Inicialização (quando chegarmos aqui):
    dbt init alles_dbt
