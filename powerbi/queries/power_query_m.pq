// Power Query (M) para o dataset Power BI do pipeline Azure SQL Server → Snowflake CDC.
// Cole no Editor Avançado. Ajuste os parâmetros abaixo antes de aplicar.

let
    // Parâmetros de conexão Snowflake
    SnowflakeAccount   = "<sua_conta>.snowflakecomputing.com",
    SnowflakeWarehouse = "COMPUTE_WH",
    SnowflakeDatabase  = "RAW_DB",
    SnowflakeSchema    = "CERTIFIED",   // use RAW ou CURATED se preferir, mas mantenha as views certificadas
    SnowflakeRole      = "PBI_READER",   // mapeado a RLS/masking no Snowflake

    // Fonte Snowflake (usa o conector nativo do Power BI)
    Source = Snowflake.Databases(
        SnowflakeAccount,
        [
            Warehouse = SnowflakeWarehouse,
            Role = SnowflakeRole,
            QueryTag = "powerbi-cdc"
        ]
    ),
    Db     = Source{[Name = SnowflakeDatabase]}[Data],
    Sch    = Db{[Name = SnowflakeSchema]}[Data],

    // Dimensões e fato (podem ser trocadas para DirectQuery mantendo o mesmo script)
    DimCustomersTable = Sch{[Name = "dim_customers"]}[Data],
    DimCustomers = Table.TransformColumnTypes(
        DimCustomersTable,
        {
            {"customer_sk", Int64.Type},
            {"customer_id", type text},
            {"full_name", type text},
            {"region", type text},
            {"state", type text},
            {"city", type text},
            {"segment", type text},
            {"masked_document", type text},
            {"is_current", type logical},
            {"valid_from", type datetimezone},
            {"valid_to", type datetimezone}
        }
    ),

    DimCardsTable = Sch{[Name = "dim_cards"]}[Data],
    DimCards = Table.TransformColumnTypes(
        DimCardsTable,
        {
            {"card_sk", Int64.Type},
            {"card_id", type text},
            {"customer_sk", Int64.Type},
            {"product", type text},
            {"limit_amount", type number},
            {"status", type text},
            {"masked_pan", type text},
            {"is_current", type logical},
            {"valid_from", type datetimezone},
            {"valid_to", type datetimezone}
        }
    ),

    FactTxTable = Sch{[Name = "fct_transactions"]}[Data],
    FactTransactions = Table.TransformColumnTypes(
        FactTxTable,
        {
            {"txn_id", type text},
            {"txn_ts", type datetimezone},
            {"card_sk", Int64.Type},
            {"customer_sk", Int64.Type},
            {"mcc", type text},
            {"status", type text},
            {"amount", type number},
            {"currency", type text},
            {"auth_code", type text},
            {"is_reversed", type logical},
            {"ingestion_ts", type datetimezone}
        }
    ),

    // Views certificadas (agregados prontos para self-service)
    VTransactionsDaily = Sch{[Name = "v_transactions_daily"]}[Data],
    VCustomersPortfolio = Sch{[Name = "v_customers_portfolio"]}[Data],
    VRiskExposure = Sch{[Name = "v_risk_exposure"]}[Data],

    // Saída
    Resultado = [
        dim_customers = DimCustomers,
        dim_cards = DimCards,
        fct_transactions = FactTransactions,
        v_transactions_daily = VTransactionsDaily,
        v_customers_portfolio = VCustomersPortfolio,
        v_risk_exposure = VRiskExposure
    ]

in
    Resultado
