import xml.etree.ElementTree as ET
import json
import re
from datetime import datetime
from typing import List, Dict, Any, Optional

def extract_transaction_details(sms_body: str) -> Dict[str, Any]:
    """
    Extract transaction details from SMS body text using regex patterns.
    
    Args:
        sms_body (str): SMS message body
        
    Returns:
        Dict[str, Any]: Extracted transaction details
    """
    details = {
        'transaction_type': 'Unknown',
        'amount': 0.0,
        'sender': '',
        'receiver': '',
        'reference': '',
        'status': 'completed',
        'description': sms_body[:100]  # First 100 chars as description
    }
    
    # Extract transaction ID/reference
    tx_id_match = re.search(r'TxId:\s*(\d+)', sms_body)
    if tx_id_match:
        details['reference'] = tx_id_match.group(1)
    
    financial_id_match = re.search(r'Financial Transaction Id:\s*(\d+)', sms_body)
    if financial_id_match:
        details['reference'] = financial_id_match.group(1)
    
    # Extract amount (handle different formats)
    amount_patterns = [
        r'(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)\s*RWF',  # 1,000 RWF or 1000.00 RWF
        r'(\d+)\s*RWF',  # Simple 1000 RWF
    ]
    
    for pattern in amount_patterns:
        amount_match = re.search(pattern, sms_body)
        if amount_match:
            amount_str = amount_match.group(1).replace(',', '')
            details['amount'] = float(amount_str)
            break
    
    # Determine transaction type and extract names
    if 'You have received' in sms_body:
        details['transaction_type'] = 'Money Received'
        # Extract sender name
        sender_match = re.search(r'from\s+([^(]+)\s*\(', sms_body)
        if sender_match:
            details['sender'] = sender_match.group(1).strip()
        details['receiver'] = 'Account Holder'
        
    elif 'Your payment of' in sms_body:
        details['transaction_type'] = 'Payment'
        # Extract receiver name
        receiver_match = re.search(r'to\s+([^0-9]+?)\s+\d+', sms_body)
        if receiver_match:
            details['receiver'] = receiver_match.group(1).strip()
        details['sender'] = 'Account Holder'
        
    elif 'transferred to' in sms_body:
        details['transaction_type'] = 'Money Transfer'
        # Extract receiver name and phone
        transfer_match = re.search(r'transferred to\s+([^(]+)\s*\((\d+)\)', sms_body)
        if transfer_match:
            details['receiver'] = transfer_match.group(1).strip()
        details['sender'] = 'Account Holder'
        
    elif 'bank deposit' in sms_body.lower():
        details['transaction_type'] = 'Bank Deposit'
        details['sender'] = 'Bank'
        details['receiver'] = 'Account Holder'
        
    elif 'withdrawn' in sms_body:
        details['transaction_type'] = 'Cash Withdrawal'
        details['sender'] = 'Account Holder'
        # Extract agent info
        agent_match = re.search(r'Agent\s+([^(]+)', sms_body)
        if agent_match:
            details['receiver'] = agent_match.group(1).strip()
        
    elif 'airtime' in sms_body.lower() or 'cash power' in sms_body.lower():
        details['transaction_type'] = 'Utility Payment'
        details['sender'] = 'Account Holder'
        if 'airtime' in sms_body.lower():
            details['receiver'] = 'Airtime Provider'
        else:
            details['receiver'] = 'Utility Provider'
            
    elif 'one-time password' in sms_body.lower():
        details['transaction_type'] = 'OTP'
        details['amount'] = 0.0
        details['sender'] = 'MTN MoMo'
        details['receiver'] = 'Account Holder'
    
    return details

def parse_xml_to_json(xml_file_path: str) -> List[Dict[str, Any]]:
    """
    Parse XML file containing SMS records and convert to JSON objects.
    
    Args:
        xml_file_path (str): Path to the XML file
        
    Returns:
        List[Dict[str, Any]]: List of transaction dictionaries
    """
    transactions = []
    
    try:
        tree = ET.parse(xml_file_path)
        root = tree.getroot()
        
        transaction_id = 1
        
        # Parse SMS elements
        for sms in root.findall('sms'):
            body = sms.get('body', '')
            date = sms.get('date', '')
            readable_date = sms.get('readable_date', '')
            
            # Skip OTP messages for transaction processing
            if 'one-time password' in body.lower():
                continue
                
            # Extract transaction details from SMS body
            details = extract_transaction_details(body)
            
            # Convert timestamp
            timestamp = readable_date if readable_date else date
            try:
                if date.isdigit():
                    # Convert Unix timestamp to readable format
                    dt = datetime.fromtimestamp(int(date) / 1000)
                    timestamp = dt.strftime('%Y-%m-%dT%H:%M:%SZ')
            except:
                timestamp = readable_date or date
            
            transaction = {
                'id': transaction_id,
                'transaction_type': details['transaction_type'],
                'amount': details['amount'],
                'sender': details['sender'],
                'receiver': details['receiver'],
                'timestamp': timestamp,
                'reference': details['reference'] or f"SMS_{transaction_id}",
                'status': details['status'],
                'description': details['description']
            }
            
            transactions.append(transaction)
            transaction_id += 1
            
    except ET.ParseError as e:
        print(f"Error parsing XML: {e}")
        return []
    except FileNotFoundError:
        print(f"XML file not found: {xml_file_path}")
        return []
    except Exception as e:
        print(f"Unexpected error: {e}")
        return []
    
    return transactions

def save_json_data(transactions: List[Dict[str, Any]], output_file: str) -> bool:
    """
    Save transactions data to JSON file.
    
    Args:
        transactions (List[Dict[str, Any]]): List of transactions
        output_file (str): Output JSON file path
        
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(transactions, f, indent=2, ensure_ascii=False)
        return True
    except Exception as e:
        print(f"Error saving JSON: {e}")
        return False

if __name__ == "__main__":
    xml_file = "modified_sms_v2.xml"
    json_file = "data/processed/transactions.json"
    
    print("Parsing XML file...")
    transactions = parse_xml_to_json(xml_file)
    
    if transactions:
        print(f"Successfully parsed {len(transactions)} transactions")
        
        if save_json_data(transactions, json_file):
            print(f"Data saved to {json_file}")
        else:
            print("Failed to save JSON data")
            
        print("\nSample transaction:")
        print(json.dumps(transactions[0], indent=2))
    else:
        print("No transactions parsed")