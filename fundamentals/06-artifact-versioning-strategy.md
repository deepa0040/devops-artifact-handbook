# Artifact Versioning Strategies

Here's a breakdown of common approaches and where each one shines (or bites you):

## Semantic Versioning (SemVer)

Format: `MAJOR.MINOR.PATCH` (e.g., `2.4.1`)

- **MAJOR** — breaking changes
- **MINOR** — new features, backward-compatible
- **PATCH** — bug fixes, backward-compatible

**Good for:** libraries, APIs, packages — anything consumers depend on and need to reason about compatibility for. Tools like npm, pip, and Cargo build their dependency resolution around this contract.

**Pitfall:** it's a human promise, not an enforced one. Nothing stops a team from shipping a breaking change in a "minor" bump. It also doesn't capture *when* something was built — two different commits could both claim `1.2.0` during development if you're not careful.

## Build-Number Tagging

Format: incrementing integer per build (e.g., `build-4521`), often combined with SemVer: `2.4.1-b4521`

**Good for:** CI/CD pipelines where every build needs a unique, always-increasing identifier — useful for rollback ("go back to build 4519") and correlating an artifact to the exact CI run that produced it.

**Pitfall:** meaningless on its own — tells you *order* but nothing about *content* or *compatibility*. Also pipeline-dependent; if you switch CI systems or run parallel pipelines, numbering can collide or reset.

## Git-SHA Tagging

Format: full or short commit hash (e.g., `a3f9c2e`)

**Good for:** absolute traceability. The tag maps to an exact, immutable snapshot of source code — no ambiguity, no manual bumping, no human error. Great for internal deployments, container images, and reproducible builds.

**Pitfall:** not human-readable or orderable — you can't look at `a3f9c2e` vs `7b1d044` and know which is newer or whether it's a breaking change. Usually paired with a SemVer or date tag rather than used alone for anything user-facing.

## The "latest" Tag Problem

`latest` is convenient and dangerous:

- **Mutable by definition** — it points to whatever was pushed most recently, so the same tag can resolve to different content over time. This breaks reproducibility: "works on my machine" often means "I pulled `latest` yesterday."
- **No rollback story** — if `latest` is broken, there's no built-in way to know what the *previous* `latest` was unless you've tagged it separately.
- **Race conditions in CI/CD** — concurrent builds/deploys pulling `latest` can grab different underlying images mid-push.
- **Caching lies to you** — container layers or package managers may cache an old `latest`, so different nodes in a cluster silently run different code.

**Best practice:** treat `latest` as a *pointer for convenience* (e.g., local dev, "give me something recent") but never deploy production off it. Pin production to an immutable tag — SHA, SemVer, or both — and let `latest` be a moving alias on top of immutable tags rather than the source of truth.

## Common combo in practice

A lot of mature pipelines tag every artifact multiple ways at once:

```
myapp:2.4.1
myapp:2.4.1-a3f9c2e
myapp:latest        (only in dev/staging)
```

This gives you human-readable intent (SemVer), exact traceability (SHA), and convenience (latest) without forcing a single tag to do all three jobs.