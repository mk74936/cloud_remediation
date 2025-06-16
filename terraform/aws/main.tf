provider "aws" {
  region = "us-west-2"
}

resource "aws_config_configuration_recorder" "recorder" {
  name     = "default"
  role_arn = aws_iam_role.config_recorder.arn
}

resource "aws_config_delivery_channel" "channel" {
  name           = "default"
  s3_bucket_name = aws_s3_bucket.config_logs.bucket
  depends_on     = [aws_config_configuration_recorder.recorder]
}

resource "aws_config_configuration_recorder_status" "status" {
  is_enabled = true
  name       = aws_config_configuration_recorder.recorder.name
  depends_on = [aws_config_delivery_channel.channel]
}

resource "aws_s3_bucket" "config_logs" {
  bucket = "cloudguard-config-logs-demo"
  force_destroy = true
}

resource "aws_iam_role" "config_recorder" {
  name = "cloudguard-config-recorder-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "config.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config_policy" {
  role       = aws_iam_role.config_recorder.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_config_config_rule" "s3_public_read" {
  name = "cloudguard-s3-public-read-prohibited"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
  maximum_execution_frequency = "One_Hour"
  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }
}

resource "aws_iam_role" "remediation_lambda_role" {
  name = "cloudguard-remediation-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "remediation_policy" {
  name = "cloudguard-remediation-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:PutBucketAcl",
          "s3:GetBucketAcl",
          "config:PutEvaluations",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_remediation_policy" {
  role       = aws_iam_role.remediation_lambda_role.name
  policy_arn = aws_iam_policy.remediation_policy.arn
}

output "remediation_role_arn" {
  value = aws_iam_role.remediation_lambda_role.arn
}

resource "aws_lambda_function" "revoke_public_access" {
  function_name = "cloudguard-revoke-s3-public-access"
  role          = aws_iam_role.remediation_lambda_role.arn
  handler       = "revoke_public_access_lambda.lambda_handler"
  runtime       = "python3.11"
  timeout       = 10

  filename         = "${path.module}/lambda_packages/revoke_public_access_lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_packages/revoke_public_access_lambda.zip")

  environment {
    variables = {
      ENV = "prod"
    }
  }
}

resource "aws_cloudwatch_event_rule" "config_noncompliance" {
  name        = "cloudguard-config-noncompliance-rule"
  description = "Trigger remediation Lambda on AWS Config noncompliance"

  event_pattern = jsonencode({
    "source": ["aws.config"],
    "detail-type": ["Config Rules Compliance Change"],
    "detail": {
      "newEvaluationResult": {
        "complianceType": ["NON_COMPLIANT"]
      },
      "configRuleName": ["${aws_config_config_rule.s3_public_read.name}"]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.config_noncompliance.name
  target_id = "cloudguard-remediation"
  arn       = aws_lambda_function.revoke_public_access.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.revoke_public_access.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.config_noncompliance.arn
}

