## Topic: Repository Types & Concepts

Here's a fuller breakdown of the three repository types you typically find in artifact management systems (like JFrog Artifactory, Sonatype Nexus, or similar tools):

## Local Repositories

These are storage locations physically hosted within your own repository manager. You push your own build outputs here — compiled binaries, packages, container images, whatever your team produces internally.

- **Purpose**: house artifacts you own and control (releases, snapshots, internal libraries)
- **Write access**: your CI/CD pipelines or developers publish directly into these
- **Examples**: `libs-release-local`, `docker-local`, `npm-internal`

## Remote Repositories (Proxy/Cache)

These act as a proxy in front of an external repository — like npmjs.com, Maven Central, PyPI, or Docker Hub. When a client requests a package, the remote repo checks its local cache first; if it's not there, it fetches from the upstream source and caches it for next time.

- **Purpose**: speed up downloads, reduce redundant external traffic, and provide a buffer if the upstream source goes down
- **Write access**: read-only from the user's perspective — you don't publish here, the system populates it automatically from the external source
- **Examples**: `npm-remote` (proxying npmjs.org), `maven-central-remote`

## Virtual Repositories (Aggregated)

These don't store artifacts themselves — they're a single unified endpoint that aggregates multiple local and remote repositories underneath. Clients query one URL and the virtual repo resolves the request across all the underlying repos it aggregates.

- **Purpose**: simplify client configuration — one URL instead of juggling multiple repo endpoints; centralizes resolution logic (e.g., check local repos first, then fall back to remote/proxy repos)
- **Write access**: typically read-only for consumption, though some tools allow deploying through a virtual repo to a designated "deployment" target underneath
- **Examples**: a `npm-virtual` combining `npm-local` + `npm-remote` so developers only need one registry URL

## How they typically work together

A common pattern:

1. Developers publish internal packages to a **local** repo.
2. External dependencies get proxied and cached through **remote** repos.
3. A **virtual** repo sits on top of both, giving developers and CI a single resolution point — so `npm install` or `pip install` doesn't need to know or care whether a package is internal or external.

This layered setup is why tools like Artifactory can serve as a single source of truth for all dependencies, whether they're built in-house or pulled from the public internet.

```
                     ┌─────────────────────┐
                     │   Virtual Repo       │  ← what your build actually points to
                     │  (npm-virtual)       │
                     └──────────┬───────────┘
                    ┌────────────┴────────────┐
                    ▼                          ▼
          ┌──────────────────┐      ┌──────────────────────┐
          │   Local Repo      │      │   Remote/Proxy Repo   │
          │ (your packages)   │      │ (cached public pkgs)  │
          └──────────────────┘      └──────────────────────┘
```

---

### Package Format Ecosystems (What Gets Stored)
Each language/tool has its own artifact format and repo protocol:

| Ecosystem | Format | Typical Repo |
|---|---|---|
| Java | JAR/WAR | Maven repo |
| JavaScript | npm package | npm repo |
| Python | wheel/sdist | PyPI repo |
| .NET | NuGet package | NuGet repo |
| Containers | Docker/OCI image | Docker/OCI registry |
| Kubernetes | Helm chart | Helm repo |
| Generic/binary | Any file | Generic repo |

Most modern tools (Artifactory, Nexus) support **all of these formats in one platform** — that's their main selling point over single-format tools (e.g., Docker Hub only does containers, npmjs.org only does npm).

### Metadata & Manifests
Every artifact in a repo carries metadata beyond just the file itself:
- **Checksum/hash** — proves the file hasn't been tampered with
- **SBOM (Software Bill of Materials)** — full list of everything inside the artifact (dependencies, versions, licenses)
- **Provenance/attestation** — proof of *how* the artifact was built (which pipeline, which commit, signed by whom)

### Promotion Pipelines (Repos as Stages)
A very common pattern: separate repos **represent** environments, and promotion = moving the artifact between repos:
```
npm-dev-local → npm-staging-local → npm-release-local
```
An artifact physically moves (or gets copied/tagged) from one repo to the next only after passing gates — tests, scans, approvals.

---

### Quick Self-Check
1. If your build points to a virtual repo, and it needs `lodash` (public) and `@yourcompany/auth` (internal) — where does each one actually come from? *(lodash → remote/proxy repo behind the virtual; `@yourcompany/auth` → local repo behind the virtual)*
2. Why would an org use a virtual repo instead of pointing builds directly at local and remote repos separately? *(Simplifies config — one URL for consumers; also lets admins add/change backing repos without consumers needing to update anything)*
3. What's the difference between a checksum and an SBOM? *(Checksum = proves file integrity/tamper detection; SBOM = full inventory of what's inside the artifact)*

---
## Repository Types Explained with AWS CodeArtifact

Let's make this concrete using a real AWS CodeArtifact setup, since abstract "local/remote/virtual" terms are confusing without a hands-on example.

### The Scenario
Your company builds a Node.js app. It needs:
- Public npm packages like `express`, `lodash` (from the internet)
- Your own internal shared package `@yourcompany/auth-utils` (built by your platform team)

You want developers to run `npm install` and get **both** — without caring where each one actually comes from.

---

### Step 1: Local Repository = Your Team's Published Packages
In AWS CodeArtifact, you create a repository called `internal-packages`.
- Your platform team runs `npm publish` and pushes `@yourcompany/auth-utils@1.0.0` **into this repo**
- Nothing is fetched from outside — this repo only contains what your org built
- **This is the "local repo" concept** — origin, not caching

```bash
aws codeartifact login --tool npm --repository internal-packages --domain mycompany
npm publish   # pushes @yourcompany/auth-utils into internal-packages repo
```

---

### Step 2: Remote/Proxy Repository = Cached Public npm Packages
You create another CodeArtifact repository called `npm-store`, and configure it with an **"external connection"** to the public npmjs.org registry.
- First time anyone requests `express@4.18.2`, CodeArtifact fetches it from npmjs.org and **permanently caches it**
- Every future request for `express@4.18.2` is served from AWS's cache — never touches the public internet again
- **This is the "remote/proxy repo" concept**

```bash
aws codeartifact associate-external-connection \
  --domain mycompany \
  --repository npm-store \
  --external-connection public:npmjs
```

---

### Step 3: Virtual/Aggregated Repository = One Endpoint for Everything
Now you create a third repository called `npm-team-repo`, and configure it to have **upstream repositories**: both `internal-packages` AND `npm-store`.

This is CodeArtifact's actual mechanism for the "virtual repo" concept — a repo can list other repos as **upstreams**, so a single endpoint searches through all of them.

```bash
aws codeartifact create-repository \
  --domain mycompany \
  --repository npm-team-repo \
  --upstreams repositoryName=internal-packages repositoryName=npm-store
```

Developers only ever configure npm to point to **one URL**: `npm-team-repo`.

```bash
npm config set registry https://mycompany-XXXX.d.codeartifact.us-east-1.amazonaws.com/npm/npm-team-repo/
```

### What Happens When a Developer Runs `npm install`
```
npm install
   ├── needs express@4.18.2      → npm-team-repo checks upstreams
   │                                 → found in npm-store (cached from npmjs.org) → served
   │
   └── needs @yourcompany/auth-utils@1.0.0  → npm-team-repo checks upstreams
                                                → found in internal-packages → served
```
The developer **never knows or cares** which upstream actually served the package — CodeArtifact handles that routing transparently.

---

### Visual Recap (AWS CodeArtifact Terms)

| Generic Concept | AWS CodeArtifact Term | What it holds |
|---|---|---|
| Local repo | A repository with **no external connection**, populated by `npm publish` | Your team's own packages |
| Remote/proxy repo | A repository with an **external connection** to npmjs.org/PyPI/Maven Central | Cached copies of public packages |
| Virtual/aggregated repo | A repository configured with **upstream repositories** | Combines the above under one endpoint |

### Why This Actually Matters (Practical Payoff)
- If npmjs.org goes down at 2am, your builds **keep working** — CodeArtifact already has `express@4.18.2` cached in `npm-store`
- If your platform team updates `@yourcompany/auth-utils` to `1.0.1`, developers get it automatically — no config change needed, since `npm-team-repo` already points to `internal-packages`
- Security teams can scan everything flowing through `npm-team-repo` in one place, regardless of origin

---
