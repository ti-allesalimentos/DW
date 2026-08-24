{#
  Macros de conformacao do Protheus.
  Existem para que a mesma tratativa nao seja reescrita (e divergida)
  em cada modelo — que e exatamente o defeito do legado.
#}

{% macro trim_protheus(coluna) %}
    {#- Campos texto do Protheus sao CHAR de largura fixa e chegam com
        padding. Sem TRIM, nenhum join funciona e o de-para -CX nunca
        dispara. Vazio vira NULL. -#}
    nullif(btrim({{ coluna }}), '')
{% endmacro %}


{% macro data_protheus(coluna) %}
    {#- Datas no Protheus sao texto 'YYYYMMDD'. Vazio, espacos e a
        sentinela '19000101' viram NULL. -#}
    case
        when btrim({{ coluna }}) ~ '^\d{8}$'
             and btrim({{ coluna }}) <> '19000101'
        then to_date(btrim({{ coluna }}), 'YYYYMMDD')
    end
{% endmacro %}
