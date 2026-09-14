# Build Once vs. Rebuild Per Environment

## The Textbook Principle
**"Build once, promote many"** — the same artifact (JAR, Docker image, etc.) is built a single time, then promoted unchanged through dev → staging → prod. Only external **configuration** changes per environment; the binary itself never changes.


### Why it matters
This gives you the core guarantee: **"what you test is what you ship."** If QA validates `myapp:1.2.3` in staging, the exact same bytes run in prod. No "should behave the same way" — it's proven identical.

---

## The Industry Reality
Many real-world teams **do** rebuild per environment. This isn't automatically wrong — it depends on *why*.

### Legitimate reasons to rebuild per environment

| Reason | Explanation |
|---|---|
| **Different build targets, not just config** | Mobile apps often must rebuild per environment — a dev `.apk` may point to a different API endpoint compiled into the binary, use different signing certs, or include debug symbols stripped in prod. This is a genuinely different build, not just config. |
| **Environment-specific compilation flags** | Native/compiled languages (C++, Rust) may build with different optimization flags per environment (debug vs release) — different binaries by design. |
| **Rebuild-from-same-commit promotion** | Some teams rebuild at each stage from the *same immutable git commit/tag* rather than reusing one binary. This gives similar traceability to true promotion, even though it's technically a different file each time. A middle-ground practice. |
| **Compliance/air-gapped environments** | Regulated industries sometimes require rebuilding within an isolated network per environment, as part of the security/audit attestation process. |

### Where rebuild-per-environment becomes a real anti-pattern
The problem isn't rebuilding itself — it's when:
- The same source/commit produces **different behavior** across environments due to non-reproducible builds (floating dependency versions, `latest` tags, unpinned base images)
- Nobody can **prove** dev/staging/prod ran identical code — no shared artifact ID or checksum ties them together
- Config gets **baked in at compile time** instead of injected at runtime, forcing a rebuild for what should have been a simple config change

---

## The Honest Middle Ground

| Context | Common practice |
|---|---|
| Backend services (JAR, Docker-based) | Build-once-promote-many is genuinely achievable and dominant — the "textbook" case |
| Mobile apps, native binaries | Rebuilding per environment is common and often unavoidable |
| What actually separates good vs. bad practice | Not "did you rebuild" — it's "**is your build reproducible and traceable**," so functional equivalence can be proven even across separate builds (pinned dependencies, checksums, SBOM comparison, deterministic builds) |

---

## Bad vs. Good Pattern (Docker Example)

```bash
# BAD: rebuild per environment, no shared identity
docker build -t myapp:dev .
docker build -t myapp:staging .
docker build -t myapp:prod .
# Three separate builds, three different image digests — even from "the same" Dockerfile

# GOOD: build once, promote the same image everywhere
docker build -t myapp:1.2.3 .
docker push registry/myapp:1.2.3

docker run -e DB_HOST=dev-db registry/myapp:1.2.3       # Dev
docker run -e DB_HOST=staging-db registry/myapp:1.2.3   # Staging
docker run -e DB_HOST=prod-db registry/myapp:1.2.3      # Prod
```

## How Configuration Gets Injected Without Rebuilding
- **Environment variables** — injected by the orchestrator (Kubernetes ConfigMaps, ECS task definitions)
- **External config servers** — Spring Cloud Config, Consul, AWS Parameter Store
- **Mounted config files** — Kubernetes ConfigMaps/Secrets mounted as volumes, not baked into the image
- **Feature flag services** — LaunchDarkly, Unleash — toggle behavior without touching the binary at all

---

## Quick Self-Check Questions
1. If a developer says "let me just rebuild the image real quick to fix the prod config," what's wrong with that statement?
   *(They're conflating a config fix with a code change — config should never require a rebuild; if it does, the config isn't properly externalized.)*
2. Is rebuilding a mobile app per environment automatically bad practice? *(No — it's often a genuine technical necessity due to compiled-in endpoints/certs, not a shortcut.)*
3. What's the real differentiator between good and bad rebuild-per-env practice? *(Reproducibility and traceability — not the mere fact of rebuilding.)*
4. Name three mechanisms that let you avoid baking config into an artifact. *(Env vars, external config servers, mounted config files/feature flags.)*