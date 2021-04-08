{#
    Renders a schema name given a custom schema name. In production, this macro
    will render out the overridden schema name for a model. Otherwise, the default
    schema specified in the active target is used.

    custom_schema_name: The custom schema name specified for a model, or none
    node: The node the schema is being generated for

#}

{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if target.name == 'production' and custom_schema_name is not none -%}
        {{ custom_schema_name | trim }}
    {%- elif custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ default_schema }}_{{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}