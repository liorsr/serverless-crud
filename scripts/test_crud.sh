# Note: These are not meant to run as a single script, but one at a time, as required.

# Create item
curl -X "PUT" -H "Content-Type: application/json" -d "{\"id\": \"1\", \"name\": \"item_1\"}" https://<api_id>.execute-api.us-west-2.amazonaws.com/items

# Get list of items
curl https://<api_id>.execute-api.us-west-2.amazonaws.com/items

# Get item
curl https://<api_id>.execute-api.us-west-2.amazonaws.com/items/1

# Update item
curl -X "PUT" -H "Content-Type: application/json" -d "{\"id\": \"1\", \"name\": \"updated_item_1\"}" https://<api_id>.execute-api.us-west-2.amazonaws.com/items/1

# Delete item
curl -X "DELETE" https://<api_id>.execute-api.us-west-2.amazonaws.com/items/1
