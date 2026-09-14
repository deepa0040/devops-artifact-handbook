## Topic 2: Why Do We Need Artifacts?

This is really asking: **what problems exist if you *don't* have a proper artifact management practice?** Understanding the "why" makes every later topic (lifecycle, repos, promotion) make sense instead of feeling like arbitrary process.

### 1. Reproducibility — "It worked on my machine" problem
Without artifacts, every environment builds from source independently. Different machine, different dependency resolution, different result.
- **With artifacts**: one build, one binary, deployed everywhere — guaranteed identical
- **Without artifacts**: you're trusting that "the same source code" behaves the same way every time it's compiled — which floating dependencies, OS differences, and compiler versions constantly violate

### 2. Speed — Avoid rebuilding from scratch every time
Compiling/packaging can be slow (think large Java monorepos, native builds, ML training).
- Artifacts let you **build once, deploy many times** — deployment becomes "pull the file and run it," not "rebuild everything"
- Dependency artifacts (npm, pip, Maven) get **cached/proxied**, so builds don't re-download the internet every run

### 3. Traceability & Audit — "What exactly is running in prod?"
- Every artifact has a version/checksum/commit-SHA tying it to an exact source snapshot
- When something breaks in prod, you can answer precisely: *which artifact version, built from which commit, with which dependencies*
- Critical for **compliance** (SOC2, ISO 27001, etc.) — auditors ask "prove what code was deployed on date X"

### 4. Rollback Safety
- If v1.5 has a critical bug, you don't rebuild v1.4 from source hoping it comes out identical — you **redeploy the exact v1.4 artifact** that's still sitting in the repo
- This turns incident recovery from "rebuild and pray" into "click redeploy," often cutting recovery time from hours to minutes

### 5. Dependency Resilience
- If you rely on live internet fetches for every build (public npm, PyPI, Maven Central), you're exposed to:
  - Upstream outages
  - Package deprecation/removal (this has happened — e.g., the infamous `left-pad` npm incident that broke builds worldwide)
  - Supply chain attacks (malicious package injected upstream)
- A local/proxy artifact repo **caches and controls** exactly what dependency versions you consume

### 6. Security & Governance
- Centralized artifact repos let you **scan once, trust everywhere** — vulnerability scanning (Xray, Trivy, Snyk) happens at the artifact level, not per-deployment
- You can **gate promotion**: an artifact can't move from staging → prod unless it passes a security/quality gate
- Without a central repo, there's no single point to enforce these policies — every team/pipeline does its own thing (or nothing)

### 7. Collaboration Across Teams
- Team A doesn't need Team B's source code or build toolchain to use their library — they just pull the published artifact
- This **decouples build environments**: Team A can be on Java 21, Team B on Java 17, and it doesn't matter, because they consume each other's artifacts, not each other's source

### 8. Consistency Across Environments (ties back to Topic 1's promotion discussion)
- Artifacts are what make "dev/staging/prod parity" achievable
- Without a shared artifact, environments drift — and drift is the #1 cause of "works in staging, breaks in prod"

---

### The One-Line Summary
**Artifacts exist to turn "trust that the build is consistent" into "prove the build is identical" — enabling speed, safety, traceability, and collaboration at scale.**

### Quick Self-Check
1. Why is caching npm packages in a proxy repo about more than just speed? *(Resilience against upstream outages/removal, and control over supply chain security)*
2. If your org has no central artifact repo, what specific audit question becomes impossible to answer confidently? *(“What exact code/version was running in production on a given date?”)*
3. How does artifact-based rollback differ from "rebuild the old version"? *(Rollback reuses the exact previously-tested binary; rebuilding risks producing a non-identical result even from the "same" source.)*


## Why We Need Artifacts — Even With "Build Per Environment"

- **Need a fixed, deployable unit** — you never deploy raw source code live; each build still gets packaged into a JAR/image before deployment
- **Need version tracking per environment** — each build (staging, prod, etc.) gets its own version/tag so you know exactly what's running where
- **Need rollback capability** — old artifacts stay in the repo, so a bad build can be reverted instantly without rebuilding
- **Need dependency caching** — every build pulls external packages (npm/Maven/PyPI); an artifact repo prevents hitting the public internet each time and protects against outages/removals
- **Need a security scan checkpoint** — whatever gets built for prod must be scanned before deployment, regardless of build strategy
- **Need teams to share outputs, not source** — other teams consume your published artifact, not your raw code or build process
- **Need speed** — packaging once per build avoids re-compiling on every single deployment action
- **Need traceability/audit** — each artifact ties back to an exact commit, build job, and dependency set — critical for debugging and compliance

