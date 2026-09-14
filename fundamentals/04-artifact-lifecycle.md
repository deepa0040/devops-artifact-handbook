## Topic 3: Artifact Lifecycle

The lifecycle is the **journey an artifact takes from creation to retirement**. Understanding each stage tells you what tooling/process is needed at that point.

### The Stages

**1. Build**
- Source code is compiled/packaged into a raw artifact
- Example: `mvn package` produces a `.jar`; `docker build` produces an image
- Not yet stored anywhere permanent — just created locally/in CI

**2. Version / Tag**
- The artifact gets a unique identifier (SemVer, git-SHA, build number)
- Example: `myapp:1.2.3` or `myapp:a1b2c3d`
- Without this, you can't tell one build apart from another later

**3. Publish / Store**
- Artifact is pushed to a repository (Artifactory, Nexus, ECR, npm registry)
- This is the point it becomes **shareable and durable** — not just sitting on a build agent that could get wiped

**4. Scan**
- Security/vulnerability scan runs against the stored artifact (Trivy, Snyk, Xray)
- Also where SBOM (Software Bill of Materials) gets generated
- Happens **before** promotion — catching issues early, not after deployment

**5. Promote**
- Artifact moves from one repo/stage to the next: dev repo → staging repo → prod repo
- Promotion usually requires passing a **gate** — tests passed, scan clean, manual approval, etc.
- This is where "build once, promote many" lives — the *same* artifact physically moves, it doesn't get rebuilt

**6. Deploy**
- The promoted artifact is pulled and run in the target environment
- Environment-specific config gets injected here (not baked into the artifact)

**7. Monitor / Retain**
- Artifact stays in the repo even after deployment — needed for rollback, audits, debugging
- Retention policies decide how long old versions are kept before cleanup

**8. Retire / Cleanup**
- Old, unused, or vulnerable artifact versions get deleted
- Important for **storage cost control** and **reducing attack surface** (old vulnerable versions sitting around are a security risk)

---

### Quick Visual
```
Build → Version/Tag → Publish → Scan → Promote → Deploy → Monitor/Retain → Retire
```

### Simple Example (Docker image)
- `docker build -t myapp:1.4.0 .` → **Build**
- Tag is `1.4.0` → **Version**
- `docker push registry/myapp:1.4.0` → **Publish**
- Trivy scans the image → **Scan**
- Image promoted from `dev-repo` to `prod-repo` after passing tests → **Promote**
- `kubectl apply` pulls `myapp:1.4.0` into prod with prod env vars → **Deploy**
- Image stays in registry for 90 days → **Monitor/Retain**
- After 90 days, old unused tag gets auto-deleted → **Retire**

### Quick Self-Check
1. Why does scanning happen *before* promotion, not after deployment? *(Catch vulnerabilities before they reach production, not after)*
2. What's the difference between "publish" and "promote"? *(Publish = first storage of a newly built artifact; promote = moving an already-published artifact to the next environment/repo)*
3. Why keep old artifact versions around instead of deleting immediately? *(Rollback capability and audit trail)*

---

## Dependency Artifact

Good catch — dependency caching doesn't fit neatly into the 8 stages I listed, because it's actually a **different flow** than "build → deploy your own artifact." Let me break down where and how it fits.

## Dependency Caching — Where It Fits in the Bigger Picture

### The Key Difference
- **Your own artifacts** (JAR, Docker image) → you produce them → they go through the full lifecycle (build → version → publish → scan → promote → deploy)
- **Dependency artifacts** (npm packages, Maven libraries, PyPI packages) → **someone else produced them** → you just *consume* them → they follow a **caching/proxy flow**, not the full lifecycle

### How Dependency Caching Actually Works

```
Your build process needs: express@4.18.2 (npm package)
                              │
                              ▼
              Does it exist in your LOCAL/proxy repo cache already?
                    │                           │
                   YES                          NO
                    │                           │
          Serve from cache              Fetch from public npm registry
          (fast, no internet call)          → store a copy in your repo
                                              → serve to your build
                                              → next time = cache hit
```

### The Repo Type Involved: **Remote Repository (a.k.a. Proxy Repo)**
This is a specific repo type (in Artifactory/Nexus terms) that:
- Sits **in front of** a public registry (npmjs.org, PyPI, Maven Central)
- On first request for a package version, fetches it from upstream and **stores a permanent local copy**
- On every future request for that same version, serves the **cached copy** — never touches the internet again for that version

### Why This Matters (Practically)
| Without caching | With caching |
|---|---|
| Every build hits the public internet for every dependency | Only the *first* build ever fetches from the internet; rest are served locally |
| If npm registry has an outage, your builds fail | Your builds keep working — cache doesn't care if upstream is down |
| If a package version gets deleted/unpublished upstream (happens more than people think) | You still have your cached copy forever — unaffected |
| No control over what's actually in a "package" — supply chain risk | You can scan cached packages before they're used, catch malicious versions |
| Slower builds — downloading megabytes of dependencies every time | Faster builds — pulling from your own network, not the internet |

### Real Example
```
Team's CI pipeline runs `npm install`
   ↓
npm is configured to point to: https://your-company.jfrog.io/npm-remote/
   (NOT https://registry.npmjs.org directly)
   ↓
Your Artifactory/Nexus checks: do we have lodash@4.17.21 cached?
   → Yes → instantly served
   → No  → fetched once from npmjs.org, cached, then served
```

### One Important Distinction
This is different from **internal package publishing** (Use Case #3 from earlier) where your *own* team publishes a package to a **local repo** — that's origin, not caching.

| Repo type | What it does | Example |
|---|---|---|
| **Remote/proxy repo** | Caches external packages you don't own | npm proxy repo caching `express`, `lodash` |
| **Local repo** | Hosts packages your org produces | `@yourcompany/logger` published by your team |
| **Virtual/aggregated repo** | Combines both so consumers hit one URL | `npm-virtual` = remote proxy + local repo merged |

