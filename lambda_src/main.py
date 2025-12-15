import boto3
import json
from decimal import Decimal

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("cv-visit-counter")

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return int(obj)
        return super(DecimalEncoder, self).default(obj)

def lambda_handler(event, context):
    method = event.get("httpMethod")

    if method == "GET":
        resp = table.get_item(Key={"pk": "visits"})
        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*" # CORS for frontend
            },
            "body": json.dumps(resp.get("Item", {}), cls=DecimalEncoder)
        }

    if method == "POST":
        table.update_item(
            Key={"pk": "visits"},
            UpdateExpression="SET #c = #c + :inc",
            ExpressionAttributeNames={"#c": "count"},
            ExpressionAttributeValues={":inc": 1},
            ReturnValues="UPDATED_NEW"
        )
        resp = table.get_item(Key={"pk": "visits"})
        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*" 
            },
            "body": json.dumps(resp["Item"], cls=DecimalEncoder)
        }

    return {
        "statusCode": 400,
        "body": json.dumps({"error": "Unsupported method"})
    }
