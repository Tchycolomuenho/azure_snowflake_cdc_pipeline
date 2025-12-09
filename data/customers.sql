-- Simulação de dados de clientes em SQL Server com CDC habilitado.
CREATE TABLE dbo.customers (
    customer_id INT PRIMARY KEY,
    full_name NVARCHAR(120) NOT NULL,
    email NVARCHAR(256) NOT NULL,
    phone NVARCHAR(32),
    address NVARCHAR(256),
    city NVARCHAR(120),
    state_code CHAR(2),
    created_at DATETIME2 DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

-- Habilita CDC na tabela
EXEC sys.sp_cdc_enable_table @source_schema = N'dbo', @source_name = N'customers', @role_name = NULL;
GO

-- Carga inicial
INSERT INTO dbo.customers (customer_id, full_name, email, phone, address, city, state_code)
VALUES
(1, 'Alice Martins', 'alice.martins@example.com', '+55 11 98888-1111', 'Rua A, 10', 'São Paulo', 'SP'),
(2, 'Bruno Dias', 'bruno.dias@example.com', '+55 21 97777-2222', 'Av B, 200', 'Rio de Janeiro', 'RJ'),
(3, 'Carla Souza', 'carla.souza@example.com', '+55 31 96666-3333', 'Rua C, 33', 'Belo Horizonte', 'MG');
GO

-- Mutação simulada (gera entradas no CDC)
UPDATE dbo.customers
   SET phone = '+55 11 98888-0000', updated_at = SYSUTCDATETIME()
 WHERE customer_id = 1;
GO

INSERT INTO dbo.customers (customer_id, full_name, email, phone, address, city, state_code)
VALUES (4, 'Daniela Prado', 'daniela.prado@example.com', '+55 41 95555-4444', 'Rua D, 44', 'Curitiba', 'PR');
GO
