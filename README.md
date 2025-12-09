# Azure → Snowflake CDC Pipeline with Airflow

Project demonstrating a full CDC ingestion pipeline from a transactional SQL Server into Snowflake, using Airflow for orchestration. Includes simulated data generation, ADF for capture/landing, dbt modeling (SCD Type 2), data quality with Soda SQL, Snowflake security policies (RLS/masking), infrastructure provisioning via Terraform/Bicep, and observability with OpenTelemetry + Datadog.

## Scope
- Source: SQL Server with CDC enabled on the `transactions`, `customers`, and `cards` tables.
- Orchestration: Airflow triggering ADF pipelines to land data into Snowflake staging (External Stage + Snowpipe/Copy via ADF).
- Analytics layer: dbt-snowflake with SCD2 models (customers/cards) and an incremental fact model (transactions) using Streams + Tasks for MERGE operations.
- Governance: Data quality with Soda SQL, Snowflake RLS/masking policies, and certified views for BI consumption (Power BI).
- Infrastructure: Terraform/Bicep provisioning for ADF, Key Vault, Storage, Snowflake roles/warehouses; observability with OpenTelemetry + Datadog.

## How to Navigate
- `data/`: SQL scripts to generate simulated inserts/updates in SQL Server.
- `airflow/dags/`: Airflow DAG orchestrating CDC ingestion via ADF and post-processing in Snowflake.
- `adf/`: Blueprint for ADF pipelines, datasets, and CDC triggers.
- `dbt/`: dbt models and documentation for SCD2, streams, and tasks.
- `snowflake/`: Scripts to create streams, tasks, RLS/masking policies, and certified views.
- `soda/`: Soda SQL configuration for data-quality checks.
- `terraform/` and `bicep/`: Infrastructure provisioning examples for Azure and Snowflake.
- `observability/`: Telemetry guide with OpenTelemetry + Datadog.

## Pipeline Summary
1. SQL Server CDC captures changes from the source tables.
2. Airflow triggers ADF Copy (or Mapping Data Flow) to extract CDC deltas and land the data in Azure Storage (parquet), notifying Snowpipe.
3. Snowpipe/ADF loads data into Snowflake staging; Streams capture deltas and Tasks execute the MERGE/INSERT logic.
4. dbt runs SCD2 snapshots and incremental models; Soda SQL validates data quality; Snowflake enforces RLS/masking; Power BI consumes certified views.

## Local Validation

### Snowflake
- Run `snowflake/tasks_and_streams.sql` to create stages, streams, tasks, and tables.
- Tasks are resumed automatically at the end of the script.

### Airflow
- Copy `airflow/dags/cdc_sqlserver_to_snowflake.py` into your Airflow DAGs directory, keeping the repository structure one level above, such as:
  `/opt/airflow/dags/azure_snowflake_cdc_pipeline/airflow/dags/cdc_sqlserver_to_snowflake.py`
  This ensures the DAG resolves relative paths to `dbt/`, `soda/`, and `snowflake/`.

- Configure the following Airflow connections:
  - `adf_api`
  - `adf_default`
  - `snowflake_default`

- Trigger the DAG manually to validate the ADF → Snowflake → dbt → Soda flow.

### dbt
Inside the `dbt/` directory:
- Copy `profiles.yml.example` to `profiles.yml` and update credentials.
- Run:
dbt deps
dbt snapshot
dbt run --select staging warehouse

### Soda
Inside the `soda/` directory:
- Set Snowflake environment variables (`SNOWFLAKE_*`).
- Run:
soda scan -d snowflake -c configuration.yml soda_scan.yml

### Sanity Check
Run from the repository root:
python -m compileall azure_snowflake_cdc_pipeline

This ensures the DAG and Python modules compile without errors.

## Assumptions
- Examples are self-contained and do not require real credentials.
- Secrets must be stored in environment variables or Azure Key Vault (never committed).
- Warehouse and database names should be adjusted according to your Snowflake tenant.
