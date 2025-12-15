import unittest
from unittest.mock import MagicMock, patch
import json
import sys
import os

# Add lambda_src to path to import main
sys.path.append(os.path.join(os.path.dirname(__file__), '../lambda_src'))

class TestLambdaHandler(unittest.TestCase):
    def setUp(self):
        # Setup mocks before importing main to avoid boto3 connection issues
        self.boto3_patcher = patch('boto3.resource')
        self.mock_boto3 = self.boto3_patcher.start()
        
        # Setup mock table
        self.mock_table = MagicMock()
        self.mock_dynamodb = MagicMock()
        self.mock_boto3.return_value = self.mock_dynamodb
        self.mock_dynamodb.Table.return_value = self.mock_table
        
        # Import main after mocks are set
        import main
        self.main = main
        # Re-inject the mocked table because main.table is instantiated at module level
        self.main.table = self.mock_table

    def tearDown(self):
        self.boto3_patcher.stop()

    def test_get_visits(self):
        # Mock DynamoDB response
        self.mock_table.get_item.return_value = {
            'Item': {'pk': 'visits', 'count': 5}
        }
        
        event = {'httpMethod': 'GET'}
        response = self.main.lambda_handler(event, None)
        
        self.assertEqual(response['statusCode'], 200)
        body = json.loads(response['body'])
        self.assertEqual(body['count'], 5)

    def test_post_visits(self):
        # Mock update_item response (not strictly needed as code calls get_item after)
        self.mock_table.update_item.return_value = {}
        # Mock subsequent get_item response
        self.mock_table.get_item.return_value = {
            'Item': {'pk': 'visits', 'count': 6}
        }
        
        event = {'httpMethod': 'POST'}
        response = self.main.lambda_handler(event, None)
        
        self.assertEqual(response['statusCode'], 200)
        body = json.loads(response['body'])
        self.assertEqual(body['count'], 6)
        
        # Verify update was called
        self.mock_table.update_item.assert_called_once()

if __name__ == '__main__':
    unittest.main()
