# Artifact Types and Use Cases

Artifacts can be classified based on **what they contain, why they are created, and how they are consumed**.

> **Important:** These are general DevOps artifact categories. They are **not four types of AWS CodeArtifact**. AWS CodeArtifact is specifically a package repository service that supports package formats such as npm, Maven, PyPI, and NuGet.

---

## 1. Deployment Artifact

### Definition

A **Deployment Artifact** is a build output that is intended to be **deployed, installed, or executed in a runtime environment**.

### Examples

* JAR / WAR
* Compiled binaries
* `.deb`
* `.rpm`
* `.exe`
* `.msi`
* Docker/OCI image
* Application deployment package

### Example

```text
Source Code
    ↓
Build
    ↓
Application
    ↓
app-1.5.0.jar
    ↓
Deploy
    ↓
Production Server
```

### Real-world use case

A Java application is built by a CI pipeline:

```text
payment-service
        ↓
    Maven Build
        ↓
payment-service-1.5.0.jar
        ↓
     Store
        ↓
     Deploy
        ↓
Production
```

The `.jar` is a **deployment artifact** because the production environment consumes it to run the application.

### Key idea

> **Deployment artifact = something that the runtime environment can deploy, install, or execute.**

---

# 2. Library Artifact

### Definition

A **Library Artifact** is a reusable package that is consumed as a **dependency by another application or library**.

### Examples

| Ecosystem | Example               |
| --------- | --------------------- |
| npm       | `company-auth-utils`  |
| PyPI      | `company-data-utils`  |
| Maven     | `company-payment-sdk` |
| NuGet     | `Company.Logging`     |

### Example

Suppose three applications need the same authentication functionality:

```text
Application A ──┐
Application B ──┼──→ company-auth-utils
Application C ──┘
```

Instead of copying the authentication source code into every application, we create a reusable package:

```text
company-auth-utils
Version: 1.4.2
```

Applications can then consume it as a dependency.

```text
Application
     ↓
npm install company-auth-utils
     ↓
Private Package Repository
     ↓
company-auth-utils:1.4.2
```

---

## Why use a private artifact repository?

A private repository provides several benefits.

### 1. Centralized dependency management

Applications can consume approved internal packages from one location.

### 2. Versioning

Different versions can be maintained:

```text
company-auth-utils
├── 1.2.0
├── 1.3.0
├── 1.4.0
└── 1.4.2
```

### 3. Dependency control

Organizations can control which packages and versions applications are allowed to use.

### 4. Caching / upstream access

A private repository can also act as a proxy/cache for public dependencies.

For example:

```text
CodeBuild
    ↓
AWS CodeArtifact
    ↓
Public npm Registry
```

The first request may retrieve the package from the public registry, while subsequent requests can use the package available through the private repository.

### Key idea

> **Library artifact = a reusable, versioned dependency consumed by other software.**

---

# 3. Bundle Artifact

### Definition

A **Bundle Artifact** is a collection of related files packaged together and delivered as **one deployable or consumable unit**.

Instead of transferring many individual files:

```text
application binary
configuration
scripts
libraries
certificates
...
```

they can be packaged into:

```text
my-application-1.0.0.tar.gz
```

---

## Example

A legacy application running on EC2 may require:

```text
my-application/
├── bin/
│   └── application
├── config/
│   └── application.yaml
├── lib/
│   ├── library1.so
│   └── library2.so
└── scripts/
    ├── install.sh
    └── start.sh
```

Instead of transferring all these files individually:

```text
my-application-1.0.0.tar.gz
```

can contain everything.

Deployment:

```text
Artifact Storage
      ↓
Download .tar.gz
      ↓
Extract
      ↓
/opt/my-application/
      ↓
Run start.sh
      ↓
Application starts
```

### Common formats

* `.zip`
* `.tar.gz`
* `.tar`
* `.tgz`

### Important distinction

A bundle does **not** necessarily mean a "private folder."

Think of it as:

> **Multiple related files packaged and versioned as one deliverable.**

### Key idea

> **Bundle artifact = multiple related files packaged together so they can be delivered and consumed as one unit.**

---

# 4. Pipeline Artifact

### Definition

A **Pipeline Artifact** is an intermediate output produced by one stage of a CI/CD pipeline and consumed by another stage.

### Example

```text
Source
  ↓
Build
  ↓
app-1.5.0.jar
  ↓
Pipeline Artifact Storage
  ↓
Test
  ↓
Security Scan
  ↓
Deploy
```

The artifact allows later stages to consume the **exact output produced by the build stage**.

---

## Why is this useful?

One important DevOps principle is:

> **Build once, test once, deploy the same artifact.**

Instead of:

```text
Build
  ↓
Test
  ↓
Build again
  ↓
Deploy
```

we want:

```text
Build
  ↓
Create Artifact
  ↓
Test Artifact
  ↓
Scan Artifact
  ↓
Deploy Same Artifact
```

This improves consistency and reduces the possibility that the artifact tested is different from the artifact deployed.

---

## Examples of Pipeline Artifacts

A pipeline artifact could be:

* `app.jar`
* `app.zip`
* Docker image reference
* Terraform plan
* Test reports
* Build output
* Configuration package
* Generated documentation

### Key idea

> **Pipeline artifact = an intermediate output passed from one CI/CD stage to another.**

---

# Comparison

| Type                    | What is it?                                | Example                        | Main Consumer               |
| ----------------------- | ------------------------------------------ | ------------------------------ | --------------------------- |
| **Deployment Artifact** | Something deployed, installed, or executed | JAR, binary, Docker image, RPM | Runtime / Server            |
| **Library Artifact**    | Reusable dependency                        | npm, PyPI, Maven package       | Application / Developer     |
| **Bundle Artifact**     | Multiple related files packaged together   | `.zip`, `.tar.gz`              | Deployment process / Server |
| **Pipeline Artifact**   | Output passed between pipeline stages      | JAR, ZIP, test report          | CI/CD stages                |

---

# Important: These Categories Can Overlap

Artifact classification is based on **purpose and context**, not only on file extension.

For example:

```text
app-1.0.0.jar
```

can be a:

### Deployment Artifact

If production runs the JAR:

```text
app.jar
    ↓
Production Server
    ↓
java -jar app.jar
```

### Pipeline Artifact

If the JAR is temporarily passed between pipeline stages:

```text
Build
  ↓
app.jar
  ↓
Test
  ↓
Security Scan
  ↓
Deploy
```

The same physical file can therefore be both a **deployment artifact** and a **pipeline artifact**, depending on how it is being used.

---

# AWS Perspective

These general artifact categories should not be confused with AWS services.

AWS provides different services for different artifact needs:

```text
                         AWS Artifact Storage
                                │
              ┌─────────────────┼─────────────────┐
              │                 │                 │
        CodeArtifact           ECR               S3
              │                 │                 │
       Package artifacts    Container images   Generic files
              │
       ┌──────┼─────────┐
       │      │         │
      npm    Maven     PyPI
                    NuGet
```

---

## AWS CodeArtifact

**AWS CodeArtifact** is primarily a **package repository**.

It is designed for package/library ecosystems such as:

```text
npm
Maven
Gradle
PyPI
NuGet
```

Example:

```text
Developer / CodeBuild
        ↓
npm package
        ↓
AWS CodeArtifact
        ↓
Application
```

---

## Amazon ECR

**Amazon ECR** is primarily used for container images.

```text
Docker Build
     ↓
my-app:1.5.0
     ↓
Amazon ECR
     ↓
ECS / EKS
```

Here the container image is a deployment artifact.

---

## Amazon S3

S3 can be used to store generic files and deployment bundles.

Example:

```text
Build
  ↓
application.zip
  ↓
S3
  ↓
EC2 / Lambda / Deployment Process
```

---

# Quick Mental Model

Remember the four categories using the question:

### 1. Deployment Artifact

**"What am I going to run?"**

```text
JAR
Binary
Docker Image
RPM
```

### 2. Library Artifact

**"What does my application depend on?"**

```text
npm
PyPI
Maven
NuGet
```

### 3. Bundle Artifact

**"What group of files do I need to deliver together?"**

```text
app.zip
app.tar.gz
```

### 4. Pipeline Artifact

**"What output needs to move from one pipeline stage to another?"**

```text
Build Output
    ↓
Test
    ↓
Scan
    ↓
Deploy
```

---

# One-Line Summary

> **Deployment artifacts are things you deploy, library artifacts are dependencies you consume, bundle artifacts package multiple related files together, and pipeline artifacts pass build outputs between CI/CD stages.**

---

# AWS Service Mapping

| Requirement                          | Common AWS Service                     |
| ------------------------------------ | -------------------------------------- |
| npm / Maven / PyPI / NuGet packages  | **AWS CodeArtifact**                   |
| Docker / OCI images                  | **Amazon ECR**                         |
| Generic ZIP / TAR / deployment files | **Amazon S3**                          |
| CI/CD stage-to-stage outputs         | **Pipeline-specific artifact storage** |
| Source code                          | **GitHub / CodeCommit / GitLab etc.**  |

> **Interview point:** Do not say "AWS CodeArtifact stores every type of artifact." A better answer is: **"CodeArtifact is AWS's managed package repository for supported package ecosystems such as npm, Maven, PyPI, and NuGet. Other artifact types, such as container images and generic deployment bundles, are commonly stored in services such as ECR and S3."**
