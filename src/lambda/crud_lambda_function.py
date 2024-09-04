"""
Serverless CRUD lambda function.
"""

import json
import os

from typing import Any

import boto3

client = boto3.client("dynamodb")
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["DYNAMODB_TABLE"])


def get_response(status_code: int, body: Any) -> dict[str, Any]:
    """
    Get response object.

    Args:
        status_code: Response status code.
        body: Response body.

    Returns:
        Response object containing status code, body, and headers.

    """
    return {
        "statusCode": status_code,
        "body": json.dumps(body),
        "headers": {
            "Content-Type": "application/json",
        },
    }


def get_item_id(event: dict[str, Any]) -> str:
    """
    Extract 'id' from path parameters in event object.

    Args:
        event: Event object.

    Returns:
        'id' value from path parameters.

    """
    return event["pathParameters"]["id"]


def get_all_items() -> list:
    """
    Retrieve all items from DynamoDB table.

    Returns:
        List of all items with their details.

    """
    body = table.scan()
    items = body["Items"]
    response_body = [
        {
            "id": item["id"],
            "name": item["name"],
        }
        for item in items
    ]

    return response_body


def get_item(event: dict[str, Any]) -> dict[str, Any]:
    """
    Retrieve single item from DynamoDB table using 'id'.

    Args:
        event: Event object.

    Returns:
        Details of single item.

    """
    body = table.get_item(Key={"id": get_item_id(event)})
    body = body["Item"]
    response_body = {
        "id": body["id"],
        "name": body["name"],
    }

    return response_body


def create_item(event: dict[str, Any]) -> str:
    """
    Create new item in DynamoDB table.

    Args:
        event: Event object containing item details.

    Returns:
        Success message indicating item has been created.

    """
    request_json = json.loads(event["body"])
    table.put_item(
        Item={
            "id": request_json["id"],
            "name": request_json["name"],
        }
    )

    return f"Put item {request_json['id']}"


def update_item(event: dict[str, Any]) -> str:
    """
    Update existing item in DynamoDB table.

    Args:
        event: Event object containing path parameters and item details.

    Returns:
        Success message indicating item has been updated.

    Raises:
        KeyError: If no required fields are provided.

    """
    # Extract item ID from path parameters
    item_id = get_item_id(event)

    # Parse  request body to get updated attributes
    request_json = json.loads(event["body"])

    # Prepare update expression and attribute values
    update_expression = "SET "
    expression_attribute_values = {}
    expression_attribute_names = {}

    # Dynamically build update expression based on provided fields
    update_fields = []
    for key, value in request_json.items():
        # Assume 'id' is primary key and should not be updated
        if key != "id":
            update_fields.append(f"#{key} = :{key}")
            expression_attribute_values[f":{key}"] = value
            expression_attribute_names[f"#{key}"] = key

    # Throw error is no fields are provided
    if not update_fields:
        raise KeyError("No valid fields provided for update.")

    # Generate expression string
    update_expression += ", ".join(update_fields)

    # Update table item
    table.update_item(
        Key={"id": item_id},
        UpdateExpression=update_expression,
        ExpressionAttributeValues=expression_attribute_values,
        ExpressionAttributeNames=expression_attribute_names,
        ReturnValues="UPDATED_NEW",
    )

    return f"Updated item {item_id}"


def delete_item(event: dict[str, Any]) -> str:
    """
    Delete single item from DynamoDB table.

    Args:
        event: Event object containing item ID.

    Returns:
        Success message indicating item has been deleted.

    """
    item_id = get_item_id(event)
    table.delete_item(Key={"id": item_id})

    return f"Deleted item {item_id}"


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """
    Main entry point for Lambda function.

    Args:
        event: Event object.
        context: Context object (not used in this function).

    Returns:
        Response object for Lambda function.

    """
    body = {}
    status_code = 200
    route_key = event["routeKey"]
    base_path = "/items"

    try:
        if route_key == f"DELETE {base_path}/{{id}}":
            body = delete_item(event)
        elif route_key == f"GET {base_path}/{{id}}":
            body = get_item(event)
        elif route_key == f"GET {base_path}":
            body = get_all_items()
        elif route_key == f"PUT {base_path}":
            body = create_item(event)
        elif route_key == f"PUT {base_path}/{{id}}":
            body = update_item(event)
    except KeyError:
        status_code = 400
        body = f"Unsupported route: {route_key}"

    return get_response(status_code, body)
