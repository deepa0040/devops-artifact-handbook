# -----------------------------------------------------------------------------
# CodeArtifact Domain
# -----------------------------------------------------------------------------
resource "aws_codeartifact_domain" "this" {
  domain = var.domain_name
}

# -----------------------------------------------------------------------------
# Upstream repository that proxies the public npmjs.org registry.
# This is what actually lets "npm install lodash" pull packages from the
# internet the first time; CodeArtifact then caches them.
# -----------------------------------------------------------------------------
resource "aws_codeartifact_repository" "upstream_npm" {
  repository = "${var.repository_name}-upstream"
  domain     = aws_codeartifact_domain.this.domain

  external_connections {
    external_connection_name = "public:npmjs"
  }
}

# -----------------------------------------------------------------------------
# The repository CodeBuild will actually log in to and install packages from.
# It points at the upstream repo above so requests fall through to npmjs.
# -----------------------------------------------------------------------------
resource "aws_codeartifact_repository" "this" {
  repository = var.repository_name
  domain     = aws_codeartifact_domain.this.domain

  upstream {
    repository_name = aws_codeartifact_repository.upstream_npm.repository
  }
}

# -----------------------------------------------------------------------------
# Handy output: the npm endpoint URL for this repository (useful if you ever
# want to run `npm config set registry ...` from your own machine too).
# -----------------------------------------------------------------------------
data "aws_codeartifact_repository_endpoint" "npm" {
  domain     = aws_codeartifact_domain.this.domain
  repository = aws_codeartifact_repository.this.repository
  format     = "npm"

  depends_on = [aws_codeartifact_repository.this]
}
