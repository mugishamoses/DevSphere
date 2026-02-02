"""
Data Structures & Algorithms Implementation for Transaction Search
Comparing Linear Search vs Dictionary Lookup efficiency
"""

import time
import json
from typing import List, Dict, Any, Optional

class TransactionSearcher:
    """
    Implementation of different search algorithms for transaction data
    """
    
    def __init__(self, transactions: List[Dict[str, Any]]):
        """
        Initialize with transaction data
        
        Args:
            transactions: List of transaction dictionaries
        """
        self.transactions_list = transactions
        self.transactions_dict = {t['id']: t for t in transactions}
        
    def linear_search(self, transaction_id: int) -> Optional[Dict[str, Any]]:
        """
        Linear search implementation - O(n) time complexity
        Scans through the list sequentially to find transaction by ID
        
        Args:
            transaction_id: ID of transaction to find
            
        Returns:
            Transaction dictionary if found, None otherwise
        """
        for transaction in self.transactions_list:
            if transaction['id'] == transaction_id:
                return transaction
        return None
    
    def dictionary_lookup(self, transaction_id: int) -> Optional[Dict[str, Any]]:
        """
        Dictionary lookup implementation - O(1) average time complexity
        Uses hash table for direct key-based access
        
        Args:
            transaction_id: ID of transaction to find
            
        Returns:
            Transaction dictionary if found, None otherwise
        """
        return self.transactions_dict.get(transaction_id)
    
    def benchmark_search_methods(self, search_ids: List[int], iterations: int = 1000) -> Dict[str, float]:
        """
        Benchmark both search methods and compare performance
        
        Args:
            search_ids: List of transaction IDs to search for
            iterations: Number of times to repeat the search for accurate timing
            
        Returns:
            Dictionary with timing results for both methods
        """
        results = {}
        
        # Benchmark Linear Search
        start_time = time.perf_counter()
        for _ in range(iterations):
            for search_id in search_ids:
                self.linear_search(search_id)
        linear_time = time.perf_counter() - start_time
        
        # Benchmark Dictionary Lookup
        start_time = time.perf_counter()
        for _ in range(iterations):
            for search_id in search_ids:
                self.dictionary_lookup(search_id)
        dict_time = time.perf_counter() - start_time
        
        results = {
            'linear_search_time': linear_time,
            'dictionary_lookup_time': dict_time,
            'speedup_factor': linear_time / dict_time if dict_time > 0 else 0,
            'searches_performed': len(search_ids) * iterations
        }
        
        return results
    
    def demonstrate_search_efficiency(self) -> None:
        """
        Demonstrate the efficiency difference between search methods
        """
        print("=== Transaction Search Algorithm Comparison ===\n")
        
        # Test with different transaction IDs
        test_ids = [1, 5, 10, 15, 20, 25] if len(self.transactions_list) >= 25 else [t['id'] for t in self.transactions_list[:6]]
        
        print(f"Dataset size: {len(self.transactions_list)} transactions")
        print(f"Testing with IDs: {test_ids}")
        print(f"Total searches per method: {len(test_ids) * 1000}")
        print()
        
        # Run benchmark
        results = self.benchmark_search_methods(test_ids, iterations=1000)
        
        # Display results
        print("Performance Results:")
        print(f"Linear Search Time:     {results['linear_search_time']:.6f} seconds")
        print(f"Dictionary Lookup Time: {results['dictionary_lookup_time']:.6f} seconds")
        print(f"Speedup Factor:         {results['speedup_factor']:.2f}x faster")
        print()
        
        # Verify both methods return same results
        print("Verification (both methods return same results):")
        for test_id in test_ids[:3]:  # Test first 3 IDs
            linear_result = self.linear_search(test_id)
            dict_result = self.dictionary_lookup(test_id)
            
            if linear_result and dict_result:
                print(f"ID {test_id}: ✓ Both found - {linear_result['transaction_type']} of {linear_result['amount']} RWF")
            elif not linear_result and not dict_result:
                print(f"ID {test_id}: ✓ Both returned None (not found)")
            else:
                print(f"ID {test_id}: ✗ Results differ!")
        
        print()
        self._explain_efficiency()
    
    def _explain_efficiency(self) -> None:
        """
        Explain why dictionary lookup is more efficient
        """
        print("=== Efficiency Analysis ===")
        print()
        print("Linear Search (O(n) time complexity):")
        print("- Scans through each transaction sequentially")
        print("- In worst case, checks every transaction in the list")
        print("- Performance degrades linearly with dataset size")
        print("- Average case: checks n/2 transactions")
        print()
        print("Dictionary Lookup (O(1) average time complexity):")
        print("- Uses hash table for direct key-based access")
        print("- Calculates hash of the key to find location directly")
        print("- Performance remains constant regardless of dataset size")
        print("- No need to scan through other transactions")
        print()
        print("Alternative Data Structures for Better Performance:")
        print("1. Binary Search Tree (O(log n)) - for sorted data")
        print("2. Hash Table with chaining - handles collisions better")
        print("3. Trie structure - for prefix-based searches")
        print("4. B-Tree - for database-like operations")
        print("5. Bloom Filter - for membership testing with space efficiency")

def load_transaction_data(file_path: str = "data/processed/transactions.json") -> List[Dict[str, Any]]:
    """
    Load transaction data from JSON file
    
    Args:
        file_path: Path to JSON file containing transactions
        
    Returns:
        List of transaction dictionaries
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"File not found: {file_path}")
        return []
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON: {e}")
        return []

def main():
    """
    Main function to demonstrate DSA implementation
    """
    # Load transaction data
    transactions = load_transaction_data()
    
    if not transactions:
        print("No transaction data available for testing")
        return
    
    # Ensure we have at least 20 records as required
    if len(transactions) < 20:
        print(f"Warning: Only {len(transactions)} transactions available. Assignment requires at least 20.")
    
    # Create searcher and run demonstration
    searcher = TransactionSearcher(transactions)
    searcher.demonstrate_search_efficiency()

if __name__ == "__main__":
    main()