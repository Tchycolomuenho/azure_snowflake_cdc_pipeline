# Medidas DAX para o dataset Power BI

Use as expressões abaixo no Model view ou Tabular Editor (assumem tabelas `dim_customers`, `dim_cards`, `fct_transactions`).

```DAX
Total Amount = SUM ( fct_transactions[amount] )

Transaction Count = COUNTROWS ( fct_transactions )

Average Ticket = DIVIDE ( [Total Amount], [Transaction Count] )

Approved Amount = CALCULATE ( [Total Amount], fct_transactions[status] = "APPROVED" )

Approval Rate % = DIVIDE ( [Approved Amount], [Total Amount] )

Chargeback Amount = CALCULATE ( [Total Amount], fct_transactions[status] = "CHARGEBACK" )

Net Amount = [Approved Amount] - [Chargeback Amount]

Active Customers = CALCULATE ( DISTINCTCOUNT ( dim_customers[customer_id] ), dim_customers[is_current] = TRUE () )

Active Cards = CALCULATE ( DISTINCTCOUNT ( dim_cards[card_id] ), dim_cards[is_current] = TRUE () )

Utilized Credit % = DIVIDE ( [Total Amount], SUM ( dim_cards[limit_amount] ) )

Avg Utilization per Customer = DIVIDE ( [Total Amount], Active Customers )

Reversal Rate % = DIVIDE ( CALCULATE ( [Transaction Count], fct_transactions[is_reversed] = TRUE () ), [Transaction Count] )

Daily Volume = CALCULATE ( [Transaction Count], DATESINPERIOD ( fct_transactions[txn_ts], MAX ( fct_transactions[txn_ts] ), -1, DAY ) )

MCC Concentration % =
VAR TopMCC = TOPN ( 1, SUMMARIZE ( fct_transactions, fct_transactions[mcc], "amt", [Total Amount] ), [Total Amount] )
VAR TopAmount = SUMX ( TopMCC, [amt] )
RETURN DIVIDE ( TopAmount, [Total Amount] )

Pipeline Latency (min) =
VAR LastLanding = MAX ( fct_transactions[ingestion_ts] )
VAR LastEvent   = MAX ( fct_transactions[txn_ts] )
RETURN DATEDIFF ( LastEvent, LastLanding, MINUTE )
```

## Filtros e RLS no modelo

- Marque `dim_customers[is_current] = TRUE` e `dim_cards[is_current] = TRUE` como filtros de relatório para evitar registros expirados.
- Para RLS adicional, crie uma função `Region Manager` com a expressão: `dim_customers[region] = USERPRINCIPALNAME()` ou use grupos do Entra ID sincronizados com o Snowflake.
- As policies de masking já aplicadas no Snowflake serão respeitadas quando o conector estiver em SSO.
