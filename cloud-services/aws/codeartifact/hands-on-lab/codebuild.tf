resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/${var.project_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_codebuild_project" "this" {
  name          = var.project_name
  description   = "Hands-on exercise: CodeBuild installs an npm package via CodeArtifact and runs a small Node.js script"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = 10

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type            = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "CA_DOMAIN"
      value = aws_codeartifact_domain.this.domain
    }

    environment_variable {
      name  = "CA_DOMAIN_OWNER"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "CA_REPO"
      value = aws_codeartifact_repository.this.repository
    }

    environment_variable {
      name  = "AWS_REGION_ENV"
      value = var.aws_region
    }
  }

  # No external source needed - the buildspec is provided inline and it
  # generates the tiny Node.js app itself during the build.
  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/buildspec.yml")
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild.name
    }
  }
}
