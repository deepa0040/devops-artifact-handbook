# Topic 1: What is an Artifact

## Definition
**Artifact** = any output of a build or packaging process that is stored, versioned, and intended to be consumed by a later stage or system.

## What Counts as an Artifact
- **Compiled outputs**: JAR, WAR, .exe, .dll, binaries
- **Packaged code**: npm package, pip wheel, NuGet package, Debian/RPM package
- **Container images**: Docker/OCI images
- **Infrastructure definitions**: Helm charts, Terraform modules (these are "outputs" of authoring, not compilation, but still versioned/stored the same way)
- **Generated data**: ML model files, test reports, documentation bundles, SBOMs

So yes — in every case, an artifact is produced by some process (compile, package, train, generate) rather than being the original source.

## What's NOT an Artifact
- **Source code itself** — the `.java`, `.py`, `.tf` files in your git repo are inputs, not artifacts. Git repos and artifact repos are deliberately separate systems.
- **Raw configuration/secrets** — these are managed by config/secrets tools (Vault, Parameter Store), not artifact repos.
- **Runtime state** — a running container instance, a live database — these are not artifacts; the *image* that spawned them is.

## The Three-Layer Mental Model
Think of software in three layers, and an artifact is the middle one:

| Layer | Example | Is it an artifact? |
|---|---|---|
| **Source** | `.java`, `.py`, `.tf` files in a git repo | ❌ No — this is input |
| **Artifact** | `.jar`, Docker image, `.whl`, Helm chart | ✅ Yes — this is packaged output |
| **Runtime** | A running container, a live pod, an active process | ❌ No — this is the artifact *executing* |

Source gets compiled/packaged into an artifact. The artifact gets deployed/run to produce a runtime instance. If the runtime crashes, you don't fix the runtime — you fix the source, rebuild the artifact, and redeploy.

## Key Properties Every Artifact Should Have
- **Versioned** — has a unique identifier (SemVer, git-SHA, build number) so you can trace exactly what's deployed
- **Immutable** — once published, it never changes; a new version is published instead of editing in place
- **Stored centrally** — lives in a repository (Artifactory, ECR, npm registry, etc.), not just on a developer's laptop
- **Traceable** — has metadata linking it back to the exact source commit, build job, and dependencies that produced it
- **Consumable** — something else (a deploy pipeline, another build, a runtime) can pull and use it without needing the original source

## Use Case Categories (Why Artifacts Get Stored in a Repo)

| # | Use Case | Why it's stored | Example |
|---|---|---|---|
| 1 | **Build-once, deploy-many** | Same artifact promoted unchanged across dev → staging → prod | JAR, WAR, Docker image |
| 2 | **Dependency caching/proxying** | Avoid re-fetching public packages every build; protect against upstream outages or removals | npm packages via a remote/proxy repo, PyPI mirror, Maven Central proxy |
| 3 | **Internal package sharing** | One team publishes reusable code; other teams/projects consume it — not caching, it's the *origin* | Internal npm package (`@company/logger`), internal Python wheel, shared Maven library |
| 4 | **Rollback & audit trail** | Keep old versions available so you can revert instantly without rebuilding, and prove what was deployed when | Old Docker image tags, previous JAR versions kept for N days |
| 5 | **Cross-team/cross-pipeline handoff** | One team's output is another team's input, and they don't share a build pipeline | ML model file trained by data science → consumed by an inference service pipeline |
| 6 | **End-user distribution** | Artifact isn't deployed to your infra — it's shipped to external users | Mobile app builds (`.apk`, `.ipa`), downloadable installers, CLI binaries via Homebrew/GitHub Releases |

### Quick self-test for any artifact
Ask: **"Is this artifact being produced here, or just relayed/cached from elsewhere?"**
- Produced here → local repo → build-once-deploy-many or internal-sharing pattern
- Relayed from elsewhere → remote/proxy repo → caching pattern
- Both combined for consumers → virtual/aggregated repo

## Common Misconceptions (Interview-Relevant)
- ❌ *"An artifact is just a Docker image"* — Docker images are one type, not the definition. Anything packaged and versioned qualifies.
- ❌ *"Config files and secrets are artifacts"* — No, those live in separate systems (Vault, Parameter Store, ConfigMaps) precisely because they change per-environment, which breaks immutability.
- ❌ *"Terraform state files are artifacts"* — State files are runtime/tracking data, not build outputs. Terraform *modules* (the reusable IaC code packages) are closer to artifacts; the state file is more like a database.
- ❌ *"You rebuild the artifact for every environment"* — Bad practice. The same artifact should be promoted through dev → staging → prod unchanged; only its *configuration* changes per environment.

```
main branch → build ONCE → JAR-v1.2.3 (single immutable file)
                              │
                              ├──► deploy to Dev       (using dev config)
                              ├──► deploy to Staging   (using staging config)
                              └──► deploy to Prod      (using prod config)
```


An artifact is any versioned, stored output of a build or packaging process that downstream systems or people consume — it is not the source, and it is not a running instance. It sits in between: the packaged, reusable thing.