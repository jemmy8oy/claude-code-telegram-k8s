# Claude Code Telegram Bot

A Telegram bot that integrates with Claude Code CLI, deployed on Oracle Kubernetes Engine (OKE) via Helm.

## CI/CD: GitHub Actions → OCIR

This repo uses GitHub Actions to automatically build and push the Docker image to Oracle Container Image Registry (OCIR) on every push to `main`.

### Required GitHub Secrets

Go to your repository → **Settings → Secrets and variables → Actions → New repository secret** and add the following:

| Secret | Description | Example |
|--------|-------------|---------|
| `OCIR_REGISTRY` | OCIR regional endpoint | `lhr.ocir.io` |
| `OCIR_NAMESPACE` | OCI tenancy namespace (object storage namespace) | `lr7uc6l49odc` |
| `OCIR_USERNAME` | Full OCIR login username (see note below) | `lr7uc6l49odc/oracleidentitycloudservice/user@example.com` |
| `OCIR_AUTH_TOKEN` | OCI Auth Token (not your account password) | *(generated in OCI Console)* |

#### Finding your OCIR username

Your OCIR username depends on how you log in to OCI:

- **Federated users** (Oracle Identity Cloud Service / SSO):
  ```
  <tenancy-namespace>/oracleidentitycloudservice/<username-or-email>
  ```
- **Local OCI users** (non-federated):
  ```
  <tenancy-namespace>/<username>
  ```

To find your tenancy namespace: OCI Console → Profile (top right) → Tenancy → **Object Storage Namespace**.

#### Generating an OCI Auth Token

1. OCI Console → Profile (top right) → **My profile** (or **User Settings**)
2. Under **Resources** → **Auth tokens** → **Generate token**
3. Give it a description (e.g. `github-actions-ocir`) and copy the token immediately — it won't be shown again
4. Use this token as the `OCIR_AUTH_TOKEN` secret

### Workflow behaviour

- Pushes to `main` trigger a build
- Two tags are pushed: `:latest` and `:<git-sha>` for traceability
- Build cache is stored in GitHub Actions cache to speed up subsequent builds
- You can also trigger a build manually via **Actions → Run workflow**

---

## Helm Deployment

The `values.yaml` in `claude-code-telegram-helm/` uses a placeholder for the image repository. Override it at deploy time:

```bash
helm upgrade --install claude-code-telegram ./claude-code-telegram-helm \
  --set image.repository=lhr.ocir.io/<your-tenancy-namespace>/claude-code-telegram \
  --set image.tag=latest \
  --namespace default
```

### Kubernetes Secrets

The bot requires the following Kubernetes secrets in your cluster before deploying:

**`bot-secrets`** — Telegram bot credentials and GitHub App details:
```bash
kubectl create secret generic bot-secrets \
  --from-literal=TELEGRAM_BOT_TOKEN=<your-telegram-bot-token> \
  --from-literal=ALLOWED_USERS=<comma-separated-user-ids> \
  --from-literal=GH_APP_ID=<your-github-app-id> \
  --from-literal=GH_INSTALLATION_ID=<your-github-installation-id>
```

**`github-app-key`** — GitHub App private key (PEM file):
```bash
kubectl create secret generic github-app-key \
  --from-file=private-key.pem=<path-to-your-pem-file>
```

---

## Architecture

- **Bot**: Python 3.11, communicates via Telegram API
- **AI**: Claude Code CLI (`@anthropic-ai/claude-code`)
- **GitHub integration**: GitHub CLI (`gh`) + GitHub App authentication
- **Deployment**: Kubernetes StatefulSet (OKE) with 50Gi persistent block volume
- **Registry**: Oracle Container Image Registry (OCIR)
