# 04 — Deployment Strategies

These are the actual mechanics of "pushing new code live," independent of which CD tool orchestrates them.
Every CD product's value prop usually boils down to "we make these strategies easy and safe."

## Rolling deployment
Replace old instances with new ones a few at a time. Default in Kubernetes (`RollingUpdate` strategy).
- Pros: simple, no extra infra cost, zero-downtime if done right.
- Cons: both versions serve traffic simultaneously during rollout — requires backward-compatible API/schema. Rollback is "roll forward with old version," not instant.

## Blue/Green deployment
Two full, identical environments. "Blue" is live. Deploy new version to "Green," run checks, then flip the router/load balancer so Green becomes live.
- Pros: instant rollback (flip back to Blue), full testing against prod-like traffic before switch.
- Cons: 2x infra cost (even if briefly), stateful services (DBs) are hard to blue/green cleanly.

## Canary deployment
Send a small % of real traffic to the new version, watch error rate/latency, progressively increase, abort if metrics regress.
- Pros: limits blast radius of a bad release automatically, often paired with automated analysis (Argo Rollouts, Spinnaker's Kayenta, Flagger).
- Cons: needs real traffic-splitting infra (service mesh or smart load balancer) and good metrics to judge "is this canary healthy."

## Feature flags / dark launches
Deploy the code to 100% of instances, but gate the new behavior behind a runtime flag. Decouples "deployed" from "released."
- This is the layer *above* deployment strategy — you can combine it with any of the above. CloudBees Feature Management (CBFM) lives here.
- Lets you roll out to users by %, by segment, instantly flip off without a redeploy — faster rollback than any infra-level strategy.

## GitOps reconciliation (not really a "strategy," but a different deployment model)
Instead of a pipeline imperatively running `kubectl apply`, an in-cluster agent (Argo CD, Flux) continuously diffs
live cluster state against a git repo and self-heals toward it. Deployment "happens" when you merge a PR to the
git repo that defines desired state — the agent handles the rest, including drift correction if someone
manually changes something in the cluster.

## Rollback mechanics worth comparing across tools
- **Automatic** — triggered by failed health check/metric threshold (best tools do this without a human).
- **Manual, one-click** — operator picks a previous version from history and redeploys it.
- **Git-revert-based** — in GitOps, rollback is just reverting the git commit; the reconciler does the rest.

When you evaluate any CD tool (including your new product), ask: which of these strategies does it support
natively vs. require you to bolt on via scripts, and what's the actual rollback latency.
