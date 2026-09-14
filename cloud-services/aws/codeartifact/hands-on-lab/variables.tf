variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name used for the CodeBuild project and related resources"
  type        = string
  default     = "codeartifact-handson"
}

variable "domain_name" {
  description = "Name of the CodeArtifact domain"
  type        = string
  default     = "handson-domain"
}

variable "repository_name" {
  description = "Name of the CodeArtifact repository consumers (CodeBuild) will log in to"
  type        = string
  default     = "handson-npm-repo"
}

variable "log_retention_days" {
  description = "CloudWatch log retention for the CodeBuild log group"
  type        = number
  default     = 7
}
