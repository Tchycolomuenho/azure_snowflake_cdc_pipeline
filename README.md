# Azure → Snowflake CDC Pipeline with Airflow

Projeto de referência para ingestão CDC de um SQL Server transacional para Snowflake usando Airflow para orquestração. Inclui geração de dados simulados, ADF para captura/aterragem, modelagem com dbt (SCD Type 2), qualidade com Soda SQL, políticas de segurança (RLS/masking), provisionamento com Terraform/Bicep e observabilidade com OpenTelemetry + Datadog.

## Escopo
- Fonte: SQL Server com CDC habilitado nas tabelas `transactions`, `customers` e `cards`.
- Orquestração: Airflow acionando pipelines ADF para aterrar dados em estágio Snowflake (External Stage + Snowpipe/Copy via ADF).
- Camada analítica: dbt-snowflake com modelos SCD2 (clientes/cartões) e fato incremental (transações) usando Streams+Tasks para MERGE.
- Governança: qualidade de dados com Soda SQL, RLS/masking policies em Snowflake, views certificadas para consumo (Power BI).
- Infra: Terraform/Bicep para provisionar ADF, Key Vault, Storage, Snowflake roles/warehouses; observabilidade com OpenTelemetry + Datadog.

## Como navegar
- `data/`: scripts SQL para gerar dados simulados (inserts/updates) em SQL Server.
- `airflow/dags/`: DAG com tarefas para orquestrar CDC via ADF e pós-processamento em Snowflake.
- `adf/`: blueprint de pipelines/datasets/triggers CDC.
- `dbt/`: modelos dbt e documentação de SCD2/streams/tasks.
- `snowflake/`: scripts de criação de streams, tasks, RLS/masking policies e views certificadas.
- `soda/`: configuração de checagens de qualidade.
- `terraform/` e `bicep/`: exemplos de provisionamento.
- `observability/`: guia de telemetria com OpenTelemetry + Datadog.

## Fluxo resumido
1. CDC habilitado no SQL Server captura alterações nas tabelas fonte.
2. Airflow agenda execução do ADF Copy (ou Mapping Data Flow) lendo alterações via CDC e escrevendo em Azure Storage (parquet) + notificação para Snowpipe.
3. A Snowpipe/ADF copia para o stage Snowflake; streams capturam deltas e tasks executam MERGE/INSERT conforme modelagem (arquivo `snowflake/tasks_and_streams.sql`).
4. dbt executa snapshots (SCD2 para clientes/cartões) e modelos incrementais; Soda SQL valida qualidade; Snowflake aplica RLS/masking; Power BI consome views certificadas.

## Como validar localmente
- `snowflake/tasks_and_streams.sql`: execute o script para criar stages/streams/tasks/tabelas no Snowflake. As tasks são retomadas ao final do script.
- Airflow: copie `airflow/dags/cdc_sqlserver_to_snowflake.py` para o diretório de DAGs **mantendo a estrutura do repositório em um nível acima** (ex.: `/opt/airflow/dags/azure_snowflake_cdc_pipeline/airflow/dags/cdc_sqlserver_to_snowflake.py`), pois o DAG resolve caminhos relativos para `dbt/`, `soda/` e `snowflake/`. Configure conexões `adf_api`, `adf_default` e `snowflake_default`; acione o DAG manualmente para testar a cadeia ADF → Snowflake → dbt → Soda.
- dbt: na pasta `dbt/`, copie `profiles.yml.example` para `profiles.yml`, ajuste credenciais e rode `dbt deps && dbt snapshot && dbt run --select staging warehouse`.
- Soda: na pasta `soda/`, ajuste variáveis de ambiente `SNOWFLAKE_*` e rode `soda scan -d snowflake -c configuration.yml soda_scan.yml`.
- Sanidade rápida: `python -m compileall azure_snowflake_cdc_pipeline` garante que o DAG e arquivos Python compilam corretamente no ambiente.

## Premissas
- Exemplos são auto-contidos e não requerem credenciais reais.
- Use variáveis de ambiente/Key Vault para segredos (não versionar chaves).
- Ajuste nomes de warehouses/databases conforme seu tenant.
