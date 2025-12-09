-- Simulação de transações com CDC para fluxo incremental.
CREATE TABLE dbo.transactions (
    transaction_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    card_id INT NOT NULL,
    merchant NVARCHAR(200) NOT NULL,
    amount DECIMAL(18,2) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'BRL',
    status NVARCHAR(20) NOT NULL,
    event_ts DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    created_at DATETIME2 DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

ALTER TABLE dbo.transactions
ADD CONSTRAINT FK_transactions_cards FOREIGN KEY (card_id) REFERENCES dbo.cards(card_id);
GO

EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'transactions', @role_name = NULL;
GO

-- Carga inicial
INSERT INTO dbo.transactions (card_id, merchant, amount, status)
VALUES
(101, 'EletroMart', 250.00, 'approved'),
(101, 'Livraria Central', 120.50, 'approved'),
(102, 'Posto Shell', 300.10, 'approved'),
(103, 'Farmácia Saúde', 75.90, 'declined');
GO

-- Alterações simuladas (chargeback, refund)
UPDATE dbo.transactions
   SET status = 'chargeback', updated_at = SYSUTCDATETIME()
 WHERE transaction_id = 2;
GO

INSERT INTO dbo.transactions (card_id, merchant, amount, status)
VALUES (101, 'Cinema 4DX', 95.00, 'approved');
GO
