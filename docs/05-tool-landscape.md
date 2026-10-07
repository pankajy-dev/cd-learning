# 05 — Tool Landscape & Feature Comparison

Goal: when you look at your new product, you can place it on this map and spot the gaps/differentiators.

| Tool | Model | Push vs Pull | Pipeline-as-Code | Native deploy strategies | Approval gates | Multi-service / release orchestration | Notes |
|---|---|---|---|---|---|---|---|
| **Jenkins / CloudBees CI (CBCI)** | Self-hosted CI server, plugin ecosystem | Push | Jenkinsfile (Groovy DSL) | None built-in — scripted via plugins (Kubernetes CLI, blue-green via steps you write) | `input` step, manual gates | Weak natively; CloudBees CD/RO bolts this on | Extremely flexible, extremely manual. You build everything from primitives. |
| **CloudBees CD/RO (ElectricFlow)** | Dedicated release/deployment orchestration, model-based | Push | Mix of UI "pipeline model" + DSL | Blue/green, canary templates, rolling | First-class, with change-mgmt integration (ServiceNow etc.) | Strong — built for multi-service "release" as a first-class object | Enterprise-focused, models whole release trains across many services/environments |
| **GitHub Actions** | SaaS CI/CD, YAML workflows | Push | Native (`.github/workflows/*.yml`) | None built-in — community actions for canary/blue-green | `environments` with required reviewers | Weak — reusable workflows help, but no release-train concept | Great CI, "CD" is really "run deploy script on a schedule/trigger," thin orchestration |
| **GitLab CI/CD** | SaaS/self-hosted, YAML, tightly integrated with GitLab repo | Push (with optional GitOps agent) | Native (`.gitlab-ci.yml`) | Canary built-in for k8s, manual blue/green via environments | `environment` + manual jobs, protected environments | Moderate — multi-project pipelines exist but clunky | More opinionated than Jenkins, less than Argo. "Environments" dashboard is a nice touch for visibility. |
| **Argo CD** | GitOps continuous *delivery* via in-cluster reconciler | **Pull** | Yes — desired state is the git repo itself (Helm/Kustomize/plain YAML) | Via Argo Rollouts add-on: canary, blue/green with analysis | Via Argo Rollouts "pause" steps + sync policies (manual sync) | Weak alone; "ApplicationSets" help fan-out to many clusters | Not a pipeline tool at all — no "build" stage. Pairs with a CI tool upstream. Best-in-class for "what's actually running where right now." |
| **Spinnaker** | OSS multi-cloud deployment orchestration (Netflix-born) | Push | Pipelines as JSON/UI, "Pipeline-as-Code" via `.spinnaker` config less common | Canary (Kayenta analysis), blue/green, rolling red/black | Manual judgment stages | Strong — pipelines can fan out across clouds/accounts | Heavier to operate; losing mindshare but still influential in design patterns |
| **Harness** | Commercial CD/CI platform, UI + YAML | Push (also has GitOps module) | YAML pipelines | Canary, blue/green, rolling, built-in verification (APM-based) | Native approval stages, policy-as-code (OPA) | Strong — "Services," "Environments," "Pipelines" as modeled first-class objects | Probably your closest direct competitor to study — modern SaaS CD UX |

## Dimensions worth probing deeper for any CD product (including the one you're joining)

1. **Environment modeling** — is "environment" a first-class object with its own history/audit, or just a deploy target string in a YAML file?
2. **Artifact traceability** — can you click a running prod instance and see exactly which commit, build, and approval chain put it there?
3. **Progressive delivery automation** — does canary analysis require you to wire up your own metrics, or is it built-in (Argo Rollouts' `AnalysisTemplate`, Harness's native APM-based verification)?
4. **Rollback UX** — one click vs. re-running a whole pipeline vs. git revert.
5. **Governance at scale** — approval policies, change-management integration, audit logs — this is where enterprise CD tools (CD/RO, Harness) differentiate from pure CI tools stretched into CD.
6. **GitOps support** — does the tool pull from git continuously (self-healing drift correction) or only push on trigger (drift can silently diverge)?
7. **Multi-cluster/multi-region fan-out** — one release triggering coordinated deploys to N targets with per-target gating.

Keep this table updated once you've explored your new product — filling in its row is a good forcing function
to understand where it's strong/weak relative to the field.
