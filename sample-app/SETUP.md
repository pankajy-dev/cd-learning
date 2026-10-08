# Running the sample CD pipeline locally

This spins up a real local Jenkins + a local Docker registry, then runs a pipeline that builds one
artifact and promotes it through dev → staging → prod(canary) → prod(full), with a manual approval
gate before prod — i.e., textbook Continuous Delivery.

## Prereqs
- Docker Desktop running
- Nothing else — Node isn't needed on your host, it only runs inside the built image/container

## 1. Start Jenkins + registry

```bash
cd sample-app
docker compose up -d
```

Jenkins takes ~30s to boot. Get the initial admin password:

```bash
docker exec cd-jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Open http://localhost:8080, paste the password, install "Suggested plugins," create your admin user.

## 2. Give the Jenkins container a Docker CLI

The Jenkins image doesn't ship with the `docker` CLI. Install it once (socket is already mounted):

```bash
docker exec -u root cd-jenkins bash -c "apt-get update && apt-get install -y docker.io curl"
```

## 3. Create the pipeline job

- New Item → Pipeline → name it `cd-sample-pipeline`
- Pipeline section → Definition: "Pipeline script from SCM" if you push this repo to git, OR
  for a fast local test, choose "Pipeline script" and paste the contents of `Jenkinsfile.local-paste`
  directly — it's already pre-adjusted for this mode (paths point at `/workspace/...` since there's
  no checkout step), unlike `Jenkinsfile` which uses `sample-app/...` paths for the git-flow case.

## 4. Run it

Click "Build Now." Watch the stage view. It will pause at **"Promote to Prod?"** — this is the
Continuous Delivery gate. Click through it to continue to prod.

## 5. See the result

```bash
curl localhost:3000/health   # dev
curl localhost:3001/health   # staging
curl localhost:3002/health   # prod canary
curl localhost:3003/health   # prod full
```

All four should report the **same** version string (the git SHA/build number) — proof the same
artifact was promoted, not rebuilt, at every stage.

## 6. Experiment (this is the point of the exercise)

- Break the test in `app/server.test.js` and re-run — watch the pipeline stop before anything deploys.
- Remove the `input` step from the Jenkinsfile — now it's Continuous *Deployment*, not Delivery.
- Change `deploy.sh` to deploy to two prod containers and only cut traffic to the new one after a
  health check passes — that's a blue/green deploy by hand.
- Point `smoke-test.sh` at a path that always 500s, watch the stage fail, and manually run
  `deploy.sh prod <previous-image-ref> 3003` — that's what "rollback" actually is at the mechanical level.

## Cleanup

```bash
docker compose down -v
docker rm -f cd-sample-dev cd-sample-staging cd-sample-prod-canary cd-sample-prod 2>/dev/null
```
