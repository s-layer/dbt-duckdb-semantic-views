---
name: verify
description: Prove a change to dbt-duckdb-semantic-views works end to end. Use before saying a change is done, before committing, and before opening or updating a pull request.
---

# Verify a change

Run from the repository root:

```bash
uv venv && uv pip install dbt-duckdb dbt-core "duckdb==2.0.0"
source .venv/bin/activate
cd integration_tests
rm -f target/test.duckdb  # start empty, as CI does
dbt deps --profiles-dir .
dbt seed --profiles-dir . --target ci
dbt run --profiles-dir . --target ci -s sem_orders_switch --vars '{sem_orders_switch_as: view}'
dbt build --profiles-dir . --target ci
dbt build --profiles-dir . --target ci
dbt run --profiles-dir . --target ci -s sem_orders_switch --vars '{sem_orders_switch_as: table}'
dbt build --profiles-dir . --target ci -s sem_orders_switch+
dbt run-operation test_semantic_view_drop_and_rename --profiles-dir . --target ci
```

It passes when every command exits 0. This is the sequence `.github/workflows/ci.yml`
runs: the second `dbt build` proves CREATE OR REPLACE is idempotent, and the switch
steps prove a plain view or table is replaced by the semantic view. The `ci` target is
file-backed, so the database is deleted first: a file left by an earlier run would send
the switch steps down paths CI never takes.

A run that skipped what you changed is not a pass.

Take each command's exit status from the command itself. In a pipeline `$?` is the last
command's status, so `cmd | tail` hides a failure. Redirect long output to a file, then
read the file.

## What this covers

- every integration model and result test on a file-backed DuckDB
- idempotent rebuilds, view/table switching, drop and rename

## What it does not cover

- the dbt-duckdb version matrix: CI runs several versions, locally you get the latest

## When it fails

- Read the first failure and fix its cause. Do not rerun hoping for a green, and do not
  skip, loosen or delete the failing test to get one.
- If the failure is real but outside the change, say so in the PR and in your report
  rather than working around it.
