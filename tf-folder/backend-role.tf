# IAM Role for GitHub Actions to interact with Terraform State in S3 and DynamoDB
resource "aws_iam_role" "github_action_role" {
  name = "github-actions-terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sts.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for S3 and DynamoDB access
resource "aws_iam_policy" "github_actions_terraform_policy" {
  name        = "GitHubActionsTerraformPolicy"
  description = "Policy to allow GitHub Actions to manage Terraform State"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::tf-remote-s3-bucket-ecs-fargate-aws",
          "arn:aws:s3:::tf-remote-s3-bucket-ecs-fargate-aws/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan"
        ]
        Resource = "arn:aws:dynamodb:us-east-1:*:table/tf-s3-app-lock-terraform"
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "github_actions_terraform_policy_attachment" {
  role       = aws_iam_role.github_action_role.name
  policy_arn = aws_iam_policy.github_actions_terraform_policy.arn
}
