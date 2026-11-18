{#-
  dbt never calls the package's drop and rename macros on its own (it drops and renames
  through its catalog, which does not list semantic views), so this run-operation calls them
  directly and checks the catalog after each step. CI runs it after `dbt build`.

    dbt run-operation test_semantic_view_drop_and_rename
-#}
{% macro test_semantic_view_drop_and_rename() %}
  {%- set schema = target.schema -%}
  {%- set source = api.Relation.create(database=target.database, schema=schema, identifier='sv_lifecycle_a') -%}
  {%- set renamed = api.Relation.create(database=target.database, schema=schema, identifier='sv_lifecycle_b') -%}

  {% do run_query(duckdb_semantic_views.duckdb__get_drop_semantic_view_sql(source)) %}
  {% do run_query(duckdb_semantic_views.duckdb__get_drop_semantic_view_sql(renamed)) %}
  {% do run_query(duckdb_semantic_views.duckdb__get_create_semantic_view_sql(source,
      "TABLES (orders AS " ~ ref('raw_orders') ~ " PRIMARY KEY (order_id)) "
      ~ "DIMENSIONS (orders.region_id AS region_id) METRICS (orders.total_amount AS sum(amount))")) %}
  {% do _sv_lifecycle_expect(['sv_lifecycle_a'], 'after create') %}

  {% do run_query(duckdb_semantic_views.duckdb__get_semantic_view_rename_sql(source, renamed.identifier)) %}
  {% do _sv_lifecycle_expect(['sv_lifecycle_b'], 'after rename') %}
  {%- set total = run_query(
      "select sum(total_amount) from semantic_view('" ~ target.database ~ "." ~ schema
      ~ ".sv_lifecycle_b', dimensions := ['region_id'], metrics := ['total_amount'])").columns[0].values()[0] -%}
  {% if total | float != 1490.0 %}
    {{ exceptions.raise_compiler_error("renamed view returned " ~ total ~ ", expected 1490.00") }}
  {% endif %}

  {% do run_query(duckdb_semantic_views.duckdb__get_drop_semantic_view_sql(renamed)) %}
  {% do _sv_lifecycle_expect([], 'after drop') %}
  {# Both statements say IF EXISTS: repeating them on a missing view must not fail. #}
  {% do run_query(duckdb_semantic_views.duckdb__get_drop_semantic_view_sql(renamed)) %}
  {% do run_query(duckdb_semantic_views.duckdb__get_semantic_view_rename_sql(source, renamed.identifier)) %}
  {{ log("semantic view drop and rename: ok", info=true) }}
{% endmacro %}

{% macro _sv_lifecycle_expect(expected, step) %}
  {%- set found = run_query(
      "select name from list_semantic_views() where schema_name = '" ~ target.schema ~ "' and name like 'sv_lifecycle_%' order by 1"
    ).columns[0].values() | list -%}
  {% if found != expected %}
    {{ exceptions.raise_compiler_error("semantic views " ~ step ~ ": found " ~ found ~ ", expected " ~ expected) }}
  {% endif %}
{% endmacro %}
