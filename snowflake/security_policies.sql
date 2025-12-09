-- Row-level security para limitar visão por estado do cliente
CREATE OR REPLACE ROW ACCESS POLICY dw.customer_state_rls AS (state_code STRING) RETURNS BOOLEAN ->
    CURRENT_ROLE() IN ('DW_ANALYST') OR state_code = CURRENT_USER();

ALTER TABLE IF EXISTS dw.dim_customers_scd2 ADD ROW ACCESS POLICY dw.customer_state_rls ON (state_code);

-- Masking policy para dados sensíveis
CREATE OR REPLACE MASKING POLICY dw.mask_card_number AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('PCI_READER', 'ACCOUNTADMIN') THEN val
        ELSE CONCAT('XXXX-XXXX-XXXX-', RIGHT(val, 4))
    END;

ALTER TABLE IF EXISTS dw.dim_cards_scd2 MODIFY COLUMN card_number SET MASKING POLICY dw.mask_card_number;
