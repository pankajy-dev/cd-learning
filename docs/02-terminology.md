# 02 — Terminology Glossary

Grouped by theme, not alphabetically, so related terms sit together.

## Pipeline structure

- **Pipeline** — the full automated sequence from code change to deployed artifact.
- **Stage** — a named phase of the pipeline (Build, Test, Deploy-Staging, Deploy-Prod). Stages usually run sequentially; steps inside a stage can run in parallel.
- **Step/Task** — a single unit of work inside a stage (run tests, build image, kubectl apply).
- **Job** — in Jenkins terms, a configured, runnable pipeline definition. In GitHub Actions, roughly a "job" is a group of steps run on one runner.
- **Trigger** — the event that starts a pipeline run: webhook (push/PR), schedule (cron), manual, or upstream pipeline completion.
- **Runner / Agent / Executor** — the compute (VM, container, bare metal) that actually executes pipeline steps. Jenkins calls them agents, GitHub Actions calls them runners, GitLab calls them runners.

## Artifacts and versioning

- **Artifact** — the immutable build output: a container image, a jar, a tarball, a Helm chart. CD's core promise is you build it once and promote the *same* artifact.
- **Artifact repository** — where built artifacts live (Nexus, Artifactory, container registries like ECR/GCR/Docker Hub).
- **Immutable artifact / Build once, deploy many** — the principle that you never rebuild between environments; you only ever re-deploy the same bits. Rebuilding per environment is a classic anti-pattern because it breaks the guarantee that what you tested is what you shipped.
- **Semantic versioning (SemVer)** / **Build number** / **Git SHA tagging** — common ways artifacts get identified across environments.

## Environments and promotion

- **Environment** — a named deployment target: dev, QA, staging, prod. Usually mapped to real infra (a namespace, a cluster, an account).
- **Promotion** — moving a specific artifact version from one environment to the next (staging → prod), the central CD action.
- **Environment parity** — how similar lower environments are to prod; low parity is why "works in staging" lies to you.
- **Pipeline-as-Code** — defining the pipeline itself in a versioned file (Jenkinsfile, `.github/workflows/*.yml`, `.gitlab-ci.yml`) instead of a GUI config. Universal now, worth noting when a tool *doesn't* support it.

## Gates and approvals

- **Gate / Approval gate / Manual intervention** — a pipeline pause requiring human sign-off (or an external check, e.g., a change-management ticket) before continuing.
- **Quality gate** — an automated gate based on a metric threshold (test coverage, static analysis score, error budget).
- **Change management integration** — linking a deploy gate to an external approval system (ServiceNow, Jira) — common in regulated enterprises, a CD/RO (CloudBees) selling point.

## Deployment mechanics

- **Rolling deployment** — replace instances/pods gradually, old and new versions coexist briefly.
- **Blue/Green deployment** — run two full environments ("blue" = live, "green" = new); switch traffic atomically, keep blue as instant rollback.
- **Canary deployment** — route a small % of traffic to the new version, watch metrics, then ramp up or roll back.
- **Rollback** — reverting to the previous known-good artifact/version, ideally automatic on failed health checks.
- **Feature flag / dark launch** — decoupling "deployed" from "visible to users" — ship code dark, flip a flag to activate. (This is literally CloudBees Feature Management's domain.)
- **GitOps** — the environment's desired state is declared in a git repo; an operator (Argo CD, Flux) continuously reconciles the live environment to match git, rather than a pipeline imperatively pushing changes.
- **Push-based vs. pull-based deployment** — push: the CD tool connects out to the target and applies changes (classic Jenkins/CD/RO model). Pull: an agent inside the target cluster watches a source of truth and pulls changes (GitOps model, Argo CD/Flux). This distinction is one of the biggest "pick a tool" decisions in CD today.

## Observability / verification

- **Smoke test** — a minimal post-deploy check that the new version is alive and basically functional.
- **Health check / readiness probe** — infra-level signal used to decide if an instance is serving traffic correctly.
- **Deployment frequency, lead time, change failure rate, MTTR** — the DORA metrics; most CD tools report dashboards around these because they're the industry-standard way to measure delivery performance.

## Orchestration concepts

- **Fan-out / fan-in** — running parallel deploys to multiple targets then waiting for all to finish before proceeding.
- **Pipeline template / reusable workflow** — a parameterized pipeline definition reused across many services (critical at enterprise scale — "how do 200 teams not each hand-roll their own pipeline").
- **Multi-tenancy** — how a CD platform isolates teams/projects sharing the same control plane (RBAC, folders, namespaces).
