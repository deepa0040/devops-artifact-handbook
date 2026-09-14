# Package Format Ecosystems

Reference table for artifact/package formats across the software development lifecycle, mapped to the roles that typically own or use them.

## Core Formats

| Format | Ecosystem | Typical Artifact | Common Registry/Tool | Primarily Owned By |
|---|---|---|---|---|
| **Maven/Gradle** | Java/JVM (also Android) | `.jar`, `.war`, `.pom`, `.aar` | Maven Central, Nexus, Artifactory | Backend, Android |
| **npm** | JavaScript/Node.js | `.tgz` (tarball) | npmjs.com, GitHub Packages | Frontend, Full-stack |
| **PyPI** | Python | `.whl`, `.tar.gz` (sdist) | pypi.org, private indexes | Backend, Data/ML |
| **NuGet** | .NET/C# | `.nupkg` | nuget.org, Azure Artifacts | Backend (.NET) |
| **Docker/OCI** | Containers | Image layers, manifests | Docker Hub, GHCR, ECR, GCR | DevOps, Backend, SRE |
| **Helm** | Kubernetes | `.tgz` charts | ChartMuseum, OCI registries | DevOps, SRE |
| **Debian/RPM** | Linux packages | `.deb`, `.rpm` | APT repos, YUM/DNF repos | DevOps, SRE |
| **Generic/binary** | Anything else | Arbitrary files | Artifactory, Nexus, S3-backed repos | DevOps, Platform Eng |

## Additional Formats (often missing from roadmaps)

| Format | Ecosystem | Typical Artifact | Common Registry/Tool | Primarily Owned By |
|---|---|---|---|---|
| **SPM / CocoaPods** | iOS/Swift | `.xcframework`, source packages | Swift Package Index, CocoaPods trunk | iOS |
| **Conda** | Python/Data Science | `.conda`, `.tar.bz2` | Anaconda.org, conda-forge | Data/ML |
| **Cargo** | Rust | `.crate` | crates.io | Backend (Rust) |
| **Go modules** | Go | source-based (no binary artifact) | proxy.golang.org, GOPROXY | Backend (Go) |

## Role → Format Quick Reference

| Role | Relevant Formats | Depth Needed |
|---|---|---|
| **Frontend (FE)** | npm | Light–Medium |
| **Backend (BE)** | Maven/Gradle, PyPI, NuGet, Docker/OCI, Cargo, Go modules | Medium–Deep |
| **iOS** | SPM, CocoaPods (Carthage in legacy projects) | Medium |
| **Android** | Maven/Gradle (`.aar` publishing) | Medium |
| **DevOps / Platform Engineering** | All formats — Docker/OCI, Helm, Debian/RPM, generic, plus language ecosystems as proxies | Deep |
| **SRE / Infra** | Docker/OCI, Helm, Debian/RPM | Medium |
| **Full-stack** | npm + one backend format (Maven or PyPI) + Docker | Light–Medium each |
| **Data / ML Engineer** | PyPI, Conda, Docker/OCI | Medium |

## Key Concepts to Learn (in order)

1. **What an artifact is** — a packaged, versioned build output (vs. source code in Git)
2. **Why artifact repositories exist** — reliable, reusable, versioned storage so systems don't rebuild from source every time
3. **Publishing workflow** — `mvn deploy`, `npm publish`, `twine upload`, `docker push`
4. **Versioning schemes** — SemVer (npm, Cargo), Maven's GAV coordinates, Docker tags, Debian's epoch:version-revision
5. **Dependency resolution** — lockfiles, transitive dependencies, checksums
6. **Universal artifact managers** — JFrog Artifactory, Sonatype Nexus (proxy/cache multiple formats behind one system)
7. **CI/CD integration** — build → push to registry → pull exact version/digest for deployment
8. **Immutability & security** — immutable vs. mutable artifacts, signing/provenance (Sigstore/cosign, GPG), SBOM (Software Bill of Materials)

---
*Note: Docker/OCI is increasingly becoming a universal artifact format — Helm charts, WASM modules, and even generic binaries are now often stored in OCI-compliant registries.*