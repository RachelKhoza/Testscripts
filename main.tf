provider "aws" {
  region = "us-east-1"  # Specify your AWS region
}

# IAM Role for Lambda Function
resource "aws_iam_role" "lambda_rds_snapshot_role" {
  name = "lambda_rds_snapshot_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# IAM Policy for Lambda Function (Create & Delete Snapshots)
resource "aws_iam_policy" "lambda_rds_snapshot_policy" {
  name = "lambda_rds_snapshot_policy"

  policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: [
          "rds:CreateDBSnapshot",
          "rds:DeleteDBSnapshot",
          "rds:DescribeDBSnapshots",
          "rds:DescribeDBInstances"
        ],
        Resource: "*"
      },
      {
        Effect: "Allow",
        Action: [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource: "*"
      }
    ]
  })
}

# Attach the IAM policy to the role
resource "aws_iam_role_policy_attachment" "lambda_rds_snapshot_role_attachment" {
  role       = aws_iam_role.lambda_rds_snapshot_role.name
  policy_arn = aws_iam_policy.lambda_rds_snapshot_policy.arn
}

# Lambda Function
resource "aws_lambda_function" "rds_snapshot_lambda" {
  filename         = "lambda_function.zip"  # Path to your ZIP file
  function_name    = "rds-hourly-snapshot"
  role             = aws_iam_role.lambda_rds_snapshot_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"  # Specify your Python version
  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      DB_INSTANCE_ID = "your-db-instance-id"  # Replace with your RDS instance ID
    }
  }
}

# EventBridge Rule to Trigger Lambda Every Hour
resource "aws_cloudwatch_event_rule" "hourly_trigger" {
  name                = "HourlyRDSBackup"
  schedule_expression = "rate(1 hour)"  # Schedule to run every hour
}

# Add Lambda as a Target of the EventBridge Rule
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.hourly_trigger.name
  target_id = "rds_snapshot_lambda"
  arn       = aws_lambda_function.rds_snapshot_lambda.arn
}

# Grant EventBridge Permission to Invoke Lambda
resource "aws_lambda_permission" "allow_cloudwatch_to_invoke" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rds_snapshot_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.hourly_trigger.arn
}