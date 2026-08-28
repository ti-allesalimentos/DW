{#
  Macros de conformacao do historico DATAVALE (ERP anterior ao Protheus).
  Formatos diferentes do Protheus: numero em pt-BR com virgula decimal e
  "-" para vazio; data DD/MM/YYYY em vez de YYYYMMDD.
#}

{% macro numero_br(coluna) %}
    {#- "-" e vazio viram NULL; separador de milhar (.) removido, decimal (,) vira ponto. -#}
    case
        when btrim({{ coluna }}) in ('-', '') then null
        else replace(replace(btrim({{ coluna }}), '.', ''), ',', '.')::numeric
    end
{% endmacro %}


{% macro data_br(coluna) %}
    case
        when btrim({{ coluna }}) = '' then null
        else to_date(btrim({{ coluna }}), 'DD/MM/YYYY')
    end
{% endmacro %}
