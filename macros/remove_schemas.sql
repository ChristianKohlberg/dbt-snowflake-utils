{# usage: dbt run-operation remove_schemas_from_database --args '{database_name: CORPCO_DEV}' --profile datahub_snowflake #}

{% macro remove_schemas_from_database(database_name) %}
    {% set snappy = "'SNAPSHOTS'" %}
    {% set schemas = run_query('select SCHEMA_NAME from ' ~ database_name ~ '.information_schema.schemata where created is not null and SCHEMA_NAME != ' ~ snappy) %}
    {% set all_schemas = schemas.columns['SCHEMA_NAME'].values() %}

    {% if all_schemas |length == 0 %}
        {{ log('Currently no schemas in database ' ~ database_name ~ ' exist',info = True) }}

    {% else  %}
        {% for schema_name in all_schemas | reject('in', ['SNAPSHOTS']) %}
            {{ log('remove schema: '  ~ schema_name, info=True) }}
            {%- call statement('delete', fetch_result=True) -%}
                DROP SCHEMA {{ database }}."{{ schema_name }}";
            {%- endcall -%}
        {% endfor %}

    {% endif %}

{% endmacro %}