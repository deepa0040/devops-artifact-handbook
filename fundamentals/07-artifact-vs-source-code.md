## Artifact vs Source Code — Why You Don't Rebuild at Each Stage

**The core idea:** you build once, then promote the same binary/package through dev → staging → production, instead of re-running `build` at every stage.

### What "artifact" means here
An artifact is the compiled, packaged output of a build step — a Docker image, a JAR, a compiled binary, a bundled frontend, a wheel/tarball. It's immutable once created and usually gets a unique identifier (a Git SHA, a semantic version, an image digest).

### Why not just rebuild from source each time?

**1. You lose the guarantee that what you tested is what you ship**
If staging builds from source and production builds from source again, you're not testing the same thing you deploy — you're testing a *sibling* of it. Dependency resolution can pull a different patch version, a base image can get a new tag, a compiler flag can behave differently on a different day. "It passed in staging" stops meaning anything if production is a fresh build.

**2. Reproducibility and determinism**
Builds aren't always deterministic — timestamps, non-pinned dependencies, flaky network fetches, environment differences (OS patch level, compiler version) can all cause two builds from identical source to differ subtly. An artifact sidesteps this: you're not asking "did the build behave the same way twice," you're just moving a file.

**3. Speed**
Rebuilding (especially compiling, bundling, running codegen) is often the slowest part of a pipeline. Doing it once and reusing the output makes every downstream stage (staging, canary, prod) dramatically faster — deploys become "pull and run" instead of "compile and run."

**4. Auditability and rollback**
A single immutable artifact with a version tag gives you a clean chain of custody: *this exact image, SHA `abc123`, passed tests at 2:14pm, was approved, was deployed to prod at 2:31pm.* Rollback becomes "redeploy the previous artifact," not "hope you can rebuild the exact same thing from a commit six versions back with dependencies that may have since changed upstream."

**5. Supply-chain integrity**
If every stage rebuilds, every stage is a new opportunity for a compromised dependency, mirror, or build agent to inject something different. Building once and cryptographically signing/verifying that single artifact narrows the attack surface considerably.

### The pattern in practice
```
source code → build (once) → artifact (immutable, versioned)
                                   ↓
                    same artifact promoted through:
                    dev → staging → canary → production
```

The only things that should change between environments are *configuration* (env vars, secrets, feature flags) — never the underlying code. That separation (build once, configure per environment) is essentially the "build, release, run" principle from the [twelve-factor app methodology].

---
## Build Once Per Environment

If an organization uses **Build Once Per Environment** instead of **Build Once and Promote the Same Artifact**, there can be several reasons.

### 1. Environment-specific configuration is baked into the artifact

Some applications package environment-specific values during the build.

```text
Dev build     → API_URL=https://dev-api.example.com
QA build      → API_URL=https://qa-api.example.com
Prod build    → API_URL=https://api.example.com
```

If the application is designed this way, each environment may require a separate build.

However, this is usually avoidable. A better design is to inject configuration at runtime.

### 2. Different dependencies are required per environment

An organization may intentionally use different dependencies:

```text
Dev  → debug libraries
QA   → testing/instrumentation libraries
Prod → production-only libraries
```

Therefore, the dependency set itself changes, meaning the artifact cannot simply be promoted unchanged.

### 3. Different build-time feature flags

Some features may be enabled or disabled during compilation:

```text
Dev  → Feature A = ON
QA   → Feature A = ON
Prod → Feature A = OFF
```

If the feature flag is compiled into the application rather than evaluated at runtime, different builds may be required.

### 4. Different compliance or security requirements

Some environments may have different security requirements.

```text
Dev
 └── Less restrictive build

Production
 ├── Hardened build
 ├── Security scanning
 └── Production signing
```

A production artifact might need additional signing, hardening, or packaging steps.

### 5. Different target platforms

Sometimes environments are not technically equivalent.

```text
Dev     → x86
Staging → x86
Prod    → ARM64
```

The binary or container image may need to be built differently.

Similarly, organizations may produce different artifacts for different operating systems or runtime architectures.

### 6. Legacy CI/CD architecture

This is a very common reason.

An old pipeline may simply be designed as:

```text
Dev Pipeline
   ↓
Build
   ↓
Deploy Dev

QA Pipeline
   ↓
Build
   ↓
Deploy QA

Prod Pipeline
   ↓
Build
   ↓
Deploy Prod
```

There may be no technical necessity for rebuilding. It may simply be how the pipeline evolved.

### 7. Environment-specific certificates or secrets are embedded during build

For example:

```text
Dev build  → Dev certificate
QA build   → QA certificate
Prod build → Prod certificate
```

This can sometimes be avoided by injecting secrets or certificates during deployment or application startup rather than embedding them into the artifact.

---

## Build Once vs Build Once Per Environment

### Build Once → Promote

```text
                 BUILD ONCE
                    │
                    ▼
              ┌───────────┐
              │ Artifact  │
              │ v1.5.2    │
              └─────┬─────┘
                    │
          ┌─────────┼─────────┐
          ▼         ▼         ▼
        DEV        QA       STAGING
                              │
                              ▼
                             PROD
```

The same artifact moves through all environments.

This provides an important guarantee:

> **The exact artifact tested in QA is the artifact deployed to production.**

### Build Once Per Environment

```text
Source Code
   │
   ├── Build → Dev Artifact
   │
   ├── Build → QA Artifact
   │
   ├── Build → Staging Artifact
   │
   └── Build → Prod Artifact
```

In this model, you may test one artifact but deploy another artifact.

---

## Important DevOps Perspective

**Build Once → Promote** is generally preferred when all environments are intended to run the **same application version**.

**Build Once Per Environment** can still be valid when the artifact itself intentionally needs to differ between environments.

The key question is:

> **Does the environment difference require the artifact to change, or can the difference be provided through configuration at deployment/runtime?**

If the only differences are:

* API URLs
* Database endpoints
* Credentials
* Environment variables
* Resource names
* Runtime feature flags

then the preferred design is usually:

> **Build once, keep the artifact immutable, and inject environment-specific configuration at deployment/runtime.**

This allows the same tested artifact to be promoted safely across environments.
