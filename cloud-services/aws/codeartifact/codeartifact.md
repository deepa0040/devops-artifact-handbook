# AWS CodeArtifact — Notes

Quick Explanation: https://www.youtube.com/watch?v=l0mYY2NUs08&t=204s

AWS CodeArtifact Features: https://aws.amazon.com/codeartifact/features/

AWS CodeArtifact Pricing: https://aws.amazon.com/codeartifact/pricing/

Notes: https://k21academy.com/aws-cloud/aws-codeartifact/

# What is AWS CodeArtifact?
CodeArtifact is a secure, central place to store all your software packages. When you’re building an application, you typically use dozens of external packages or libraries — things other developers have created that you don’t want to build from scratch.

An artifact repository gives you a consistent, reliable place to store and retrieve these components. This gives you three big benefits:

1️⃣ Security: Everyone in a team retrieves packages from a secure repository (CodeArtifact), instead of downloading from unsafe sources on the internet (hello, security risks)!

2️⃣ Reliability: If public package websites go down, you have backups in your CodeArtifact repository.

3️⃣ Control: Your team can easily share and use the same versions of packages, instead of everyone working with a different version of the same package.

AWS CodeArtifact automatically scales when you ingest or publish new packages to your repositories. Because it's a fully managed service, the setup and operation of its infrastructure is done for you.

# AWS CodeArtifact — Building Blocks

Simple structure

Domain → Repository → Package → Version
```
CodeArtifact Domain
       │
       ├── Repository
       │      │
       │      ├── Package
       │      │      ├── Version 1.0
       │      │      └── Version 1.1
       │      │
       │      └── Package
       │
       └── Repository
```

| Building Block          | Simple Meaning                                         | Example                           |
| ----------------------- | ------------------------------------------------------ | --------------------------------- |
| **Domain**              | A big container that groups repositories               | `my-company-domain`               |
| **Repository**          | Place where packages are stored                        | `npm-repo`                        |
| **Package**             | The library/software stored in the repository          | `my-utils`                        |
| **Package Version**     | A particular version of a package                      | `my-utils v1.2.0`                 |
| **Upstream Repository** | Another repository from which packages can be obtained | `dev-repo → shared-repo`          |
| **External Connection** | Connection to public package sources                   | npm, PyPI, Maven Central          |
| **IAM**                 | Controls who can access CodeArtifact                   | Developer = download, CI = upload |
| **Authentication**      | Login/permission required to use the repository        | `aws codeartifact login`          |

# AWS CodeArtifact Building Blocks

## 1. Domain

A **Domain** is the top-level container that groups one or more repositories.

### Key Points
- Provides a logical boundary for repositories.
- Stores package metadata and assets centrally.
- Assets are stored only once within a domain, even if referenced by multiple repositories.

---

## 2. Repository

A **Repository** contains packages and package versions.

### Key Points
- Serves as the main location for publishing and consuming packages.
- Supports multiple package formats such as npm, Maven, PyPI, and NuGet.
- Can be connected to upstream repositories and external package sources.

---

## 3. Package

A **Package** is a software component along with its metadata.

### Examples
- npm package: `react`
- Maven package: `com.company:utility`
- Python package: `requests`

### Key Points
- Contains package metadata.
- Consists of one or more package versions.

---

## 4. Package Version

A **Package Version** represents a specific release of a package.

### Examples
- `1.0.0`
- `2.5.1`
- `3.0.0`

### Key Points
- Each version can have one or more assets.
- Enables version tracking and dependency management.

---

## 5. Asset

An **Asset** is the actual file stored in CodeArtifact.

### Examples
- `.jar`
- `.pom`
- `.tgz`
- `.whl`
- `.nupkg`

### Key Points
- Assets are associated with package versions.
- These are the files downloaded by package managers during installation.

---

## 6. Upstream Repository

An **Upstream Repository** allows one repository to consume packages from another repository within the same domain.

### Benefits
- Package sharing between teams
- Centralized dependency management
- Reduced duplication
- Improved package governance

### Example

```text
Repository-B
      |
      v
Repository-A (Upstream)
```

When a package is not found in `Repository-B`, CodeArtifact searches the upstream repository for the package.

---

## 7. External Connection

An **External Connection** links a repository to public package sources.

### Supported Sources
- npm Registry
- Maven Central
- PyPI
- NuGet

### How It Works
When a package is requested and is not available in the repository, CodeArtifact can:

1. Fetch the package from the external source.
2. Cache the package within CodeArtifact.
3. Serve the package to consumers from the repository.

### Benefits
- Access to open-source dependencies.
- Faster future downloads through caching.
- Centralized control over external packages.

---

## Architecture Overview

```text
Domain
│
├── Repository A
│   ├── Package X
│   │   ├── Version 1.0
│   │   └── Version 2.0
│   │
│   └── Package Y
│
├── Repository B
│   └── Upstream → Repository A
│
└── External Connection
    ├── npm Registry
    ├── Maven Central
    ├── PyPI
    └── NuGet
```

## Summary

**Hierarchy:**

```text
Domain
  └── Repository
        └── Package
              └── Package Version
                    └── Asset
```

**Additional Components:**
- Upstream Repository → Repository-to-repository package sharing
- External Connection → Access to public package registries