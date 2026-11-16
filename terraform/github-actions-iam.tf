# Look up the GitHub Actions OIDC provider already in the account.
data "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

# Trust only this repository's gitops branch.
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        data.aws_iam_openid_connect_provider.github_actions.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:dexter210@78829953/tech-challenge-2@1460084161:ref:refs/heads/gitops"]
    }
  }
}

resource "aws_iam_role" "github_actions_ecr" {
  name               = "tech-challenge-2-github-actions-ecr-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json
}

# Permit authentication and image pushes to this ECR repository.
resource "aws_iam_role_policy" "github_actions_ecr" {
  name = "tech-challenge-2-github-actions-ecr-policy"
  role = aws_iam_role.github_actions_ecr.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ECRLogin"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "PushProjectImages"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = aws_ecr_repository.app.arn
      }
    ]
  })
}

output "github_actions_ecr_role_arn" {
  description = "IAM role ARN for GitHub Actions ECR pushes"
  value       = aws_iam_role.github_actions_ecr.arn
}