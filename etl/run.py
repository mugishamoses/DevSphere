"""
ETL Pipeline Runner for MoMo SMS Transaction Data
Orchestrates the complete Extract, Transform, Load process
"""

import os
import sys
import json
from pathlib import Path

# Add project root to path for imports
project_root = Path(__file__).parent.parent
sys.path.append(str(project_root))

from etl.parse_xml import parse_xml_to_json, save_json_data

def run_etl_pipeline():
    """
    Run the complete ETL pipeline:
    1. Extract: Parse XML SMS data
    2. Transform: Clean and normalize data
    3. Load: Save to JSON format
    """
    print("=== MoMo SMS Data ETL Pipeline ===\n")
    
    # File paths
    xml_file = "modified_sms_v2.xml"
    json_output = "data/processed/transactions.json"
    
    # Ensure output directory exists
    os.makedirs(os.path.dirname(json_output), exist_ok=True)
    
    # Step 1: Extract - Parse XML
    print("Step 1: Extracting data from XML...")
    print(f"Reading: {xml_file}")
    
    transactions = parse_xml_to_json(xml_file)
    
    if not transactions:
        print("❌ No transactions extracted. Check XML file format.")
        return False
    
    print(f"✅ Extracted {len(transactions)} transactions")
    
    # Step 2: Transform - Data is already cleaned during parsing
    print("\nStep 2: Transforming data...")
    print("✅ Data transformation completed during parsing")
    
    # Display sample transaction
    if transactions:
        print("\nSample transaction:")
        sample = transactions[0]
        for key, value in sample.items():
            print(f"  {key}: {value}")
    
    # Step 3: Load - Save to JSON
    print(f"\nStep 3: Loading data to {json_output}...")
    
    if save_json_data(transactions, json_output):
        print(f"✅ Data successfully saved to {json_output}")
        
        # Display summary statistics
        print(f"\n=== ETL Summary ===")
        print(f"Total transactions processed: {len(transactions)}")
        
        # Transaction type distribution
        type_counts = {}
        total_amount = 0
        
        for tx in transactions:
            tx_type = tx['transaction_type']
            type_counts[tx_type] = type_counts.get(tx_type, 0) + 1
            total_amount += tx['amount']
        
        print(f"Total transaction value: {total_amount:,.2f} RWF")
        print(f"Transaction types:")
        for tx_type, count in sorted(type_counts.items()):
            print(f"  {tx_type}: {count}")
        
        return True
    else:
        print("❌ Failed to save data")
        return False

def main():
    """Main function"""
    success = run_etl_pipeline()
    
    if success:
        print(f"\n🎉 ETL Pipeline completed successfully!")
        print(f"Next steps:")
        print(f"1. Run API server: python api/app.py")
        print(f"2. Test DSA algorithms: python dsa/search_algorithms.py")
    else:
        print(f"\n❌ ETL Pipeline failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()