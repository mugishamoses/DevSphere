#!/bin/bash

# API Testing Script for MoMo SMS Transaction API
# This script tests all endpoints with proper authentication

API_BASE="http://localhost:8000"
ADMIN_AUTH="admin:password123"
INVALID_AUTH="invalid:wrong"

echo "=== MoMo SMS Transaction API Testing ==="
echo "Base URL: $API_BASE"
echo

# Test 1: Unauthorized request (should return 401)
echo "Test 1: Unauthorized request"
echo "Command: curl -s $API_BASE/transactions"
curl -s $API_BASE/transactions | jq .
echo
echo "---"
echo

# Test 2: Valid authentication - GET all transactions
echo "Test 2: GET all transactions (with auth)"
echo "Command: curl -s -u $ADMIN_AUTH $API_BASE/transactions"
curl -s -u $ADMIN_AUTH $API_BASE/transactions | jq '.transactions | length'
echo
echo "---"
echo

# Test 3: GET specific transaction
echo "Test 3: GET specific transaction (ID: 1)"
echo "Command: curl -s -u $ADMIN_AUTH $API_BASE/transactions/1"
curl -s -u $ADMIN_AUTH $API_BASE/transactions/1 | jq .
echo
echo "---"
echo

# Test 4: POST new transaction
echo "Test 4: POST new transaction"
NEW_TRANSACTION='{
  "transaction_type": "Money Transfer",
  "amount": 50000.0,
  "sender": "+250788999999",
  "receiver": "+250788888888",
  "reference": "TEST_API_001",
  "status": "completed",
  "description": "API Test Transaction"
}'

echo "Command: curl -s -X POST -u $ADMIN_AUTH -H 'Content-Type: application/json' -d '$NEW_TRANSACTION' $API_BASE/transactions"
CREATED_TX=$(curl -s -X POST -u $ADMIN_AUTH -H "Content-Type: application/json" -d "$NEW_TRANSACTION" $API_BASE/transactions)
echo "$CREATED_TX" | jq .
CREATED_ID=$(echo "$CREATED_TX" | jq -r '.id')
echo
echo "---"
echo

# Test 5: PUT update transaction
echo "Test 5: PUT update transaction (ID: $CREATED_ID)"
UPDATE_DATA='{
  "status": "pending",
  "description": "Updated via API test"
}'

echo "Command: curl -s -X PUT -u $ADMIN_AUTH -H 'Content-Type: application/json' -d '$UPDATE_DATA' $API_BASE/transactions/$CREATED_ID"
curl -s -X PUT -u $ADMIN_AUTH -H "Content-Type: application/json" -d "$UPDATE_DATA" $API_BASE/transactions/$CREATED_ID | jq .
echo
echo "---"
echo

# Test 6: DELETE transaction
echo "Test 6: DELETE transaction (ID: $CREATED_ID)"
echo "Command: curl -s -X DELETE -u $ADMIN_AUTH $API_BASE/transactions/$CREATED_ID"
curl -s -X DELETE -u $ADMIN_AUTH $API_BASE/transactions/$CREATED_ID | jq .
echo
echo "---"
echo

# Test 7: Invalid credentials
echo "Test 7: Invalid credentials (should return 401)"
echo "Command: curl -s -u $INVALID_AUTH $API_BASE/transactions"
curl -s -u $INVALID_AUTH $API_BASE/transactions | jq .
echo

echo "=== API Testing Complete ==="