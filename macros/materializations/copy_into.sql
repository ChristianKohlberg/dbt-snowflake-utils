{% materialization copy_into, adapter='snowflake' -%}

    -- Copy into parameters
    {%- set file_format = config.require('file_format') -%}
    {%- set pattern = config.get('pattern', default=None) -%}

    -- Relation parameters
    {%- set identifier = model['alias'] -%}
    {%- set old_relation = adapter.get_relation(database=database, schema=schema, identifier=identifier) -%}
    {%- set target_relation = api.Relation.create(schema=schema, identifier=identifier, type='table') -%}

    {%- set full_refresh_mode = (flags.FULL_REFRESH == True) -%}
    {%- set exists_as_table = (old_relation is not none and old_relation.is_table) -%}
    {%- set should_drop = (full_refresh_mode or not exists_as_table) -%}

    -- Setup
    {% if old_relation is none -%}
        -- noop
    {%- elif should_drop -%}
        {{ adapter.drop_relation(old_relation) }}
        {%- set old_relation = none -%}
    {%- endif %}

    {{ run_hooks(pre_hooks, inside_transaction=False) }}

    -- `BEGIN` happens here:
    {{ run_hooks(pre_hooks, inside_transaction=True) }}

    -- build model
    {% if full_refresh_mode or old_relation is none -%}

        {%- call statement() -%}
            CREATE OR REPLACE TABLE {{ target_relation }} AS (
                {{ sql ~ '/' ~ invocation_id }}
            )
        {%- endcall -%}
    {%- endif %}

    {%- call statement('main') -%}
        COPY INTO {{ target_relation }}
        FROM (
            {{ sql }}
        )
        {{ 'pattern = ' ~ pattern if pattern }}
        {{ 'file_format = ' ~ file_format if file_format }}
        {{ 'LOAD_UNCERTAIN_FILES = TRUE' if full_refresh_mode }}
    {% endcall %}

    {{ run_hooks(post_hooks, inside_transaction=True) }}

    -- `COMMIT` happens here
    {{ adapter.commit() }}

    {{ run_hooks(post_hooks, inside_transaction=False) }}

    {{ return({'relations': [target_relation]}) }}

{%- endmaterialization %}