# 03 — Anatomy of a CD Pipeline

A concrete, representative pipeline most CD tools will model this same way under different syntax:

```
 commit/PR
    |
    v
 [ Build ]  --> compile, produce artifact, tag with git SHA
    |
    v
 [ Test ]   --> unit + integration tests against the artifact
    |
    v
 [ Publish ] --> push artifact to registry (immutable, versioned)
    |
    v
 [ Deploy: Dev ]        --> auto, no gate
    |
    v
 [ Deploy: Staging ]    --> auto, maybe a quality gate (coverage %, perf test)
    |
    v
 [ Approval Gate ]      --> human clicks "promote to prod" (Delivery) or skipped (Deployment)
    |
    v
 [ Deploy: Prod ]       --> canary or blue/green, with automatic health-check verification
    |
    v
 [ Post-deploy verify ] --> smoke tests, rollback if failed
```

## Key design questions every CD tool answers differently

1. **What triggers promotion to the next environment?** Fully automatic, manual click, or policy-based (e.g., auto-promote outside business hours, else wait)?
2. **Is the pipeline a single linear definition, or separate per-environment pipelines wired together?** Jenkins/GitHub Actions: usually one file, environment are stages. Argo CD: no "pipeline" at all — each environment is a separate Application reconciled independently from git state.
3. **Where does pipeline state live?** Push-based tools (Jenkins, CD/RO) hold run state in the CD server's own DB. GitOps tools (Argo CD) hold *desired* state in git and current state in the cluster — the CD tool is just a reconciler, not a run history by itself.
4. **How are secrets/credentials injected into a stage?** Vault integration, built-in credential store, cloud IAM roles.
5. **How is a multi-service release coordinated?** Does the tool understand "release train" (deploy service A, B, C together, as a unit), or is every pipeline single-service and coordination is a human/process problem?

## Promotion vs. rebuild — the detail that separates toy CI configs from real CD

A very common mistake in a first CD setup: having "Deploy to staging" and "Deploy to prod" each run `docker build` again.
That's not CD — that's two independent builds that happen to use the same Dockerfile, with no guarantee they produce
identical bits (dependency drift, base image updates, non-deterministic builds). Real CD pipelines build **once**,
publish an artifact with an immutable reference (digest, not just a mutable tag like `latest`), and every later
stage *references that same reference*. The sample app in this repo demonstrates this explicitly.
