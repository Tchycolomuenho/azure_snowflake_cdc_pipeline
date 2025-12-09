# Observabilidade (OpenTelemetry + Datadog)

- **Airflow**: habilitar tracing via `AIRFLOW__METRICS__OTLP_*` apontando para collector. Exportar spans para Datadog com atributos `dag_id`, `task_id`, `run_id`, `env`.
- **ADF**: ativar diagnóstico e enviar logs para Log Analytics + exportar para Datadog (Forwarder). Incluir correlation-id recebido do Airflow na chamada da pipeline.
- **Snowflake**: habilitar `QUERY_TAG` com correlation-id (passado pelo Airflow Operator) e coletar logs via Datadog Snowflake Integration.
- **Soda**: enviar resultados de scans via `soda-cloud` e habilitar webhook para Datadog Events.
- **Métricas principais**: lag de CDC, tempo de fila do Snowpipe/Task, taxa de erro de MERGE, Freshness das tabelas, consumo de warehouse.
- **Dashboards**: visões por camada (ingestão, bronze, silver/dw), alertas de frescor > 1h, contagem de falhas por dag_id.
