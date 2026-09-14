In artifact management, "metadata & manifests" refers to the supporting information that travels alongside a build artifact (a container image, package, binary, etc.) so that anyone downstream — a deployment pipeline, an auditor, a security scanner — can verify what it is, what's in it, and where it came from. Three pieces usually make up this layer:

## Checksums
A checksum (typically SHA-256 or similar) is a cryptographic hash of the artifact's contents. It lets you verify that the file you downloaded is byte-for-byte identical to the one that was published — nothing corrupted in transit, nothing tampered with. Most registries (npm, Docker Hub, Maven Central) publish a checksum or digest alongside every artifact, and package managers verify it automatically before installing.

- **Purpose:** integrity — "is this the exact file that was built?"
- **Common formats:** SHA-256 digest, sometimes SHA-1 or MD5 (legacy, weaker)
- **Typical use:** container image digests (`sha256:abc123...`), lockfile hashes (`package-lock.json`, `Cargo.lock`)

## SBOMs (Software Bill of Materials)
An SBOM is a structured inventory of every component, library, and dependency (direct and transitive) that went into an artifact — similar to an ingredients list. It's become a standard requirement in regulated and security-conscious environments because it lets you answer "am I affected by CVE-XYZ?" in seconds instead of days.

- **Purpose:** transparency into composition — "what's actually inside this?"
- **Common formats:** SPDX, CycloneDX
- **Typical use:** vulnerability scanning, license compliance, supply-chain audits

## Provenance / Attestation
Provenance metadata records *how* an artifact was produced: which source commit, which CI pipeline, which build system, at what time, and by whom. An attestation is a signed statement (often cryptographically signed) asserting that this provenance information is true and hasn't been altered — this is what lets a consumer trust the artifact wasn't built or modified by an untrusted party.

- **Purpose:** trust and traceability — "was this built the way it claims to have been?"
- **Common frameworks:** SLSA (Supply-chain Levels for Software Artifacts), in-toto attestations, Sigstore/cosign for signing
- **Typical use:** verifying that a production container image came from an approved CI pipeline and not from someone's laptop

Together, these three give you a chain of trust: the checksum proves integrity, the SBOM proves composition, and the provenance/attestation proves origin and build process. Modern artifact registries (Artifactory, Harbor, GitHub Packages, AWS ECR) increasingly store and enforce all three as part of the artifact's manifest, often gating deployment on policies like "only deploy images with a valid SLSA attestation and no critical CVEs in the SBOM."

