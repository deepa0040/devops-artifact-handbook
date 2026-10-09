# CodeArtifact + CodeBuild Hands-On Exercise

This Terraform stack builds everything needed to practice **AWS CodeArtifact**
integrated with **AWS CodeBuild**:

- A CodeArtifact **domain**
- An **upstream repository** that proxies public npmjs.org
- A **repository** that CodeBuild authenticates against
- An **IAM role/policy** giving CodeBuild exactly the permissions it needs
  (`codeartifact:GetAuthorizationToken`, `ReadFromRepository`,
  `GetRepositoryEndpoint`, `sts:GetServiceBearerToken`)
- A **CodeBuild project** with `NO_SOURCE` — the buildspec is inline and
  self-contained, so there's no repo or S3 bucket to set up. During the
  build it:
  1. Runs `aws codeartifact login --tool npm ...` to point npm at your
     CodeArtifact repo
  2. Creates a tiny `package.json`
  3. Runs `npm install` (pulled through CodeArtifact -> upstream npmjs)

## Files

| File            | Purpose                                      |
|-----------------|-----------------------------------------------|
| `provider.tf`   | AWS provider + Terraform version constraints  |
| `variables.tf`  | Configurable inputs (region, names, etc.)     |
| `codeartifact.tf` | Domain + upstream + repository            |
| `iam.tf`        | CodeBuild service role and IAM policy         |
| `codebuild.tf`  | CodeBuild project + CloudWatch log group      |
| `buildspec.yml` | Inline buildspec run inside the build         |
| `outputs.tf`    | Useful values after apply                     |

## Usage

```bash
terraform init
terraform plan
terraform apply
```

Then trigger the build (there's no source push needed since it's `NO_SOURCE`):

```bash
aws codebuild start-build --project-name codeartifact-handson
```

Watch it run:

```bash
aws codebuild list-builds-for-project --project-name codeartifact-handson
# grab the build id from the output above, then:
aws codebuild batch-get-builds --ids <BUILD_ID>
```

Or just watch the logs in CloudWatch under:
`/aws/codebuild/codeartifact-handson`


## Cleanup

```bash
terraform destroy
```

## Notes / assumptions

- Default region is `us-east-1` — change `aws_region` in `variables.tf` or
  pass `-var="aws_region=ap-south-1"` at apply time.
- Uses CodeBuild's standard Amazon Linux 2 image with the Node.js 18
  runtime selected inside the buildspec.
- The AWS credentials Terraform runs with need permissions to create
  CodeArtifact, IAM, CodeBuild, and CloudWatch Logs resources.