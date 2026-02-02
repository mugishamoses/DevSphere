# MoMo SMS Transaction REST API Documentation

## Overview
This REST API provides secure access to MoMo (Mobile Money) SMS transaction data. The API implements full CRUD operations with Basic Authentication for security.

**Base URL:** `http://localhost:8000`  
**Authentication:** Basic Authentication  
**Content-Type:** `application/json`

## Authentication

The API uses Basic Authentication. Include the `Authorization` header with base64-encoded credentials:

```
Authorization: Basic <base64(username:password)>
```

### Valid Credentials
- **Admin User:** `admin:password123`
- **Regular User:** `user:user123`

### Authentication Example
```bash
# Using curl with admin credentials
curl -u admin:password123 http://localhost:8000/transactions
```

## Endpoints

### 1. List All Transactions
**GET** `/transactions`

Retrieves all transactions in the system.

#### Request Example
```bash
curl -X GET \
  -u admin:password123 \
  http://localhost:8000/transactions
```

#### Response Example (200 OK)
```json
{
  "transactions": [
    {
      "id": 1,
      "transaction_type": "Money Transfer",
      "amount": 10000.0,
      "sender": "+250788123456",
      "receiver": "+250788234567",
      "timestamp": "2026-01-25T10:30:00Z",
      "reference": "TXN20260125001",
      "status": "completed",
      "description": "Payment for services"
    }
  ],
  "total": 1
}
```

### 2. Get Specific Transaction
**GET** `/transactions/{id}`

Retrieves a specific transaction by ID.

#### Request Example
```bash
curl -X GET \
  -u admin:password123 \
  http://localhost:8000/transactions/1
```

#### Response Example (200 OK)
```json
{
  "id": 1,
  "transaction_type": "Money Transfer",
  "amount": 10000.0,
  "sender": "+250788123456",
  "receiver": "+250788234567",
  "timestamp": "2026-01-25T10:30:00Z",
  "reference": "TXN20260125001",
  "status": "completed",
  "description": "Payment for services"
}
```

### 3. Create New Transaction
**POST** `/transactions`

Creates a new transaction record.

#### Request Example
```bash
curl -X POST \
  -u admin:password123 \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_type": "Money Transfer",
    "amount": 15000.0,
    "sender": "+250788111111",
    "receiver": "+250788222222",
    "reference": "TXN20260202001",
    "status": "completed",
    "description": "Family support"
  }' \
  http://localhost:8000/transactions
```

#### Request Body Schema
```json
{
  "transaction_type": "string (required)",
  "amount": "number (required, positive)",
  "sender": "string (required)",
  "receiver": "string (required)",
  "reference": "string (required)",
  "status": "string (required: pending|completed|failed)",
  "timestamp": "string (optional, ISO format)",
  "description": "string (optional)"
}
```

#### Response Example (201 Created)
```json
{
  "id": 26,
  "transaction_type": "Money Transfer",
  "amount": 15000.0,
  "sender": "+250788111111",
  "receiver": "+250788222222",
  "timestamp": "2026-02-02T14:30:00Z",
  "reference": "TXN20260202001",
  "status": "completed",
  "description": "Family support"
}
```

### 4. Update Transaction
**PUT** `/transactions/{id}`

Updates an existing transaction record.

#### Request Example
```bash
curl -X PUT \
  -u admin:password123 \
  -H "Content-Type: application/json" \
  -d '{
    "status": "failed",
    "description": "Transaction failed due to insufficient funds"
  }' \
  http://localhost:8000/transactions/1
```

#### Request Body Schema
All fields are optional for updates:
```json
{
  "transaction_type": "string (optional)",
  "amount": "number (optional, positive)",
  "sender": "string (optional)",
  "receiver": "string (optional)",
  "reference": "string (optional)",
  "status": "string (optional: pending|completed|failed)",
  "description": "string (optional)"
}
```

#### Response Example (200 OK)
```json
{
  "id": 1,
  "transaction_type": "Money Transfer",
  "amount": 10000.0,
  "sender": "+250788123456",
  "receiver": "+250788234567",
  "timestamp": "2026-01-25T10:30:00Z",
  "reference": "TXN20260125001",
  "status": "failed",
  "description": "Transaction failed due to insufficient funds"
}
```

### 5. Delete Transaction
**DELETE** `/transactions/{id}`

Deletes a transaction record.

#### Request Example
```bash
curl -X DELETE \
  -u admin:password123 \
  http://localhost:8000/transactions/1
```

#### Response Example (200 OK)
```json
{
  "message": "Transaction deleted successfully"
}
```

## Error Codes

### HTTP Status Codes
- **200 OK** - Request successful
- **201 Created** - Resource created successfully
- **400 Bad Request** - Invalid request data
- **401 Unauthorized** - Authentication required or invalid credentials
- **404 Not Found** - Resource not found
- **500 Internal Server Error** - Server error

### Error Response Format
```json
{
  "error": "Error message description",
  "status_code": 400
}
```

### Common Error Examples

#### 401 Unauthorized
```json
{
  "error": "Unauthorized",
  "status_code": 401
}
```

#### 404 Not Found
```json
{
  "error": "Transaction not found",
  "status_code": 404
}
```

#### 400 Bad Request - Missing Field
```json
{
  "error": "Missing required field: amount",
  "status_code": 400
}
```

#### 400 Bad Request - Invalid Amount
```json
{
  "error": "Amount must be positive",
  "status_code": 400
}
```

#### 400 Bad Request - Invalid Status
```json
{
  "error": "Status must be one of: pending, completed, failed",
  "status_code": 400
}
```

## Data Models

### Transaction Object
```json
{
  "id": "integer (auto-generated)",
  "transaction_type": "string",
  "amount": "number (positive)",
  "sender": "string",
  "receiver": "string",
  "timestamp": "string (ISO 8601 format)",
  "reference": "string (unique identifier)",
  "status": "string (pending|completed|failed)",
  "description": "string"
}
```

### Transaction Types
Common transaction types in the system:
- `Money Transfer`
- `Money Received`
- `Payment`
- `Bank Deposit`
- `Cash Withdrawal`
- `Utility Payment`
- `Airtime Purchase`
- `Bill Payment`
- `Merchant Payment`

## Rate Limiting
Currently, no rate limiting is implemented. In production, consider implementing:
- Request rate limits per user
- Concurrent connection limits
- API key-based access control

## Security Considerations

### Current Implementation
- **Basic Authentication** - Simple username/password authentication
- **CORS Headers** - Allows cross-origin requests
- **Input Validation** - Validates required fields and data types

### Security Limitations of Basic Auth
1. **Credentials in Plain Text** - Base64 encoding is not encryption
2. **No Session Management** - Credentials sent with every request
3. **No Token Expiration** - Credentials remain valid indefinitely
4. **Vulnerable to Interception** - Should only be used over HTTPS

### Recommended Security Improvements
1. **JWT (JSON Web Tokens)**
   - Stateless authentication
   - Token expiration
   - Payload encryption
   
2. **OAuth 2.0**
   - Industry standard
   - Delegated authorization
   - Refresh token mechanism
   
3. **API Keys**
   - Unique keys per client
   - Easy revocation
   - Usage tracking

4. **HTTPS Only**
   - Encrypt all communications
   - Prevent credential interception
   
5. **Input Sanitization**
   - Prevent injection attacks
   - Validate all input data

## Testing the API

### Using curl
```bash
# Test authentication
curl -u admin:password123 http://localhost:8000/transactions

# Test unauthorized access
curl http://localhost:8000/transactions

# Create transaction
curl -X POST -u admin:password123 \
  -H "Content-Type: application/json" \
  -d '{"transaction_type":"Test","amount":1000,"sender":"Test","receiver":"Test","reference":"TEST001","status":"completed"}' \
  http://localhost:8000/transactions
```

### Using Postman
1. Set Authorization to "Basic Auth"
2. Enter username: `admin`, password: `password123`
3. Set Content-Type header to `application/json`
4. Test all endpoints with various payloads

## Running the API Server

### Start Server
```bash
cd api
python app.py
```

### Server Information
- **Port:** 8000 (default)
- **Host:** localhost (0.0.0.0)
- **Protocol:** HTTP

### Server Output
```
Starting MoMo SMS Transaction API server on port 8000
API Endpoints:
  GET    /transactions     - List all transactions
  GET    /transactions/{id} - Get specific transaction
  POST   /transactions     - Create new transaction
  PUT    /transactions/{id} - Update transaction
  DELETE /transactions/{id} - Delete transaction

Authentication: Basic Auth
  Username: admin, Password: password123
  Username: user, Password: user123

Press Ctrl+C to stop the server
```