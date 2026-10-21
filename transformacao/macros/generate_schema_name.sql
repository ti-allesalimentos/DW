{#
  Schemas limpos (bronze / prata / ouro), como define a arquitetura.

  O comportamento padrao do dbt concatena o schema do profile com o `+schema`
  do modelo (gerava `prata_prata` / `prata_ouro`). Aqui usamos o `+schema`
  verbatim; sem `+schema`, cai no schema do target (profiles.yml).
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema | trim }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
