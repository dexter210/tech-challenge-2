# GitOps Deployment | GitHub Actions + Argo CD

This branch contains the **GitOps deployment path** for the [AWS EKS Tech Challenge 2 portfolio](../../tree/main). The [main README](../../blob/main/README.md) contains the complete architecture, Terraform provisioning, Jenkins CI/CD walkthrough, test results, and [screenshots](../../tree/main/screenshots).

## Deployment workflow

1. A source change to `app.py`, `requirements.txt`, `Dockerfile`, or the workflow on the `gitops` branch triggers [GitHub Actions](.github/workflows/build-ecr.yml). The workflow also supports manual dispatch.
2. GitHub Actions assumes an AWS IAM role using **OIDC**; no long-lived AWS access key is required in the workflow.
3. The job builds the Docker image, pushes a versioned image to **Amazon ECR**, and updates the image tag in [`values-gitops.yaml`](helm/tech-challenge-2/values-gitops.yaml).
4. **Argo CD** tracks the `gitops` branch and Helm chart, synchronizing the `hello-gitops` release in the `gitops-demo` namespace.
5. The application is validated with `kubectl rollout status` and local port forwarding. This GitOps release deliberately disables the public ingress.

## Files

| File | Purpose |
| --- | --- |
| [`.github/workflows/build-ecr.yml`](.github/workflows/build-ecr.yml) | OIDC-authenticated image build, ECR push, and tag update |
| [`terraform/github-actions-iam.tf`](terraform/github-actions-iam.tf) | Restricted IAM role and ECR permissions for the GitOps workflow |
| [`helm/tech-challenge-2/values-gitops.yaml`](helm/tech-challenge-2/values-gitops.yaml) | Image version and GitOps ingress configuration |
| [`helm/tech-challenge-2/`](helm/tech-challenge-2/) | Helm deployment and autoscaling resources |

## Validate the GitOps release

```sh
kubectl get deployment hello-gitops -n gitops-demo
kubectl rollout status deployment/hello-gitops -n gitops-demo
kubectl get hpa -n gitops-demo
kubectl port-forward -n gitops-demo service/hello-gitops 8083:80
```

Open `http://localhost:8083` while port forwarding is running. Stop forwarding with **Ctrl+C**.

## Environment and security notes

This is a documented **lab**, not a continuously hosted live service. Recreating it requires AWS, EKS, Argo CD, a matching IAM OIDC configuration, and a GitHub Actions repository variable named `AWS_ROLE_ARN`. The role's trust policy must match the GitHub OIDC subject configuration for your repository. Do not commit AWS keys, Terraform state, passwords, or live credentials.

**[Read the complete project walkthrough and view deployment evidence on main →](../../blob/main/README.md)**
