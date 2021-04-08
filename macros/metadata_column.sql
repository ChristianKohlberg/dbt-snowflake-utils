{% macro metadata_column() %}
         OBJECT_CONSTRUCT(
              'Filename', METADATA$FILENAME::text
            , 'RowNumber', METADATA$FILE_ROW_NUMBER::int
            , 'Timestamp', current_timestamp(9)
            , 'User', current_user()
            , 'Role', current_role()
            , 'Client', current_client()
            , 'Session', current_session()
            , 'Version', current_version()
        )               as METADATA
{% endmacro %}