import json
import base64
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import threading
import time
from typing import List, Dict, Any, Optional

class TransactionAPI(BaseHTTPRequestHandler):
    """REST API for MoMo SMS Transaction Management"""
    
    # In-memory storage (in production, use a database)
    transactions = []
    next_id = 1
    
    # Basic Auth credentials (in production, use secure storage)
    VALID_CREDENTIALS = {
        'admin': 'password123',
        'user': 'user123'
    }
    
    def _set_headers(self, status_code: int = 200, content_type: str = 'application/json'):
        """Set HTTP response headers"""
        self.send_response(status_code)
        self.send_header('Content-Type', content_type)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()
    
    def _authenticate(self) -> bool:
        """Validate Basic Authentication"""
        auth_header = self.headers.get('Authorization')
        
        if not auth_header or not auth_header.startswith('Basic '):
            return False
        
        try:
            encoded_credentials = auth_header.split(' ')[1]
            decoded_credentials = base64.b64decode(encoded_credentials).decode('utf-8')
            username, password = decoded_credentials.split(':', 1)
            
            return self.VALID_CREDENTIALS.get(username) == password
        except Exception:
            return False
    
    def _send_json_response(self, data: Any, status_code: int = 200):
        """Send JSON response"""
        self._set_headers(status_code)
        response = json.dumps(data, indent=2)
        self.wfile.write(response.encode('utf-8'))
    
    def _send_error_response(self, message: str, status_code: int = 400):
        """Send error response"""
        self._set_headers(status_code)
        error_response = {'error': message, 'status_code': status_code}
        response = json.dumps(error_response, indent=2)
        self.wfile.write(response.encode('utf-8'))
    
    def _get_request_body(self) -> Optional[Dict[str, Any]]:
        """Parse JSON request body"""
        try:
            content_length = int(self.headers.get('Content-Length', 0))
            if content_length == 0:
                return None
            
            body = self.rfile.read(content_length)
            return json.loads(body.decode('utf-8'))
        except Exception as e:
            return None
    
    def _validate_transaction_data(self, data: Dict[str, Any], is_update: bool = False) -> Optional[str]:
        """Validate transaction data"""
        required_fields = ['transaction_type', 'amount', 'sender', 'receiver', 'reference', 'status']
        
        if not is_update:
            for field in required_fields:
                if field not in data:
                    return f"Missing required field: {field}"
        
        if 'amount' in data:
            try:
                amount = float(data['amount'])
                if amount <= 0:
                    return "Amount must be positive"
            except (ValueError, TypeError):
                return "Amount must be a valid number"
        
        if 'status' in data and data['status'] not in ['pending', 'completed', 'failed']:
            return "Status must be one of: pending, completed, failed"
        
        return None
    
    def do_OPTIONS(self):
        """Handle preflight requests"""
        self._set_headers()
    
    def do_GET(self):
        """Handle GET requests"""
        if not self._authenticate():
            self._send_error_response("Unauthorized", 401)
            return
        
        parsed_url = urlparse(self.path)
        path_parts = parsed_url.path.strip('/').split('/')
        
        if path_parts[0] == 'transactions':
            if len(path_parts) == 1:
                # GET /transactions - list all transactions
                self._send_json_response({
                    'transactions': self.transactions,
                    'total': len(self.transactions)
                })
            elif len(path_parts) == 2:
                # GET /transactions/{id} - get specific transaction
                try:
                    transaction_id = int(path_parts[1])
                    transaction = next((t for t in self.transactions if t['id'] == transaction_id), None)
                    
                    if transaction:
                        self._send_json_response(transaction)
                    else:
                        self._send_error_response("Transaction not found", 404)
                except ValueError:
                    self._send_error_response("Invalid transaction ID", 400)
            else:
                self._send_error_response("Invalid endpoint", 404)
        else:
            self._send_error_response("Endpoint not found", 404)
    
    def do_POST(self):
        """Handle POST requests"""
        if not self._authenticate():
            self._send_error_response("Unauthorized", 401)
            return
        
        parsed_url = urlparse(self.path)
        path_parts = parsed_url.path.strip('/').split('/')
        
        if path_parts[0] == 'transactions' and len(path_parts) == 1:
            # POST /transactions - create new transaction
            data = self._get_request_body()
            
            if not data:
                self._send_error_response("Invalid JSON data", 400)
                return
            
            validation_error = self._validate_transaction_data(data)
            if validation_error:
                self._send_error_response(validation_error, 400)
                return
            
            # Create new transaction
            new_transaction = {
                'id': self.next_id,
                'transaction_type': data['transaction_type'],
                'amount': float(data['amount']),
                'sender': data['sender'],
                'receiver': data['receiver'],
                'timestamp': data.get('timestamp', time.strftime('%Y-%m-%dT%H:%M:%SZ')),
                'reference': data['reference'],
                'status': data['status'],
                'description': data.get('description', '')
            }
            
            self.transactions.append(new_transaction)
            self.next_id += 1
            
            self._send_json_response(new_transaction, 201)
        else:
            self._send_error_response("Invalid endpoint", 404)
    
    def do_PUT(self):
        """Handle PUT requests"""
        if not self._authenticate():
            self._send_error_response("Unauthorized", 401)
            return
        
        parsed_url = urlparse(self.path)
        path_parts = parsed_url.path.strip('/').split('/')
        
        if path_parts[0] == 'transactions' and len(path_parts) == 2:
            # PUT /transactions/{id} - update transaction
            try:
                transaction_id = int(path_parts[1])
                data = self._get_request_body()
                
                if not data:
                    self._send_error_response("Invalid JSON data", 400)
                    return
                
                validation_error = self._validate_transaction_data(data, is_update=True)
                if validation_error:
                    self._send_error_response(validation_error, 400)
                    return
                
                # Find and update transaction
                transaction = next((t for t in self.transactions if t['id'] == transaction_id), None)
                
                if not transaction:
                    self._send_error_response("Transaction not found", 404)
                    return
                
                # Update fields
                for key, value in data.items():
                    if key == 'amount':
                        transaction[key] = float(value)
                    else:
                        transaction[key] = value
                
                self._send_json_response(transaction)
                
            except ValueError:
                self._send_error_response("Invalid transaction ID", 400)
        else:
            self._send_error_response("Invalid endpoint", 404)
    
    def do_DELETE(self):
        """Handle DELETE requests"""
        if not self._authenticate():
            self._send_error_response("Unauthorized", 401)
            return
        
        parsed_url = urlparse(self.path)
        path_parts = parsed_url.path.strip('/').split('/')
        
        if path_parts[0] == 'transactions' and len(path_parts) == 2:
            # DELETE /transactions/{id} - delete transaction
            try:
                transaction_id = int(path_parts[1])
                
                # Find and remove transaction
                transaction = next((t for t in self.transactions if t['id'] == transaction_id), None)
                
                if not transaction:
                    self._send_error_response("Transaction not found", 404)
                    return
                
                self.transactions.remove(transaction)
                self._send_json_response({'message': 'Transaction deleted successfully'})
                
            except ValueError:
                self._send_error_response("Invalid transaction ID", 400)
        else:
            self._send_error_response("Invalid endpoint", 404)

def load_initial_data():
    """Load initial transaction data from JSON file"""
    try:
        with open('data/processed/transactions.json', 'r', encoding='utf-8') as f:
            data = json.load(f)
            TransactionAPI.transactions = data
            TransactionAPI.next_id = max([t['id'] for t in data]) + 1 if data else 1
            print(f"Loaded {len(data)} transactions from JSON file")
    except FileNotFoundError:
        print("No initial data file found. Starting with empty dataset.")
    except Exception as e:
        print(f"Error loading initial data: {e}")

def run_server(port: int = 8000):
    """Run the HTTP server"""
    load_initial_data()
    
    server_address = ('', port)
    httpd = HTTPServer(server_address, TransactionAPI)
    
    print(f"Starting MoMo SMS Transaction API server on port {port}")
    print(f"API Endpoints:")
    print(f"  GET    /transactions     - List all transactions")
    print(f"  GET    /transactions/{{id}} - Get specific transaction")
    print(f"  POST   /transactions     - Create new transaction")
    print(f"  PUT    /transactions/{{id}} - Update transaction")
    print(f"  DELETE /transactions/{{id}} - Delete transaction")
    print(f"\nAuthentication: Basic Auth")
    print(f"  Username: admin, Password: password123")
    print(f"  Username: user, Password: user123")
    print(f"\nPress Ctrl+C to stop the server")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server...")
        httpd.shutdown()

if __name__ == "__main__":
    run_server()