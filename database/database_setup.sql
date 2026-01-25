DROP DATABASE IF EXISTS momo_sms_system;

CREATE DATABASE momo_sms_system
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE momo_sms_system;

CREATE TABLE Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for each user',
    phone_number VARCHAR(15) NOT NULL UNIQUE COMMENT 'User phone number (unique MoMo identifier)',
    full_name VARCHAR(100) NOT NULL COMMENT 'Full name of the user',
    email VARCHAR(100) UNIQUE COMMENT 'User email address',
    account_balance DECIMAL(15,2) DEFAULT 0.00 COMMENT 'Current account balance in RWF',
    registration_date DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Date user registered with the system',
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active' COMMENT 'Account status: active, inactive, or suspended',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record last update timestamp',
    
    CONSTRAINT chk_phone_format CHECK (phone_number REGEXP '^[0-9]{10,15}$'),
    CONSTRAINT chk_balance_positive CHECK (account_balance >= 0),
    CONSTRAINT chk_email_format CHECK (email IS NULL OR email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Stores MoMo user account information and balance tracking';

CREATE INDEX idx_phone_number ON Users(phone_number);
CREATE INDEX idx_status ON Users(status);
CREATE INDEX idx_registration_date ON Users(registration_date);

CREATE TABLE Transaction_Categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for each category',
    category_name VARCHAR(50) NOT NULL UNIQUE COMMENT 'Name of transaction category',
    description TEXT COMMENT 'Detailed description of what this category covers',
    fee_percentage DECIMAL(5,2) DEFAULT 0.00 COMMENT 'Transaction fee as percentage of amount',
    is_active BOOLEAN DEFAULT TRUE COMMENT 'Whether category is currently active for new transactions',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record last update timestamp',
    
    CONSTRAINT chk_fee_percentage CHECK (fee_percentage >= 0 AND fee_percentage <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Categorizes and manages different types of MoMo transactions';

CREATE INDEX idx_category_name ON Transaction_Categories(category_name);
CREATE INDEX idx_is_active ON Transaction_Categories(is_active);

CREATE TABLE Transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique transaction identifier',
    sender_id INT NOT NULL COMMENT 'User ID of transaction sender',
    receiver_id INT NOT NULL COMMENT 'User ID of transaction receiver',
    category_id INT NOT NULL COMMENT 'Transaction category ID',
    amount DECIMAL(15,2) NOT NULL COMMENT 'Transaction amount in RWF',
    transaction_date DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Date and time of transaction',
    status ENUM('pending', 'completed', 'failed', 'reversed') DEFAULT 'pending' COMMENT 'Transaction status',
    reference_number VARCHAR(50) NOT NULL UNIQUE COMMENT 'Unique transaction reference for tracking',
    notes TEXT COMMENT 'Additional transaction notes or description',
    fee_amount DECIMAL(10,2) DEFAULT 0.00 COMMENT 'Transaction fee charged based on category',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record last update timestamp',
    
    CONSTRAINT fk_sender FOREIGN KEY (sender_id) 
        REFERENCES Users(user_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_receiver FOREIGN KEY (receiver_id) 
        REFERENCES Users(user_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_category FOREIGN KEY (category_id) 
        REFERENCES Transaction_Categories(category_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    
    CONSTRAINT chk_amount_positive CHECK (amount > 0),
    CONSTRAINT chk_different_users CHECK (sender_id != receiver_id),
    CONSTRAINT chk_fee_positive CHECK (fee_amount >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Stores all mobile money transaction records with full audit trail';

CREATE INDEX idx_sender_id ON Transactions(sender_id);
CREATE INDEX idx_receiver_id ON Transactions(receiver_id);
CREATE INDEX idx_category_id ON Transactions(category_id);
CREATE INDEX idx_transaction_date ON Transactions(transaction_date);
CREATE INDEX idx_status ON Transactions(status);
CREATE INDEX idx_reference_number ON Transactions(reference_number);
CREATE INDEX idx_sender_date ON Transactions(sender_id, transaction_date);

CREATE TABLE System_Logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique log identifier',
    transaction_id INT COMMENT 'Related transaction ID (nullable for system-level logs)',
    log_type VARCHAR(50) NOT NULL COMMENT 'Type of log entry (e.g., TRANSACTION_INIT, ERROR)',
    log_message TEXT NOT NULL COMMENT 'Detailed log message describing the event',
    severity ENUM('info', 'warning', 'error', 'critical') DEFAULT 'info' COMMENT 'Log severity level',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Log entry timestamp',
    
    CONSTRAINT fk_transaction_log FOREIGN KEY (transaction_id) 
        REFERENCES Transactions(transaction_id) 
        ON DELETE SET NULL 
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='System audit logs and transaction processing events';

CREATE INDEX idx_transaction_id ON System_Logs(transaction_id);
CREATE INDEX idx_log_type ON System_Logs(log_type);
CREATE INDEX idx_created_at ON System_Logs(created_at);
CREATE INDEX idx_severity ON System_Logs(severity);

CREATE TABLE User_Category_Preferences (
    preference_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique preference identifier',
    user_id INT NOT NULL COMMENT 'User ID',
    category_id INT NOT NULL COMMENT 'Transaction category ID',
    preference_level INT DEFAULT 1 COMMENT 'Preference ranking (1=highest priority)',
    last_used_date DATETIME COMMENT 'Last time user used this category',
    usage_count INT DEFAULT 0 COMMENT 'Number of times category was used by this user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record last update timestamp',
    
    CONSTRAINT fk_user_preference FOREIGN KEY (user_id) 
        REFERENCES Users(user_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_category_preference FOREIGN KEY (category_id) 
        REFERENCES Transaction_Categories(category_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    
    CONSTRAINT unique_user_category UNIQUE (user_id, category_id),
    
    CONSTRAINT chk_preference_level CHECK (preference_level > 0),
    CONSTRAINT chk_usage_count CHECK (usage_count >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Junction table for user-category many-to-many relationship';

CREATE INDEX idx_user_id ON User_Category_Preferences(user_id);
CREATE INDEX idx_category_id ON User_Category_Preferences(category_id);
CREATE INDEX idx_preference_level ON User_Category_Preferences(preference_level);

CREATE VIEW vw_transaction_details AS
SELECT 
    t.transaction_id,
    t.reference_number,
    CONCAT(u1.full_name, ' (', u1.phone_number, ')') AS sender,
    CONCAT(u2.full_name, ' (', u2.phone_number, ')') AS receiver,
    tc.category_name,
    t.amount,
    t.fee_amount,
    (t.amount + t.fee_amount) AS total_deducted,
    t.status,
    t.transaction_date,
    t.notes
FROM Transactions t
INNER JOIN Users u1 ON t.sender_id = u1.user_id
INNER JOIN Users u2 ON t.receiver_id = u2.user_id
INNER JOIN Transaction_Categories tc ON t.category_id = tc.category_id
ORDER BY t.transaction_date DESC;

CREATE VIEW vw_user_transaction_summary AS
SELECT 
    u.user_id,
    u.full_name,
    u.phone_number,
    COUNT(DISTINCT t1.transaction_id) AS total_sent,
    COUNT(DISTINCT t2.transaction_id) AS total_received,
    COALESCE(SUM(CASE WHEN t1.status = 'completed' THEN t1.amount ELSE 0 END), 0) AS total_sent_amount,
    COALESCE(SUM(CASE WHEN t2.status = 'completed' THEN t2.amount ELSE 0 END), 0) AS total_received_amount,
    COALESCE(SUM(CASE WHEN t1.status = 'completed' THEN t1.fee_amount ELSE 0 END), 0) AS total_fees_paid,
    u.account_balance,
    u.status
FROM Users u
LEFT JOIN Transactions t1 ON u.user_id = t1.sender_id AND t1.status = 'completed'
LEFT JOIN Transactions t2 ON u.user_id = t2.receiver_id AND t2.status = 'completed'
GROUP BY u.user_id, u.full_name, u.phone_number, u.account_balance, u.status;

-- View: Daily Transaction Summary for Analytics
SELECT 
    DATE(t.transaction_date) AS transaction_date,
    tc.category_name,
    COUNT(t.transaction_id) AS transaction_count,
    SUM(t.amount) AS total_amount,
    SUM(t.fee_amount) AS total_fees,
    COUNT(CASE WHEN t.status = 'completed' THEN 1 END) AS completed_count,
    COUNT(CASE WHEN t.status = 'failed' THEN 1 END) AS failed_count,
    COUNT(CASE WHEN t.status = 'pending' THEN 1 END) AS pending_count
FROM Transactions t
INNER JOIN Transaction_Categories tc ON t.category_id = tc.category_id
GROUP BY DATE(t.transaction_date), tc.category_name
ORDER BY transaction_date DESC;

-- ============================================================================
DELIMITER //
_id INT)
BEGIN
    SELECT 
        t.transaction_id,
        t.reference_number,
        CASE 
            WHEN t.sender_id = p_user_id THEN 'SENT'
            ELSE 'RECEIVED'
        END AS transaction_type,
        CASE 
            WHEN t.sender_id = p_user_id THEN u2.full_name
            ELSE u1.full_name
        END AS other_party,
        CASE 
            WHEN t.sender_id = p_user_id THEN u2.phone_number
            ELSE u1.phone_number
        END AS other_party_phone,
        tc.category_name,
        t.amount,
        t.fee_amount,
        t.status,
        t.transaction_date,
        t.notes
    FROM Transactions t
    INNER JOIN Users u1 ON t.sender_id = u1.user_id
    INNER JOIN Users u2 ON t.receiver_id = u2.user_id
    INNER JOIN Transaction_Categories tc ON t.category_id = tc.category_id
    WHERE t.sender_id = p_user_id OR t.receiver_id = p_user_id
    ORDER BY t.transaction_date DESC;
END //

-- Procedure: Get User Account Summary
CREATE PROCEDURE sp_get_user_summary(IN p_user_id INT)
BEGIN
    SELECT 
        u.user_id,
        u.full_name,
        u.email,
        u.account_balance,
        u.status,
        u.registration_date,
        COUNT(DISTINCT t1.transaction_id) AS total_transactions_sent,
        COUNT(DISTINCT t2.transaction_id) AS total_transactions_received,
        COALESCE(SUM(t1.amount), 0) AS total_amount_sent,
        COALESCE(SUM(t2.amount), 0) AS total_amount_received
    FROM Users u
    LEFT JOIN Transactions t1 ON u.user_id = t1.sender_id AND t1.status = 'completed'
    LEFT JOIN Transactions t2 ON u.user_id = t2.receiver_id AND t2.status = 'completed'
    WHERE u.user_id = p_user_id
    GROUP BY u.user_id, u.full_name, u.phone_number, u.email, u.account_balance, u.status, u.registration_date;
END //

DELIMITER ;

-- ============================================================================
-- TRIGGERS FOR AUTOMATED BUSINESS LOGIC
-- ============================================================================

DELIMITER //

DELIMITER //

        UPDATE Users 
        SET account_balance = account_balance - (NEW.amount + NEW.fee_amount)
        WHERE user_id = NEW.sender_id;
        
        -- Add to receiver (amount only, receiver doesn't pay fee)
        UPDATE Users 
        SET account_balance = account_balance + NEW.amount
        WHERE user_id = NEW.receiver_id;
        
        -- Log the balance update
        UPDATE Users 
        SET account_balance = account_balance - (NEW.amount + NEW.fee_amount)
        WHERE user_id = NEW.sender_id;
        
        UPDATE Users 
        SET account_balance = account_balance + NEW.amount
        WHERE user_id = NEW.receiver_id;
        
        INSERT INTO System_Logs (transaction_id, log_type, log_message, severity)
        VALUES (NEW.transaction_id, 'BALANCE_UPDATE', 
                CONCAT('Balances updated - Sender: -', NEW.amount + NEW.fee_amount, 
                       ', Receiver: +', NEW.amount, ' for TXN: ', NEW.reference_number), 'info');
    END IF;
END //

        IF sender_balance < (NEW.amount + NEW.fee_amount) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient balance for this transaction';
        END IF;
    END IF;
END //

-- Trigger: Log transaction status changes
CREATE TRIGGER trg_log_transaction_status
AFTER UPDATE ON Transactions
FOR EACH ROW
BEGIN
    IF NEW.status != OLD.status THEN
        INSERT INTO System_Logs (transaction_id, log_type, log_message, severity)
        VALUES (NEW.transaction_id, 'TRANSACTION_STATUS_CHANGE', 
                CONCAT('Transaction status changed from ', OLD.status, ' to ', NEW.status),
                IF(NEW.status = 'failed', 'warning', 'info'));
END //

DELIMITER ;

-- ============================================================================
-- SAMPLE DATA INSERTION
-- ============================================================================

-- Insert Transaction Categories (Master Data)
INSERT INTO Transaction_Categories (category_name, description, fee_percentage, is_active) VALUES
('Money Transfer', 'Person-to-person money transfer for personal payments', 1.50, TRUE),
('Bill Payment', 'Utility and service bill payments (electricity, water, internet)', 0.75, TRUE),
('Airtime Purchase', 'Mobile airtime top-up for telecom services', 0.00, TRUE),
('Merchant Payment', 'Payment to registered merchants and businesses', 1.00, TRUE),
('Withdraw Cash', 'Cash withdrawal from authorized agents', 2.00, TRUE),
('250788123456', 'Jean Claude Mugabo', 'jc.mugabo@email.com', 50000.00, 'active'),
('250788234567', 'Marie Grace Uwera', 'mg.uwera@email.com', 125000.00, 'active'),
('250788345678', 'Eric Nsabimana', 'e.nsabimana@email.com', 75000.00, 'active'),
('250788456789', 'Diane Mutoni', 'd.mutoni@email.com', 200000.00, 'active'),
('250788567890', 'Patrick Habimana', 'p.habimana@email.com', 30000.00, 'active'),
('250788678901', 'Sarah Kayitesi', 's.kayitesi@email.com', 95000.00, 'active'),
('250788789012', 'David Nkusi', 'd.nkusi@email.com', 150000.00, 'active');

-- Insert Transactions (Sample Test Data - Real Transaction Scenarios)
INSERT INTO Transactions (sender_id, receiver_id, category_id, amount, status, reference_number, fee_amount, notes) VALUES
(1, 2, 1, 10000.00, 'completed', 'TXN20260125001', 150.00, 'Payment for services'),
(2, 3, 1, 25000.00, 'completed', 'TXN20260125002', 375.00, 'Family support'),
(3, 4, 4, 50000.00, 'completed', 'TXN20260125003', 500.00, 'Shop payment'),
(5, 1, 1, 5000.00, 'completed', 'TXN20260125005', 75.00, 'Loan repayment'),
(6, 7, 1, 30000.00, 'pending', 'TXN20260125006', 450.00, 'Business transaction'),
(1, 3, 3, 2000.00, 'completed', 'TXN20260125007', 0.00, 'Airtime purchase'),
(7, 2, 2, 12000.00, 'completed', 'TXN20260125008', 90.00, 'Electricity bill');

-- Insert System Logs (Audit Trail)
INSERT INTO System_Logs (transaction_id, log_type, log_message, severity) VALUES
(1, 'TRANSACTION_INIT', 'Transaction initiated by user 1', 'info'),
(1, 'TRANSACTION_COMPLETE', 'Transaction completed successfully', 'info'),
(2, 'TRANSACTION_INIT', 'Transaction initiated by user 2', 'info'),
(3, 'TRANSACTION_INIT', 'Transaction initiated by user 3', 'info'),
(3, 'TRANSACTION_COMPLETE', 'Transaction completed successfully', 'info'),
(6, 'TRANSACTION_INIT', 'Transaction initiated by user 6', 'info'),
(6, 'TRANSACTION_PENDING', 'Transaction pending receiver confirmation', 'warning'),
(NULL, 'SYSTEM_STARTUP', 'MoMo SMS system started successfully', 'info'),
(NULL, 'DATA_BACKUP', 'Daily data backup completed', 'info');
-- Insert User Category Preferences (User Behavior Data)
INSERT INTO User_Category_Preferences (user_id, category_id, preference_level, usage_count, last_used_date) VALUES
(1, 1, 1, 5, '2026-01-25 10:30:00'),
(1, 3, 2, 3, '2026-01-25 09:15:00'),
(2, 1, 1, 8, '2026-01-25 11:20:00'),
(2, 4, 2, 4, '2026-01-24 14:30:00'),
(3, 4, 1, 6, '2026-01-25 08:45:00'),
(3, 1, 2, 2, '2026-01-23 16:20:00'),
(4, 1, 1, 10, '2026-01-25 12:00:00'),
(5, 1, 1, 3, '2026-01-25 13:30:00'),
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

