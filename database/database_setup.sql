-- =====================================================
-- MoMo SMS Data Processing System - Database Setup
-- =====================================================
-- Database: momo_db
-- Created: 2026-01-25
-- Purpose: Store and manage mobile money transaction data
-- =====================================================

DROP DATABASE IF EXISTS momo_db;

CREATE DATABASE momo_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE momo_db;

-- =====================================================
-- TABLE: parties (Users/Customers)
-- =====================================================
CREATE TABLE IF NOT EXISTS parties (
    party_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for party',
    party_name VARCHAR(255) NOT NULL COMMENT 'Full name of the party',
    party_type ENUM('Individual', 'Business', 'Agent') NOT NULL COMMENT 'Type of party',
    phone_number VARCHAR(20) NOT NULL UNIQUE COMMENT 'Mobile phone number',
    national_id VARCHAR(50) UNIQUE COMMENT 'National identification number',
    email VARCHAR(255) COMMENT 'Email address',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last update timestamp',
    
    CHECK (LENGTH(phone_number) >= 10) COMMENT 'Validate phone number length',
    INDEX idx_phone (phone_number),
    INDEX idx_party_type (party_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Stores information about all parties (users, customers, agents)';

-- =====================================================
-- TABLE: accounts
-- =====================================================
CREATE TABLE IF NOT EXISTS accounts (
    account_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique account identifier',
    party_id INT NOT NULL COMMENT 'Foreign key to parties table',
    account_type ENUM('Wallet', 'Savings', 'Business', 'Agent') NOT NULL DEFAULT 'Wallet' COMMENT 'Type of account',
    currency VARCHAR(3) NOT NULL DEFAULT 'USD' COMMENT 'Account currency (ISO 4217 code)',
    current_balance DECIMAL(15, 2) NOT NULL DEFAULT 0.00 COMMENT 'Current account balance',
    is_active BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Account active status',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Account creation date',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last update timestamp',
    
    FOREIGN KEY (party_id) REFERENCES parties(party_id) ON DELETE CASCADE COMMENT 'Reference to parties',
    CHECK (current_balance >= 0) COMMENT 'Ensure non-negative balance',
    INDEX idx_party_id (party_id),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Stores account information for parties with balance tracking';

-- =====================================================
-- TABLE: transaction_categories
-- =====================================================
CREATE TABLE IF NOT EXISTS transaction_categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique category identifier',
    category_name VARCHAR(100) NOT NULL UNIQUE COMMENT 'Category name',
    description TEXT COMMENT 'Detailed description of the category',
    is_active BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Category active status',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Category creation date',
    
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Categorizes transaction types for organization and reporting';

-- =====================================================
-- TABLE: transactions
-- =====================================================
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique transaction identifier',
    transaction_code VARCHAR(50) NOT NULL UNIQUE COMMENT 'Unique transaction reference code',
    sender_account_id INT NOT NULL COMMENT 'Foreign key to sender account',
    receiver_account_id INT NOT NULL COMMENT 'Foreign key to receiver account',
    category_id INT NOT NULL COMMENT 'Foreign key to transaction category',
    amount DECIMAL(15, 2) NOT NULL COMMENT 'Transaction amount',
    currency VARCHAR(3) NOT NULL DEFAULT 'USD' COMMENT 'Transaction currency',
    status ENUM('Pending', 'Completed', 'Failed', 'Reversed') NOT NULL DEFAULT 'Pending' COMMENT 'Transaction status',
    transaction_timestamp DATETIME NOT NULL COMMENT 'Date and time of transaction',
    description VARCHAR(500) COMMENT 'Transaction description or notes',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
    
    FOREIGN KEY (sender_account_id) REFERENCES accounts(account_id) ON DELETE RESTRICT COMMENT 'Sender account reference',
    FOREIGN KEY (receiver_account_id) REFERENCES accounts(account_id) ON DELETE RESTRICT COMMENT 'Receiver account reference',
    FOREIGN KEY (category_id) REFERENCES transaction_categories(category_id) ON DELETE SET NULL COMMENT 'Category reference',
    CHECK (amount > 0) COMMENT 'Ensure positive transaction amount',
    CHECK (sender_account_id != receiver_account_id) COMMENT 'Ensure sender and receiver are different',
    INDEX idx_sender (sender_account_id),
    INDEX idx_receiver (receiver_account_id),
    INDEX idx_category (category_id),
    INDEX idx_status (status),
    INDEX idx_timestamp (transaction_timestamp),
    INDEX idx_transaction_code (transaction_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Core table storing all mobile money transactions';

-- =====================================================
-- TABLE: fees
-- =====================================================
CREATE TABLE IF NOT EXISTS fees (
    fee_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique fee identifier',
    transaction_id INT NOT NULL COMMENT 'Foreign key to transaction',
    fee_amount DECIMAL(15, 2) NOT NULL COMMENT 'Fee amount charged',
    fee_type ENUM('Flat', 'Percentage', 'Tiered') NOT NULL COMMENT 'Type of fee',
    fee_percentage DECIMAL(5, 3) COMMENT 'Percentage value if applicable',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Fee creation timestamp',
    
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE CASCADE COMMENT 'Transaction reference',
    CHECK (fee_amount >= 0) COMMENT 'Ensure non-negative fee',
    INDEX idx_transaction_id (transaction_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Tracks transaction fees for revenue and auditing purposes';

-- =====================================================
-- TABLE: processing_logs
-- =====================================================
CREATE TABLE IF NOT EXISTS processing_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique log identifier',
    transaction_id INT COMMENT 'Related transaction (nullable for system-level logs)',
    log_level ENUM('DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL') NOT NULL COMMENT 'Log severity level',
    message TEXT NOT NULL COMMENT 'Log message content',
    log_timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'When the log was recorded',
    process_name VARCHAR(100) COMMENT 'Name of processing step',
    status VARCHAR(50) COMMENT 'Status message related to processing',
    
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE SET NULL COMMENT 'Optional transaction reference',
    INDEX idx_level (log_level),
    INDEX idx_timestamp (log_timestamp),
    INDEX idx_transaction_id (transaction_id),
    INDEX idx_process_name (process_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='System logs for monitoring ETL processing and troubleshooting';

-- =====================================================
-- TABLE: transaction_tags (Many-to-Many Junction Table)
-- =====================================================
CREATE TABLE IF NOT EXISTS transaction_tags (
    transaction_id INT NOT NULL COMMENT 'Foreign key to transaction',
    tag_name VARCHAR(50) NOT NULL COMMENT 'Tag label',
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When tag was assigned',
    assigned_by VARCHAR(100) COMMENT 'User or system that assigned the tag',
    
    PRIMARY KEY (transaction_id, tag_name) COMMENT 'Composite key for junction table',
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE CASCADE COMMENT 'Transaction reference',
    INDEX idx_tag_name (tag_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Junction table for applying multiple tags/labels to transactions';

-- =====================================================
-- VIEWS FOR COMMON QUERIES
-- =====================================================

-- View: Transaction Summary with Parties and Accounts
CREATE OR REPLACE VIEW v_transaction_summary AS
SELECT 
    t.transaction_id,
    t.transaction_code,
    sp.party_name AS sender_name,
    rp.party_name AS receiver_name,
    tc.category_name,
    t.amount,
    t.currency,
    t.status,
    t.transaction_timestamp
FROM transactions t
JOIN accounts sa ON t.sender_account_id = sa.account_id
JOIN accounts ra ON t.receiver_account_id = ra.account_id
JOIN parties sp ON sa.party_id = sp.party_id
JOIN parties rp ON ra.party_id = rp.party_id
JOIN transaction_categories tc ON t.category_id = tc.category_id;

-- View: Account Balance Summary
CREATE OR REPLACE VIEW v_account_summary AS
SELECT 
    p.party_id,
    p.party_name,
    p.party_type,
    a.account_id,
    a.account_type,
    a.current_balance,
    a.currency,
    a.is_active,
    COUNT(DISTINCT t.transaction_id) AS total_transactions,
    SUM(CASE WHEN t.status = 'Completed' THEN t.amount ELSE 0 END) AS total_completed_amount
FROM parties p
JOIN accounts a ON p.party_id = a.party_id
LEFT JOIN transactions t ON (a.account_id = t.sender_account_id OR a.account_id = t.receiver_account_id)
GROUP BY p.party_id, a.account_id;

-- =====================================================
-- SAMPLE DATA INSERTION
-- =====================================================

-- Insert Sample Parties (Users/Customers)
INSERT INTO parties (party_name, party_type, phone_number, national_id, email) VALUES
('Mugisha Moses', 'Individual', '+256701234567', 'CM-123456789', 'mugisha@example.com'),
('Lisa Ineza', 'Individual', '+256702345678', 'CM-987654321', 'lisa@example.com'),
('TechHub Business Ltd', 'Business', '+256703456789', 'BRN-001234', 'info@techhub.ug'),
('Mobile Agent Kampala', 'Agent', '+256704567890', 'AGN-005678', 'agent@kampala.ug'),
('Nkingi Chris', 'Individual', '+256705678901', 'CM-555666777', 'chris@example.com');

-- Insert Sample Accounts
INSERT INTO accounts (party_id, account_type, currency, current_balance, is_active) VALUES
(1, 'Wallet', 'USD', 5000.00, TRUE),
(2, 'Wallet', 'USD', 3500.50, TRUE),
(3, 'Business', 'USD', 15000.00, TRUE),
(4, 'Agent', 'USD', 8200.25, TRUE),
(5, 'Wallet', 'USD', 2750.75, TRUE);

-- Insert Sample Categories
INSERT INTO transaction_categories (category_name, description, is_active) VALUES
('Money Transfer', 'Person-to-person money transfer', TRUE),
('Bill Payment', 'Utility and service bill payments', TRUE),
('Airtime Purchase', 'Mobile airtime top-up', TRUE),
('Merchant Payment', 'Payment to registered merchants', TRUE),
('Cash Withdrawal', 'Cash withdrawal from agents', TRUE);

-- Insert Sample Transactions
INSERT INTO transactions (transaction_code, sender_account_id, receiver_account_id, category_id, amount, currency, status, transaction_timestamp, description) VALUES
('TXN-001-2026-001', 1, 2, 1, 500.00, 'USD', 'Completed', '2026-01-20 14:30:00', 'Payment for services'),
('TXN-001-2026-002', 2, 1, 1, 250.00, 'USD', 'Completed', '2026-01-21 09:15:00', 'Refund'),
('TXN-001-2026-003', 3, 4, 2, 1000.00, 'USD', 'Completed', '2026-01-22 10:45:00', 'Supplier payment'),
('TXN-001-2026-004', 4, 5, 1, 150.00, 'USD', 'Pending', '2026-01-23 15:20:00', 'Agent commission'),
('TXN-001-2026-005', 5, 3, 3, 50.00, 'USD', 'Completed', '2026-01-24 11:00:00', 'Airtime purchase');

-- Insert Sample Fees
INSERT INTO fees (transaction_id, fee_amount, fee_type, fee_percentage) VALUES
(1, 5.00, 'Flat', NULL),
(2, 2.50, 'Flat', NULL),
(3, 10.00, 'Percentage', 1.00),
(4, 1.50, 'Flat', NULL),
(5, 0.50, 'Flat', NULL);

-- Insert Sample Processing Logs
INSERT INTO processing_logs (transaction_id, log_level, message, log_timestamp, process_name, status) VALUES
(1, 'INFO', 'Transaction parsed successfully from XML source', '2026-01-20 14:25:00', 'parse_xml', 'Success'),
(1, 'INFO', 'Amount normalized and validated', '2026-01-20 14:26:00', 'clean_normalize', 'Success'),
(1, 'INFO', 'Transaction categorized as Money Transfer', '2026-01-20 14:27:00', 'categorize', 'Success'),
(1, 'INFO', 'Data loaded into database successfully', '2026-01-20 14:28:00', 'load_db', 'Success'),
(4, 'WARNING', 'Transaction pending verification - exceeds threshold', '2026-01-23 15:20:00', 'load_db', 'Pending');

-- Insert Sample Tags (Many-to-Many)
INSERT INTO transaction_tags (transaction_id, tag_name, assigned_by) VALUES
(1, 'verified', 'system'),
(1, 'high-priority', 'admin'),
(2, 'verified', 'system'),
(3, 'business-transaction', 'system'),
(4, 'requires-review', 'system'),
(5, 'verified', 'system'),
(5, 'airtime', 'system');

-- =====================================================
-- VERIFICATION QUERIES (Run to test database setup)
-- =====================================================

-- Count records in each table
SELECT 'Database Setup Completed Successfully!' AS Status;

SELECT 
    'parties' AS TableName, COUNT(*) AS RecordCount FROM parties
UNION ALL
SELECT 'accounts', COUNT(*) FROM accounts
UNION ALL
SELECT 'transaction_categories', COUNT(*) FROM transaction_categories
UNION ALL
SELECT 'transactions', COUNT(*) FROM transactions
UNION ALL
SELECT 'fees', COUNT(*) FROM fees
UNION ALL
SELECT 'processing_logs', COUNT(*) FROM processing_logs
UNION ALL
SELECT 'transaction_tags', COUNT(*) FROM transaction_tags
ORDER BY TableName;

-- =====================================================
-- END OF DATABASE SETUP SCRIPT
-- =====================================================
(6, 1, 1, 7, '2026-01-24 10:00:00'),
(7, 2, 1, 5, '2026-01-25 15:45:00');

-- VERIFICATION QUERIES
-- ============================================================================

SELECT 'Database Setup Completed Successfully!' AS Status;

SELECT 
    'Users' AS TableName, COUNT(*) AS RecordCount FROM Users
UNION ALL
SELECT 'Transaction_Categories', COUNT(*) FROM Transaction_Categories
UNION ALL
SELECT 'User_Category_Preferences', COUNT(*) FROM User_Category_Preferences
ORDER BY TableName;

