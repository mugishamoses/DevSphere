# MoMo SMS Data Processing System - Database Design Document

**Date:** January 25, 2026  
**Database Name:** momo_db  
**Version:** 1.0  

---

## Executive Summary

This document outlines the comprehensive database design for the DevSphere MoMo SMS data processing system. The database implements a normalized relational schema designed to efficiently store, retrieve, and analyze mobile money transaction data while maintaining data integrity and supporting future scalability.

---

## 1. Database Design Rationale

### 1.1 Architecture Overview

The database architecture follows **Third Normal Form (3NF)** principles to ensure:
- **Data Integrity:** Foreign key constraints prevent orphaned records
- **Scalability:** Proper indexing enables fast queries on large datasets
- **Maintainability:** Clear entity relationships facilitate future modifications
- **Audit Trail:** Complete logging of all transactions and system events

### 1.2 Key Design Decisions

#### Entity Separation
- **Parties vs Accounts:** Separated to support multiple accounts per user (e.g., Wallet + Savings)
- **Fees Table:** Decoupled from Transactions for flexible fee calculation and auditing
- **Processing Logs:** Independent table for comprehensive ETL pipeline tracking
- **Tags (Many-to-Many):** Junction table for flexible transaction categorization

#### Referential Integrity
- **ON DELETE CASCADE:** Applied to child tables (fees, tags) for automatic cleanup
- **ON DELETE RESTRICT:** Applied to core entities to prevent accidental deletion
- **ON DELETE SET NULL:** Applied to optional foreign keys (logs, categories)

#### Performance Optimization
- **Composite Indexes:** Created on frequently queried combinations (status + timestamp)
- **Foreign Key Indexes:** Automatic indexes on all FK columns for JOIN performance
- **Covering Indexes:** Designed to minimize disk I/O

---

## 2. Data Dictionary

### 2.1 Table: parties

**Purpose:** Stores information about all participants (users, customers, agents)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| party_id | INT | PK, AUTO_INCREMENT | Unique identifier |
| party_name | VARCHAR(255) | NOT NULL | Full name of party |
| party_type | ENUM | NOT NULL | Individual, Business, or Agent |
| phone_number | VARCHAR(20) | NOT NULL, UNIQUE | Mobile number (10-20 chars) |
| national_id | VARCHAR(50) | UNIQUE, NULLABLE | Government ID number |
| email | VARCHAR(255) | NULLABLE | Email address |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Record creation time |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Last update time |

**Indexes:**
- `idx_phone`: Phone number lookup
- `idx_party_type`: Query by party classification

**CHECK Constraints:**
- `LENGTH(phone_number) >= 10`: Minimum phone length validation

---

### 2.2 Table: accounts

**Purpose:** Financial accounts belonging to parties with balance tracking

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| account_id | INT | PK, AUTO_INCREMENT | Unique account identifier |
| party_id | INT | FK (parties), NOT NULL | Reference to party owner |
| account_type | ENUM | NOT NULL, DEFAULT 'Wallet' | Wallet, Savings, Business, Agent |
| currency | VARCHAR(3) | NOT NULL, DEFAULT 'USD' | ISO 4217 currency code |
| current_balance | DECIMAL(15,2) | NOT NULL, DEFAULT 0 | Current account balance |
| is_active | BOOLEAN | NOT NULL, DEFAULT TRUE | Account status |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Creation timestamp |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Last update timestamp |

**Indexes:**
- `idx_party_id`: Find accounts by party
- `idx_active`: Query active accounts

**CHECK Constraints:**
- `current_balance >= 0`: Prevent negative balances

---

### 2.3 Table: transaction_categories

**Purpose:** Classification system for transaction types

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| category_id | INT | PK, AUTO_INCREMENT | Unique category identifier |
| category_name | VARCHAR(100) | NOT NULL, UNIQUE | Category label |
| description | TEXT | NULLABLE | Detailed category description |
| is_active | BOOLEAN | NOT NULL, DEFAULT TRUE | Category availability status |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Creation timestamp |

**Indexes:**
- `idx_active`: Query active categories

**Sample Categories:**
- Money Transfer
- Bill Payment
- Airtime Purchase
- Merchant Payment
- Cash Withdrawal

---

### 2.4 Table: transactions (Core Entity)

**Purpose:** Master table storing all mobile money transactions

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| transaction_id | INT | PK, AUTO_INCREMENT | Unique transaction identifier |
| transaction_code | VARCHAR(50) | NOT NULL, UNIQUE | External reference code |
| sender_account_id | INT | FK (accounts), NOT NULL | Sender's account |
| receiver_account_id | INT | FK (accounts), NOT NULL | Receiver's account |
| category_id | INT | FK (categories), NULLABLE | Transaction category |
| amount | DECIMAL(15,2) | NOT NULL | Transaction amount |
| currency | VARCHAR(3) | NOT NULL, DEFAULT 'USD' | Transaction currency |
| status | ENUM | NOT NULL, DEFAULT 'Pending' | Pending, Completed, Failed, Reversed |
| transaction_timestamp | DATETIME | NOT NULL | Transaction date/time |
| description | VARCHAR(500) | NULLABLE | Transaction notes |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Record creation time |

**Indexes:**
- `idx_sender`: Query transactions by sender
- `idx_receiver`: Query transactions by receiver
- `idx_category`: Query transactions by category
- `idx_status`: Query by transaction status
- `idx_timestamp`: Query by date range
- `idx_transaction_code`: Quick lookup by code
- `idx_transaction_status_date`: Composite for status reports

**CHECK Constraints:**
- `amount > 0`: Ensure positive amounts
- `sender_account_id != receiver_account_id`: Prevent self-transfers

---

### 2.5 Table: fees

**Purpose:** Transaction fees for auditing and revenue tracking

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| fee_id | INT | PK, AUTO_INCREMENT | Unique fee identifier |
| transaction_id | INT | FK (transactions), NOT NULL | Related transaction |
| fee_amount | DECIMAL(15,2) | NOT NULL | Fee amount charged |
| fee_type | ENUM | NOT NULL | Flat, Percentage, Tiered |
| fee_percentage | DECIMAL(5,3) | NULLABLE | Percentage if applicable |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Creation timestamp |

**Indexes:**
- `idx_transaction_id`: Find fees by transaction

**CHECK Constraints:**
- `fee_amount >= 0`: Non-negative fees

---

### 2.6 Table: processing_logs

**Purpose:** Comprehensive audit trail of ETL pipeline operations

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| log_id | INT | PK, AUTO_INCREMENT | Unique log entry identifier |
| transaction_id | INT | FK (transactions), NULLABLE | Related transaction (optional) |
| log_level | ENUM | NOT NULL | DEBUG, INFO, WARNING, ERROR, CRITICAL |
| message | TEXT | NOT NULL | Log message content |
| log_timestamp | DATETIME | NOT NULL, DEFAULT NOW() | When log was created |
| process_name | VARCHAR(100) | NULLABLE | ETL step name (parse_xml, clean_normalize, categorize, load_db) |
| status | VARCHAR(50) | NULLABLE | Process status (Success, Pending, Failed) |

**Indexes:**
- `idx_level`: Query by severity level
- `idx_timestamp`: Query by date range
- `idx_transaction_id`: Find logs for transaction
- `idx_process_name`: Query by ETL step

**Sample ETL Stages:**
1. **parse_xml**: XML parsing and validation
2. **clean_normalize**: Data cleaning and normalization
3. **categorize**: Automatic category assignment
4. **load_db**: Database insertion and balance updates

---

### 2.7 Table: transaction_tags (Junction Table - Many-to-Many)

**Purpose:** Apply multiple flexible tags/labels to transactions

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| transaction_id | INT | FK (transactions), PK Part 1 | Related transaction |
| tag_name | VARCHAR(50) | NOT NULL, PK Part 2 | Tag label |
| assigned_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | When tag was assigned |
| assigned_by | VARCHAR(100) | NULLABLE | User/system that assigned tag |

**Indexes:**
- `idx_tag_name`: Find transactions by tag

**Sample Tags:**
- `verified`: Transaction has been verified
- `high-priority`: Requires expedited processing
- `business-transaction`: Business account transaction
- `requires-review`: Flagged for manual review
- `fraud-suspected`: Potential fraud alert
- `airtime`: Airtime purchase category
- `bulk-transaction`: Batch processing

---

## 3. Views for Common Queries

### 3.1 v_transaction_summary
Provides complete transaction details with party and category information

```sql
SELECT 
    transaction_id,
    transaction_code,
    sender_name,
    receiver_name,
    category_name,
    amount,
    currency,
    status,
    transaction_timestamp
```

### 3.2 v_account_summary
Shows account balances with transaction statistics

```sql
SELECT 
    party_id,
    party_name,
    party_type,
    account_id,
    account_type,
    current_balance,
    currency,
    is_active,
    total_transactions,
    total_completed_amount
```

---

## 4. Security Features

### 4.1 Database-Level Security

#### 1. CHECK Constraints
```sql
-- Balance cannot be negative
CHECK (current_balance >= 0)

-- Transaction amount must be positive
CHECK (amount > 0)

-- Prevent self-transfers
CHECK (sender_account_id != receiver_account_id)

-- Phone number minimum length
CHECK (LENGTH(phone_number) >= 10)
```

#### 2. Referential Integrity
- **Foreign Key Constraints:** Prevent orphaned records
- **CASCADE Deletes:** Automatically remove related records (fees, tags)
- **RESTRICT Deletes:** Prevent deletion of core entities still in use

#### 3. Unique Constraints
- `phone_number`: Prevents duplicate registrations
- `transaction_code`: Ensures idempotent transaction processing
- `category_name`: Prevents duplicate category names

#### 4. Audit Logging
- `created_at` timestamp: Track record creation
- `updated_at` timestamp: Track modifications
- `processing_logs` table: Complete ETL audit trail
- `assigned_by` field: Track who made changes

### 4.2 Data Validation Rules

| Entity | Rule | Implementation |
|--------|------|-----------------|
| Account | Non-negative balance | CHECK constraint |
| Transaction | Positive amount | CHECK constraint |
| Transaction | Different sender/receiver | CHECK constraint |
| Party | Valid phone format | CHECK constraint (length) |
| Fee | Non-negative fee | CHECK constraint |

---

## 5. Sample CRUD Operations

### 5.1 CREATE - Insert New Transaction

```sql
-- Create transaction and automatically record fees and logs
INSERT INTO transactions (
    transaction_code, sender_account_id, receiver_account_id,
    category_id, amount, currency, status,
    transaction_timestamp, description
) VALUES (
    'TXN-001-2026-006', 1, 2, 1, 500.00, 'USD',
    'Completed', NOW(), 'Payment for services'
);

INSERT INTO fees (transaction_id, fee_amount, fee_type)
VALUES (LAST_INSERT_ID(), 5.00, 'Flat');

INSERT INTO processing_logs (transaction_id, log_level, message, process_name, status)
VALUES (LAST_INSERT_ID(), 'INFO', 'Transaction created successfully', 'load_db', 'Success');
```

### 5.2 READ - Query Transaction Summary

```sql
SELECT * FROM v_transaction_summary
WHERE transaction_timestamp BETWEEN DATE_SUB(NOW(), INTERVAL 7 DAY) AND NOW()
AND status = 'Completed'
ORDER BY transaction_timestamp DESC;
```

### 5.3 UPDATE - Change Transaction Status

```sql
UPDATE transactions
SET status = 'Completed'
WHERE transaction_id = 1;

-- Automatically logged
INSERT INTO processing_logs (transaction_id, log_level, message, process_name)
VALUES (1, 'INFO', 'Transaction status changed to Completed', 'load_db');
```

### 5.4 DELETE - Remove Old Logs (with safety)

```sql
-- Delete logs older than 90 days (transactions preserved due to RESTRICT)
DELETE FROM processing_logs
WHERE log_timestamp < DATE_SUB(NOW(), INTERVAL 90 DAY);
```

---

## 6. Performance Characteristics

### 6.1 Query Performance Indexes

| Index | Purpose | Expected Query Time |
|-------|---------|-------------------|
| idx_transaction_code | Lookup by code | O(log n) - Instant |
| idx_sender | Find user's sent transactions | O(log n) |
| idx_status | Filter by completion status | O(log n) |
| idx_timestamp | Date range queries | O(log n) + sorting |
| idx_party_id | User account lookup | O(log n) |

### 6.2 Optimization Strategies

1. **Composite Indexes:** `idx_transaction_status_date` for common report queries
2. **Covering Indexes:** Include commonly selected columns
3. **Denormalization Consideration:** current_balance on accounts avoids SUM aggregation
4. **Partitioning:** Future - partition transactions table by month for archived data

---

## 7. Scalability Considerations

### 7.1 Current Capacity
- Supports 1-10M transactions
- Multi-user concurrent access
- Daily transaction volume: 10K-100K

### 7.2 Future Enhancements
1. **Table Partitioning:** By transaction date
2. **Archival Strategy:** Move old logs to separate tables
3. **Read Replicas:** For reporting queries
4. **Sharding:** By party_id for massive scale

---

## 8. Database Deployment Instructions

### 8.1 Installation

```bash
# 1. Log into MySQL
mysql -u root -p

# 2. Run setup script
SOURCE database/database_setup.sql;

# 3. Verify installation
USE momo_db;
SHOW TABLES;
```

### 8.2 Verification Queries

```sql
-- Verify all tables created
SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'momo_db';

-- Check sample data loaded
SELECT COUNT(*) FROM parties;
SELECT COUNT(*) FROM transactions;
SELECT COUNT(*) FROM processing_logs;
```

---

## 9. Data Backup and Recovery

### 9.1 Backup Strategy
```sql
-- Full database backup (weekly)
mysqldump -u root -p momo_db > backup_momo_db_2026-01-25.sql

-- Incremental backup (daily)
mysqldump --all-databases --single-transaction > full_backup.sql
```

### 9.2 Recovery
```sql
-- Restore from backup
mysql -u root -p momo_db < backup_momo_db_2026-01-25.sql
```

---

## 10. Unique Rules for Enhanced Security & Accuracy

### Rule 1: Prevent Duplicate Transactions
- **Implementation:** UNIQUE constraint on `transaction_code`
- **Benefit:** Prevents reprocessing of same transaction
- **Impact:** Idempotent ETL pipeline

### Rule 2: Balance Integrity
- **Implementation:** CHECK constraint `current_balance >= 0`
- **Benefit:** Prevents negative balances causing financial discrepancies
- **Impact:** No overdraft without explicit authorization

### Rule 3: Self-Transfer Prevention
- **Implementation:** CHECK constraint `sender_account_id != receiver_account_id`
- **Benefit:** Prevents circular transactions and fraud
- **Impact:** All transactions represent real value movement

### Rule 4: Atomic Fee Association
- **Implementation:** Foreign key with CASCADE delete between transactions and fees
- **Benefit:** Fees automatically removed with transaction (accounting accuracy)
- **Impact:** No orphaned fee records

### Rule 5: Audit Trail Immutability
- **Implementation:** Append-only processing_logs with timestamps
- **Benefit:** Cannot alter historical logs (compliance requirement)
- **Impact:** Complete forensic capability

### Rule 6: Phone Number Validation
- **Implementation:** UNIQUE constraint + CHECK (LENGTH >= 10)
- **Benefit:** Prevents duplicate registrations and invalid formats
- **Impact:** Reliable party identification

### Rule 7: Status State Machine
- **Implementation:** ENUM (Pending, Completed, Failed, Reversed)
- **Benefit:** Only valid states allowed
- **Impact:** Prevents invalid transaction states

---

## 11. Future Enhancements

1. **Real-Time Analytics:** Add materialized views for dashboards
2. **Encryption:** At-rest encryption for sensitive fields (national_id, email)
3. **Row-Level Security:** User can only see their own transactions
4. **API Rate Limiting:** Track API calls in database
5. **Machine Learning:** Fraud detection tables and models

---

## Conclusion

The MoMo SMS database design provides a solid, scalable foundation for processing mobile money transactions. The normalized structure ensures data integrity, while comprehensive logging provides audit trails for compliance. Future enhancements can be added without major restructuring.

---

**Document Version:** 1.0  
**Last Updated:** January 25, 2026  
**Next Review:** March 25, 2026
