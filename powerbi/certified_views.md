# Views certificadas para Power BI

Crie views estáveis e governadas no schema `certified` para consumo pelo Power BI e pelo conector Snowflake (SSO/Entra ID):

- `certified.v_transactions_daily`: agrega volume/valor diário por status, MCC e bandeira.
- `certified.v_customers_portfolio`: junta cliente + cartões vigentes com máscaras aplicadas e limites atualizados.
- `certified.v_risk_exposure`: expõe limites e alavancagem por cliente/cartão, já filtrando registros expirados.

Boas práticas:
- Adicionar tags `PBI_CERTIFIED` e comentários com dicionário de dados.
- Garantir que as views referenciem apenas tabelas com RLS/masking já aplicados.
- Publicar datasources no Power BI usando SSO/Entra ID e role `PBI_READER` mapeada para Snowflake.
- Testar cada view com o Soda e em `powerbi/queries/power_query_m.pq` antes de certificar.
