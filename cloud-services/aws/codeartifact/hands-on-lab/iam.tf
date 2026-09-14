# -----------------------------------------------------------------------------
# IAM Role that CodeBuild assumes
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild" {
  name               = "${var.project_name}-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}

# -----------------------------------------------------------------------------
# Permissions:
#  - Write build logs to CloudWatch
#  - Authenticate against CodeArtifact and read/install packages
#  - Get the STS service bearer token CodeArtifact login needs
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "codebuild_permissions" {
  statement {
    sid    = "Logs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "${aws_cloudwatch_log_group.codebuild.arn}:*",
    ]
  }

  statement {
    sid    = "CodeArtifactAuth"
    effect = "Allow"
    actions = [
      "codeartifact:GetAuthorizationToken",
    ]
    resources = [
      aws_codeartifact_domain.this.arn,
    ]
  }

  statement {
    sid    = "CodeArtifactRead"
    effect = "Allow"
    actions = [
      "codeartifact:GetRepositoryEndpoint",
      "codeartifact:ReadFromRepository",
    ]
    resources = [
      aws_codeartifact_repository.this.arn,
      aws_codeartifact_repository.upstream_npm.arn,
    ]
  }

  statement {
    sid    = "StsBearerToken"
    effect = "Allow"
    actions = [
      "sts:GetServiceBearerToken",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "sts:AWSServiceName"
      values   = ["codeartifact.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "codebuild" {
  name   = "${var.project_name}-codebuild-policy"
  role   = aws_iam_role.codebuild.id
  policy = data.aws_iam_policy_document.codebuild_permissions.json
}
