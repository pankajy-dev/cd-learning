# 06 — GitHub Actions CD Tutorial

GitHub Actions doesn't have a dedicated "CD" concept the way Argo CD or CD/RO do — it has **jobs**,
**environments**, and dependencies between jobs (`needs:`). You build the CD semantics (gates,
promotion order, same-artifact-everywhere) yourself out of those primitives. That's useful to know
going in: it's closer to Jenkins than to a purpose-built CD tool.

## The workflow

See [`.github/workflows/cd.yml`](../.github/workflows/cd.yml) at the repo root (GitHub only recognizes
workflows in that exact path). It reuses the same toy app from the Jenkins tutorial
(`sample-app/app`) so you can compare the two side by side.

Structure:

```
build-test-publish  (build once, tag with ${{ github.sha }}, push to GHCR)
        |
        v
   deploy-dev        (environment: dev — no protection rules, runs immediately)
        |
        v
   deploy-staging    (environment: staging)
        |
        v
   deploy-prod        (environment: prod — gated)
```

## The key GitHub-specific concept: Environments

Repo Settings → Environments lets you define `dev`, `staging`, `prod` and attach **protection rules**
to each: required reviewers, a wait timer, or restricting which branches can deploy to it. A job with
`environment: prod` will **pause and wait for an approval** from a required reviewer before it runs —
this is GitHub's version of Jenkins' `input` step, except it's configured in repo settings/UI, not in
the workflow file itself. That's a meaningful product difference worth noting: the gate is metadata on
the environment, not a line of pipeline code, so the same workflow file behaves differently depending
on how the environment is configured — gates are decoupled from pipeline logic.

Environments also give you:
- A per-environment deployment history/audit trail (visible under the repo's "Environments" tab)
- Per-environment secrets (a `prod` environment can have different credentials than `staging`)

## What's missing compared to a dedicated CD tool

- No native deployment strategies (canary/blue-green) — you write the `kubectl`/script logic yourself in a step.
- No cross-repo/multi-service release orchestration — "reusable workflows" help share logic, but there's no concept of a release train spanning several repos' pipelines.
- No built-in rollback — reverting means re-running an old workflow run or re-triggering with an old SHA.
- Environment "state" (what's actually deployed where) isn't modeled — the Environments tab shows *deployment history*, not live reconciliation against what's really running (contrast with Argo CD).

## Running it for real

1. Push this repo to a GitHub repo you own.
2. Settings → Environments → create `dev`, `staging`, `prod`. On `prod`, add yourself as a required reviewer.
3. Give the workflow permission to push to GHCR — no PAT or manual secret needed, this uses the
   token GitHub auto-generates per run (`secrets.GITHUB_TOKEN`, referenced in `cd.yml`'s
   `docker/login-action` step), but by default that token is read-only:
   - Settings → Actions → General → Workflow permissions → select "Read and write permissions."
   - This is on top of (not instead of) the `permissions: packages: write` already declared in
     `cd.yml` — the repo setting and the per-workflow `permissions:` block both have to allow it,
     whichever is more restrictive wins.
4. Push a change under `sample-app/app/` to `main` — e.g. edit the `Hello from version ${VERSION}`
   message in `server.js` — and watch the Actions tab: it'll run through dev and staging
   automatically, then sit "Waiting" on `deploy-prod` until you approve it from the run page.
5. First successful push creates the GHCR package (`ghcr.io/<owner>/<repo>/cd-sample-app`) under your
   account/org, defaulting to **private** — visible under your profile/org's "Packages" tab, not the repo.
   If you want to pull it without auth later, you'll need to change its visibility there, or link it to
   the repo (Package settings → "Connect repository") so repo collaborators inherit access automatically.
6. Compare this pause to the Jenkins `input` step from the other tutorial — functionally identical,
   configured completely differently.
