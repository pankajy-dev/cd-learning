# 07 — Argo CD Tutorial (GitOps)

Argo CD is a different kind of tool than Jenkins or GitHub Actions. There's no "pipeline" that runs
build → test → deploy in sequence. Argo CD only does one thing: continuously watch a git repo and a
Kubernetes cluster, and make the cluster match what's declared in git. CI (build/test/publish an
image) happens somewhere else, upstream — Jenkins or GitHub Actions, same as in the other two tutorials.

This is the **pull** model mentioned in [`docs/05-tool-landscape.md`](05-tool-landscape.md): instead of
a pipeline pushing `kubectl apply` out to a cluster (which requires giving your CI system cluster
credentials), an agent *inside* the cluster pulls from git. Nothing external needs write access to
your cluster at all.

## What's in `argocd-app/`

```
argocd-app/
  manifests/
    base/                 -- the Deployment + Service, environment-agnostic
    overlays/dev/          -- Kustomize overlay: namespace cd-dev, image tag "dev-latest"
    overlays/staging/      -- namespace cd-staging, a pinned image tag (a specific git SHA)
    overlays/prod/         -- namespace cd-prod, 3 replicas, a pinned image tag
  argocd/
    application-dev.yaml      -- Argo CD Application: watches overlays/dev, auto-sync + self-heal
    application-staging.yaml  -- watches overlays/staging, auto-sync + self-heal
    application-prod.yaml     -- watches overlays/prod, NO auto-sync (manual gate)
```

**Promotion, in this model, is a git commit.** To promote a new build to staging, you edit
`overlays/staging/kustomization.yaml`'s `newTag` to the new image SHA and merge that change. Argo CD
notices the diff and reconciles staging to match within seconds. There's no "staging deploy job" to
run — the deploy *is* the git merge. Looking at a diff of this repo's history over time literally is
your deployment audit log.

## Why `prod` has no `automated` block

`dev` and `staging` self-heal continuously: if someone manually changes anything in that namespace
(e.g., `kubectl edit`), Argo CD reverts it back to match git on the next reconcile loop — drift is
corrected automatically. `prod` deliberately has no `automated` sync policy, so even after you merge
a change to `overlays/prod`, Argo CD will show the app as **OutOfSync** and wait. A human has to click
"Sync" (UI) or run `argocd app sync cd-sample-app-prod` (CLI). That manual sync click is Argo CD's
version of Jenkins' `input` step and GitHub's required-reviewer environment gate — same job, modeled
as "did someone trigger reconciliation," not "did someone approve a pipeline stage."

## Running it locally

### 1. Spin up a local cluster
```bash
brew install kind kubectl kustomize argocd
kind create cluster --name cd-learning
```

### 2. Install Argo CD into it
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd rollout status deploy/argocd-server
```

### 3. Open the UI
```bash
kubectl -n argocd port-forward svc/argocd-server 8081:443 &
# username: admin
# password:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```
Visit https://localhost:8081.

### 4. Push this repo to your own GitHub, then edit the Applications
Argo CD needs to pull from a real git URL. Push `cd-learning` to a repo under your GitHub account,
then in each `argocd-app/argocd/application-*.yaml`, replace `REPLACE_ME` in `repoURL` with your
GitHub username, and replace `REPLACE_ME` in each overlay's `kustomization.yaml` with your GHCR path
(same image your GitHub Actions workflow from the previous tutorial publishes to).

### 5. Register the apps
```bash
kubectl apply -f argocd-app/argocd/application-dev.yaml
kubectl apply -f argocd-app/argocd/application-staging.yaml
kubectl apply -f argocd-app/argocd/application-prod.yaml
```

Watch them appear in the UI. `dev` and `staging` go green (Synced) automatically. `prod` sits
OutOfSync until you click Sync — try it.

### 6. See GitOps self-heal in action
```bash
kubectl -n cd-dev scale deploy/cd-sample-app --replicas=0
```
Watch the UI: Argo CD detects the drift and scales it back up within seconds, with no pipeline run
involved at all. This is the behavior no push-based tool (Jenkins, GitHub Actions, CD/RO) gives you
for free — it's Argo CD's core differentiator.

## What's missing compared to a full CD platform

- No build step at all — you still need Jenkins/GitHub Actions/etc. upstream for that half.
- No canary/blue-green analysis by itself — needs the companion **Argo Rollouts** controller for
  progressive delivery with automated metric analysis.
- No cross-service release coordination out of the box — "app of apps" (an Application whose source
  is a folder of other Application manifests) is the usual pattern to fan out a related group, but
  there's no native concept of a multi-service release train with its own approval gate.
