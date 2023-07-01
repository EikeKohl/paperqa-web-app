data "aws_secretsmanager_secret" "openai" {
  name = "paperqa_openai_api_key"
}

resource "aws_iam_policy" "paperqa_policy" {
  name   = "paperqa_policy"
  policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Sid: "Specific",
        Effect: "Allow",
        Action: [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "s3:GetObject",
          "s3:ListBucket",
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
        ],
        Resource: [
          aws_ecr_repository.paperqa.arn,
          "${aws_cloudwatch_log_group.paperqa_log_group.arn}:*",
          data.aws_secretsmanager_secret.openai.arn
        ]
      },
      {
        Sid: "General",
        Effect: "Allow",
        Action: [
          "ecr:GetAuthorizationToken"
        ],
        Resource: "*"
      },
      {
        Sid: "CognitoAccess",
        Effect: "Allow",
        Action: [
          "cognito-idp:AdminInitiateAuth",
          "cognito-idp:AdminRespondToAuthChallenge",
          "cognito-idp:DescribeUserPoolClient",
          "cognito-idp:GetUser"
        ],
        Resource: [
          aws_cognito_user_pool.paperqa_user_pool.arn,
          "${aws_cognito_user_pool.paperqa_user_pool.arn}/client/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "paperqa_role" {
  name                = "paperqa_role"
  assume_role_policy  = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Sid: "",
        Effect: "Allow",
        Principal: {
          Service: "ecs-tasks.amazonaws.com"
        },
        Action: "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = [aws_iam_policy.paperqa_policy.arn]
}


