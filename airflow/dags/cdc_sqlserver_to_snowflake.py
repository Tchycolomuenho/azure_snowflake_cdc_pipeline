"""
DAG de referência para orquestrar CDC SQL Server → Snowflake usando ADF + dbt + Soda.
Executa healthcheck, dispara ADF copy, aplica merges via streams/tasks em Snowflake,
roda snapshots/dbt models e validações Soda.
"""
from datetime import datetime, timedelta
from pathlib import Path

from airflow import DAG
from airflow.models.baseoperator import chain
from airflow.operators.bash import BashOperator
from airflow.providers.http.sensors.http import HttpSensor
from airflow.providers.microsoft.azure.operators.data_factory import (
    AzureDataFactoryRunPipelineOperator,
)
from airflow.providers.microsoft.azure.sensors.data_factory import (
    AzureDataFactoryPipelineRunSensor,
)
from airflow.providers.snowflake.operators.snowflake import SnowflakeOperator

DEFAULT_ARGS = {
    "owner": "data-team",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

PROJECT_ROOT = Path(__file__).resolve().parents[2]
SQL_DIR = PROJECT_ROOT / "snowflake"
DBT_DIR = PROJECT_ROOT / "dbt"
SODA_DIR = PROJECT_ROOT / "soda"


def load_sql(name: str) -> str:
    return (SQL_DIR / name).read_text()


with DAG(
    dag_id="cdc_sqlserver_to_snowflake",
    start_date=datetime(2024, 1, 1),
    schedule_interval="*/30 * * * *",  # execução a cada 30 minutos
    catchup=False,
    default_args=DEFAULT_ARGS,
    max_active_runs=1,
    tags=["cdc", "snowflake", "adf"],
) as dag:
    # Verifica se API do ADF está disponível
    adf_healthcheck = HttpSensor(
        task_id="adf_healthcheck",
        http_conn_id="adf_api",
        endpoint="/health",
        poke_interval=30,
        timeout=120,
    )

    # Dispara pipeline ADF parametrizado para CDC
    start_adf = AzureDataFactoryRunPipelineOperator(
        task_id="start_adf_copy",
        pipeline_name="pl_cdc_sqlserver_to_bronze",
        azure_data_factory_conn_id="adf_default",
        parameters={
            "source_tables": ["dbo.transactions", "dbo.customers", "dbo.cards"],
            "target_container": "landing/cdc",
        },
    )

    # Aguarda conclusão
    wait_adf = AzureDataFactoryPipelineRunSensor(
        task_id="wait_adf_copy",
        azure_data_factory_conn_id="adf_default",
        run_id=start_adf.output,
        timeout=3600,
    )

    # Cria objetos/streams/tasks em Snowflake (idempotente)
    bootstrap_snowflake = SnowflakeOperator(
        task_id="bootstrap_snowflake",
        snowflake_conn_id="snowflake_default",
        warehouse="COMPUTE_WH",
        database="RAW",
        schema="BRONZE",
        sql=load_sql("tasks_and_streams.sql"),
    )

    # Executa os tasks encadeados de merge uma vez por rodada
    run_merge_tasks = SnowflakeOperator(
        task_id="run_merge_tasks",
        snowflake_conn_id="snowflake_default",
        warehouse="COMPUTE_WH",
        database="RAW",
        schema="BRONZE",
        sql=[
            "EXECUTE TASK RAW.STREAMING.MERGE_TRANSACTIONS_TASK;",
            "EXECUTE TASK RAW.STREAMING.MERGE_CUSTOMERS_TASK;",
            "EXECUTE TASK RAW.STREAMING.MERGE_CARDS_TASK;",
        ],
    )

    # Executa snapshots + modelos dbt (staging, warehouse)
    dbt_snapshot = BashOperator(
        task_id="dbt_snapshot",
        bash_command="cd {{ params.dbt_dir }} && dbt deps --quiet && dbt snapshot --profiles-dir .",
        params={"dbt_dir": str(DBT_DIR)},
        env={"DBT_PROFILES_DIR": str(DBT_DIR)},
    )

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command="cd {{ params.dbt_dir }} && dbt run --select staging warehouse --profiles-dir .",
        params={"dbt_dir": str(DBT_DIR)},
        env={"DBT_PROFILES_DIR": str(DBT_DIR)},
    )

    # Validação de qualidade com Soda
    soda_scan = BashOperator(
        task_id="soda_scan",
        bash_command=(
            "cd {{ params.soda_dir }} && "
            "soda scan -d snowflake -c configuration.yml soda_scan.yml"
        ),
        params={"soda_dir": str(SODA_DIR)},
        env={"SODA_LOG_LEVEL": "INFO"},
    )

    chain(
        adf_healthcheck,
        start_adf,
        wait_adf,
        bootstrap_snowflake,
        run_merge_tasks,
        dbt_snapshot,
        dbt_run,
        soda_scan,
    )
