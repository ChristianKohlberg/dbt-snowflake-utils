## Materializations

### Materialization: copy_into

The materialization `copy_into` loads data from an external stage into the specified table.
A repeated execution picks up only new files. Some limitations apply - please read carefully.

Reference to Snowflake [Copy Into](https://docs.snowflake.com/en/sql-reference/sql/copy-into-table.html) docs.

#### Usage
```
{# my_table.sql #}

{{
  config(
    materialized='copy_into',
    file_format=None,
    pattern=None
  )
}}

SELECT
	// column declaration
	$1::text as column_one
	
// load from external stage and optionally a path 
FROM @<DATABASE>.<SCHEMA>.<TABLE>/my_table_path/
​```
```
* param str file_format: Specifies the format of the data files to load:
* param str pattern: A regular expression pattern string, enclosed in single quotes, specifying the file names and/or paths to match.

#### First load

The first load needs to be triggered with flag `--full-refresh` to ensure files older than 64 days will be loaded.

#### Model syntax restrictions:

Not supported is the usage of
* Subqueries or nested queries
* CTEs

Inside the model. It is meant primarily to specify datatypes and parse content into a relational shape before load.

#### Idempotency
The `copy into` mechanism behaves by default:
* Ignore any files with a last modified date older than 64 days (timestamp of the file itself)
* Files with a timestamp younger than 64 days will be loaded only once as long as filename and file checksum do not change

If either a file

* gets a new name 
* changes its checksum (content of the file)

it will be loaded a **second** time!  

Rerun your dbt model with the `--full-refresh` flag to start over fresh. This should be a rare occassion and will be a manual process. This materialization is not well-suited if your data source layer will be overwritten or altered without notice - consider an alternative approach like merge.


#### Full Refresh

`dbt run -m <my_model> --full-refresh` triggers a full reload of the specified models.

Whenever the logic within the model changes, a full refresh needs to be triggered. Otherwise two cases can happen:

* The model returns a compiler error:
  * Mismatch of columns 
  * Mismatch of data types

* The model returns no error, but table integrity is corrupt:
  * Mismatch of column order could load data into the wrong column
  * Change of parse algorithms e.g. dates can lead to inconsistent behaviour

#### Examples
```
{{
  config(
    materialized='copy_into',
    file_format='(type = csv skip_header=1 FIELD_OPTIONALLY_ENCLOSED_BY = \'"\')',
    pattern=None
  )
}}

SELECT
    $1::text as col_one

    ,SPLIT_PART(metadata$FILENAME, '/', -1)::text as file_name
    ,metadata$file_row_number::number as row_number
FROM @<DATABASE>.<SCHEMA>.<TABLE>/snowplow_logs/
​```
```