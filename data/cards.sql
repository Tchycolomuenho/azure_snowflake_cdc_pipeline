-- Simulação de cartões vinculados a clientes, com limites e CDC ativo.
CREATE TABLE dbo.cards (
    card_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    card_number NVARCHAR(32) NOT NULL,
    status NVARCHAR(20) NOT NULL,
    credit_limit DECIMAL(18,2) NOT NULL,
    available_limit DECIMAL(18,2) NOT NULL,
    created_at DATETIME2 DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

ALTER TABLE dbo.cards
ADD CONSTRAINT FK_cards_customers FOREIGN KEY (customer_id) REFERENCES dbo.customers(customer_id);
GO

EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'cards', @role_name = NULL;
GO

INSERT INTO dbo.cards (card_id, customer_id, card_number, status, credit_limit, available_limit)
VALUES
(101, 1, '4111-1111-1111-1111', 'active', 15000, 15000),
(102, 2, '5500-0000-0000-0004', 'active', 12000, 8000),
(103, 3, '3400-000000-00009', 'blocked', 8000, 0);
GO

-- Ajuste de limite e mudança de status (gera CDC)
UPDATE dbo.cards
   SET credit_limit = 18000, available_limit = 16000, updated_at = SYSUTCDATETIME()
 WHERE card_id = 101;
GO

UPDATE dbo.cards
   SET status = 'active', available_limit = 2000, updated_at = SYSUTCDATETIME()
 WHERE card_id = 103;
GO
