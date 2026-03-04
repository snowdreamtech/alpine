# 11 · Deployment

> Standards for containerization, infrastructure as code, deployment pipelines, and operations.

::: tip Source
This page summarizes [`.agent/rules/11-deployment.md`](https://github.com/snowdreamtech/template/blob/main/.agent/rules/11-deployment.md).
:::

## Containerization (Docker)

All services MUST be containerized. Follow these Dockerfile best practices:

```dockerfile
# ✅ Multi-stage build — minimizes final image size
FROM golang:1.23.4-alpine3.21 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /app/server .

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /app/server /server
USER nonroot
ENTRYPOINT ["/server"]
```

**Rules:**

- Pin base image to exact version digest or tag (never `latest`)
- Use multi-stage builds to minimize attack surface in the final image
- Run containers as non-root users
- Use `distroless` or `alpine` base images for production
- Never include secrets or credentials in image layers

## Infrastructure as Code

All infrastructure MUST be managed as code (IaC):

- **Terraform / OpenTofu** — cloud resources
- **Helm** — Kubernetes workloads
- **Ansible** — configuration management

Rules:

- IaC lives in `infrastructure/` or `deploy/`
- Every change goes through CI/CD — no manual `apply` in production
- Plan output must be reviewed before apply
- Use remote state with locking (S3 + DynamoDB, GCS, Terraform Cloud)

## Deployment Pipeline

```
dev     → test     → staging     → production
```

- Deploys to production require approval gate
- Use blue-green or canary deployment strategy for zero-downtime
- Rollback must be possible within 5 minutes

## Health Checks

Every service must expose:

- `GET /health` → liveness (is the process alive?)
- `GET /ready` → readiness (is the service ready to serve traffic?)

## Observability

All services must implement:

- **Structured logging** (JSON) with correlation IDs
- **Metrics** (Prometheus format): latency p50/p95/p99, error rate, saturation
- **Distributed tracing** (OpenTelemetry)
- **Alerts** for SLO breaches

## Disaster Recovery

- Define RPO (Recovery Point Objective) and RTO (Recovery Time Objective) per service
- Automated database backups with verified restore testing
- Runbooks for each class of incident, stored in `docs/runbooks/`
