# Power BI — Azure SQL Server → Snowflake CDC

Este diretório contém artefatos para construir o BI no Power BI a partir do pipeline de CDC.
Os componentes principais são:

- **Consultas Power Query (M)** em `queries/power_query_m.pq` apontando para as views certificadas no Snowflake.
- **Medidas DAX** em `measures/dax_measures.md` para métricas financeiras e de portfólio.
- **Views certificadas** documentadas em `certified_views.md` (schema `certified`).
- **RLS e masking** já aplicados no Snowflake; usar SSO/Entra ID no Power BI para herdar o contexto.

## Como usar

1. Copie o conteúdo de `queries/power_query_m.pq` para o editor avançado do Power Query (Power BI Desktop).
2. Defina os parâmetros solicitados (conta Snowflake, warehouse, database, etc.) e valide a conexão.
3. Carregue as tabelas (`dim_customers`, `dim_cards`, `fct_transactions`, `v_*` certificadas).
4. Cole as medidas de `measures/dax_measures.md` no Model view (ou Tabular Editor). Todas usam nomes das tabelas acima.
5. Publique o relatório/dataset e habilite **Single Sign-On (SSO)** com Entra ID para o conector Snowflake. Isso garante que as policies de masking/RLS no Snowflake sejam respeitadas.
6. Marque o dataset como **certificado** e vincule os relatórios existentes ou construa novos visuais.

## Dicas de modelagem

- Use `dim_customers[customer_sk]` ↔ `fct_transactions[customer_sk]` e `dim_cards[card_sk]` ↔ `fct_transactions[card_sk]` como relacionamentos 1:N.
- Marque `dim_customers[is_current]` e `dim_cards[is_current]` como filtros padrão em visuais para mostrar apenas registros vigentes. Há medidas que já consideram vigência (ver `measures/dax_measures.md`).
- Crie hierarquias (ex.: `customer_region` → `customer_state` → `city`) e calendários derivados de `fct_transactions[txn_ts]`.
- Se precisar de DirectQuery, mantenha o `Query reduction` habilitado e evite colunas de alta cardinalidade em slicers.

## Observabilidade

- Monte dashboards no Power BI usando as medidas de confiabilidade (ex.: `% de transações conciliadas`, `QTD cards mascarados`) para acompanhar se o pipeline está saudável.
- Acompanhe latência entre `raw` → `curated` → `certified` com a medida `Pipeline Latency (min)` em `measures/dax_measures.md`.
