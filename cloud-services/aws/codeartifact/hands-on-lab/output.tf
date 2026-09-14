output "codeartifact_domain_name" {
  description = "Name of the CodeArtifact domain"
  value       = aws_codeartifact_domain.this.domain
}

output "codeartifact_repository_name" {
  description = "Name of the CodeArtifact repository CodeBuild logs in to"
  value       = aws_codeartifact_repository.this.repository
}

output "codeartifact_upstream_repository_name" {
  description = "Name of the upstream repository proxying public npmjs"
  value       = aws_codeartifact_repository.upstream_npm.repository
}

output "codeartifact_npm_endpoint" {
  description = "npm registry endpoint URL for the CodeArtifact repository"
  value       = data.aws_codeartifact_repository_endpoint.npm.repository_endpoint
}

output "codebuild_project_name" {
  description = "Name of the CodeBuild project - run this to trigger the exercise"
  value       = aws_codebuild_project.this.name
}

output "codebuild_iam_role_arn" {
  description = "ARN of the IAM role used by CodeBuild"
  value       = aws_iam_role.codebuild.arn
}
