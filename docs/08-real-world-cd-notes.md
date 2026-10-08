# 08 — Real-world CD: quick reference notes

## How this exercise would map to a real AWS deployment

The `deploy-dev`/`deploy-staging`/`deploy-prod` jobs in [`cd.yml`](../.github/workflows/cd.yml)
are placeholders (`echo "Deploying ..."`). In a real pipeline those steps would be replaced with
something that actually talks to the target platform:

- **ECS/Fargate**: update task definition, `aws ecs update-service --force-new-deployment`.
- **EKS**: `kubectl set image` or update a Helm/Argo CD manifest and let it reconcile (GitOps —
  see [07-argocd-tutorial.md](07-argocd-tutorial.md)).
- **Lambda**: `aws lambda update-function-code --image-uri <ref>`.
- **EC2**: SSM/SSH in, pull the new image, restart — same idea as `deploy.sh` in the Jenkins tutorial.

Across all of these, the invariant stays the same: the exact artifact built once in
`build-test-publish` (`image_ref`) is what gets promoted everywhere — never rebuilt per environment.

**Auth to AWS**: not static access keys. Standard practice is OIDC federation — GitHub issues a
short-lived OIDC token, AWS IAM trusts tokens from this specific repo/branch, and
`aws-actions/configure-aws-credentials` exchanges it for temporary, scoped credentials. No long-lived
secrets stored in GitHub.

**Is this pipeline Continuous Deployment?** No — it's Continuous Delivery, because `prod`'s
required-reviewer rule (Settings → Environments) gates the final step on a human approval. Remove
that rule and the same pipeline becomes Continuous Deployment — no code change needed, since the gate
is environment metadata, not pipeline logic.

**What's still missing vs. a production setup**: automated rollback (here it's just re-running an
old workflow/image ref manually), progressive delivery (canary %, traffic shifting — needs
CodeDeploy/App Mesh/service mesh, no native GH Actions primitive), and drift detection (Actions only
knows what it told AWS to do, not what's actually running — Argo CD's continuous reconciliation
against Git solves this specifically).

## Jenkins/Actions vs. dedicated CD/RO tools (CloudBees CD/RO, Harness, Spinnaker)

Jenkins and GitHub Actions can absolutely trigger a live deployment, not just publish an artifact —
`cd.yml`'s own `deploy-dev`/`deploy-staging`/`deploy-prod` jobs prove that. So the dividing line is
**not** "release vs. live deploy." A single-artifact live deploy (one jar released via Maven, one
container promoted through dev→staging→prod, as this whole repo does) is squarely in Jenkins/Actions'
comfort zone, whether it ends at "published to a registry" or "running in prod."

The real dividing line is **coordination complexity across multiple coupled artifacts/services**,
not artifact count or release-vs-deploy. Concretely, Jenkins/Actions start to strain when a release
needs:

- **Multiple coupled artifacts moving together** — e.g. 6 microservices that must deploy as one
  release, with cross-service version compatibility, and roll back together if any one fails.
- **One release = one object, with its own gate** — not 6 independent pipeline runs each with their
  own approval that could get approved out of order.
- **Native progressive-delivery strategies** (canary analysis, auto-rollback on metrics) instead of
  hand-scripted ones (`deploy.sh` in this repo is a toy stand-in for exactly this kind of logic).
- **Governance/audit tied to the release itself** — e.g. ServiceNow change-management integration —
  not just to one pipeline run.
- **"What's running where, as a release"** answered directly, instead of correlating N independent
  services' deploy histories by hand.

Jenkins *can* be forced to do this (a master Jenkinsfile fanning out to N downstream jobs, polling
their status) — people do build it — but at that point you're hand-rolling in Groovy what CD/RO-class
tools ship as a modeled first-class object: a "release" spanning N services/pipelines, with its own
approval, audit trail, and all-or-nothing semantics.

**Where Argo CD fits in**: it isn't a CD/RO competitor — it solves one narrow problem extremely well
(continuous drift-corrected reconciliation against Git, Kubernetes-only). It's often the component a
CD/RO tool or pipeline hands off to for the k8s leg of a deploy, while CD/RO handles cross-service
orchestration, non-k8s targets, and governance Argo CD doesn't touch.

**Rule of thumb**: single artifact, single pipeline, promoted through environments → Jenkins/Actions
is right-sized, live deploy or not. Coordinated release across multiple coupled
artifacts/services/environments → that's the specific gap CD/RO-class tools exist to fill.

## CD isn't only container images — other common deploy targets

- **Static frontend builds** — HTML/JS/CSS bundle shipped to S3+CloudFront, Netlify, Vercel.
- **Serverless function artifacts** — zip/jar (not always a container) for Lambda, Azure Functions.
- **Infrastructure itself** — Terraform/CloudFormation/Pulumi plans applied as the "deployment."
- **Database migrations** — schema changes rolled out as their own pipeline stage/gate.
- **Config-only changes** — feature flags, CasC, Helm `values.yaml` — no rebuild, just reconciled config.
- **Mobile builds** — APK/IPA shipped to app stores or internal distribution (Fastlane-style pipelines).
- **VM/AMI images** — Packer-built images rolled out to an EC2 fleet via instance refresh.
- **Library/package releases** — npm/Maven/PyPI publish; the "deployment" is a version bump, not a running process.
- **ML model artifacts** — model weights pushed to an inference service/registry.

The mechanics taught in this repo (build once, promote the same artifact, gate, smoke-test, rollback)
apply to all of these — only the "what gets built" and "what deploy actually does" change per target.
