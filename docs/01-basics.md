# 01 — The Basics

## CI vs. the two CDs

People say "CI/CD" like it's one thing. It's three overlapping practices:

| Term | What it means | Who/what triggers it |
|---|---|---|
| **CI — Continuous Integration** | Every code change is automatically built and tested, merged frequently into a shared branch. | Every commit/PR |
| **Continuous Delivery** | Every change that passes CI is automatically prepared into a release-ready, deployable artifact — and *can* be deployed to any environment at the push of a button. A human still approves the final prod push. | Every successful CI build |
| **Continuous Deployment** | Same as Delivery, but there's no human gate — if it passes all checks, it goes straight to production. | Every successful CI build, no manual gate |

Continuous Delivery is the "safe to ship any time" guarantee. The product you're moving to almost certainly
sells itself on this guarantee: given a passing build, can we get it to any environment, reliably, with
visibility into what's running where, and roll back if it's bad.

## What a CD product actually does

Strip away branding and every CD tool is doing some subset of:

1. **Trigger** — detect a new build/artifact (usually from CI) or a schedule or a manual click.
2. **Promote** — move an artifact through a sequence of environments (dev → staging → prod), not rebuild it. The artifact built once should be the *exact* artifact deployed everywhere ("build once, deploy many").
3. **Gate** — require approval, a passing test suite, a change ticket, or a time window before promotion continues.
4. **Deploy** — actually push the artifact into an environment using some strategy (rolling, blue/green, canary).
5. **Verify** — run smoke tests / health checks post-deploy, often automatically rolling back on failure.
6. **Visualize/audit** — show what version is in which environment right now, and the full history of what shipped when, approved by whom. This is the part CI tools are usually weak at and dedicated CD tools (Argo CD, Spinnaker, Harness, CloudBees CD/RO) are built around.

## Why CD is a harder problem than CI

CI is "did my code work in isolation." CD deals with:
- **State** — a running production system has state (traffic, data, feature flags) that a CI test run doesn't.
- **Irreversibility** — a bad test run costs you nothing; a bad prod deploy costs users/money.
- **Topology** — multiple environments, each potentially different infra (k8s cluster, VM fleet, serverless), and the tool needs a model of all of them.
- **Coordination** — multi-service deployments need ordering, dependency awareness, and rollback across services, not just one build.

Keep that framing in mind as you explore any CD tool: ask "how does it model environments," "how does it guarantee
the same artifact everywhere," and "what's the rollback story."

### Topology, in more detail

CI just needs one thing: a runner that can check out code and run a build/test command. Every CI job
looks basically the same regardless of what the app eventually runs on.

CD has to actually land an artifact onto *real infrastructure*, and that infrastructure varies wildly
per environment:

- **dev** might be a single Kubernetes namespace in a shared cluster
- **staging** might be its own dedicated k8s cluster
- **prod** might be a fleet of VMs behind a load balancer in one region, and serverless (Lambda/Cloud
  Functions) for another part of the system
- a different service might deploy to a completely different cloud account, or even a different cloud
  provider entirely

A CD tool has to know, for *each* environment: how do I authenticate to it, what does "deploy" even
mean there (`kubectl apply` vs. `scp` + restart a service vs. `aws lambda update-function-code`), what
does "healthy" look like there, how do I query current state there. That's why CD tools have concepts
like Argo CD's `destination.server` (which cluster), or Harness's "Infrastructure Definitions," or
Spinnaker's "accounts" per cloud provider — they're all modeling "this environment is a different kind
of place, with its own rules for deploying and verifying." A pure CI tool stretched into CD usually
just shells out to whatever CLI matches that infra, with no shared abstraction — which is exactly the
gap dedicated CD tools try to close.

### Coordination, in more detail

CI tests one build in isolation. CD often has to deploy a *change that spans several services at
once* — e.g., a new API version in `order-service` that only works once `payment-service` has also
shipped a compatible contract change.

That raises problems CI never has to solve:
- **Ordering** — payment-service must deploy before order-service, or the rollout breaks
- **Dependency awareness** — the tool needs to know these two deploys are linked, not independent
- **Rollback across services** — if order-service's deploy fails health checks, you may need to roll
  back *both* services together to get back to a known-good combined state, not just the one that failed

Plain CI tools (and even a lone Jenkins pipeline) usually have no native concept of "this is one
logical release spanning N services" — that's a human/process problem unless the tool has a feature
for it. This is specifically what CloudBees CD/RO's "release" object, or Spinnaker's multi-pipeline
fan-out, or Harness's multi-service pipelines are built to solve: model the group of deployments as
one unit with shared ordering and a shared rollback boundary, instead of N independent single-service
pipelines that happen to run near each other in time.
