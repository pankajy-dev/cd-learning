# CD Learning Repo

A hands-on path to understanding Continuous Delivery (CD) tooling, from zero.
Written for someone moving into a CD product who already knows CI concepts loosely
but hasn't worked CD day-to-day.

## How to use this repo

Read in order:

1. [`docs/01-basics.md`](docs/01-basics.md) — what CD actually is, how it differs from CI and CD(eployment)
2. [`docs/02-terminology.md`](docs/02-terminology.md) — glossary you'll hear in every CD product
3. [`docs/03-pipeline-anatomy.md`](docs/03-pipeline-anatomy.md) — stages, gates, artifacts, environments, promotion
4. [`docs/04-deployment-strategies.md`](docs/04-deployment-strategies.md) — blue/green, canary, rolling, feature flags
5. [`docs/05-tool-landscape.md`](docs/05-tool-landscape.md) — feature comparison: Jenkins/CBCI, GitHub Actions, GitLab CI/CD, Argo CD, Spinnaker, Harness
6. [`sample-app/`](sample-app/) — a real toy pipeline you run locally with Jenkins to see every concept in motion

## Why Jenkins first

Your target product context is CloudBees (CBCI = Jenkins-based CI, CD/RO = CloudBees CD/Release Orchestration,
originally ElectricFlow). Jenkins is also the most "manual" of the major tools — nothing is hidden behind
a managed SaaS UI — so building a pipeline by hand here teaches you the primitives (agents, stages, artifacts,
credentials, approval gates) that every other tool abstracts away. Once you've done it by hand, the opinionated
versions in GitHub Actions/GitLab/Argo CD will look like shortcuts, not new ideas.
