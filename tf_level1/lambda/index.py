import json


def lambda_handler(event, context):
  """Basic AWS Lambda handler function in Python."""
  print("Event received:", json.dumps(event))

  return {
      "statusCode": 200,
      "body": json.dumps({
          "message": "Hello from Lambda created via Terraform!",
          "input": event,
      }),
  }