---
applyTo: ".github/workflows/**/*.yml,.github/workflows/**/*.yaml"
---

# GitHub Actions Security Instructions

Apply these rules to workflow definitions (`lint.yml`, `molecule.yml`, `issues.yml`, `scorecards.yml`,
`dependency-review.yml`, `slsa.yml`).

## Security-first workflow design
- Use least-privilege `permissions` at workflow/job scope; avoid implicit broad defaults (all current
  workflows set `permissions: contents: read` at the top level — keep new/edited jobs consistent with
  that, only widening a specific job when strictly required, as `slsa.yml`'s release job does for
  `contents: write`).
- Keep triggers narrow (`branches`, `paths`, event types) and avoid unnecessary execution scope.
- Pin third-party actions to a commit SHA (existing pattern: `uses: owner/action@<sha> # vX.Y.Z`) —
  never introduce an unpinned `@main`/`@vX` reference for a third-party action.
- Treat all PR metadata, issue content, artifact contents, and external inputs as untrusted.
- Keep `step-security/harden-runner` as the first step of every job, as done throughout this repo.

## Secrets and token handling
- Never hardcode secrets or tokens.
- Use GitHub secrets/variables and mask sensitive output.
- Avoid printing env/context objects that may contain credentials.
- Minimize `GITHUB_TOKEN` privileges and step exposure.

## High-risk event and runner handling
- Use extreme caution with `pull_request_target` and `workflow_run`; never execute untrusted code with
  elevated context. This repo currently uses only `pull_request`, `push`, `schedule`, and
  `workflow_dispatch` — do not switch to `pull_request_target` without a clear, documented need.
- Validate artifact provenance before reuse; avoid cross-trust artifact promotion. Be especially
  careful in `slsa.yml`, which produces the release provenance consumers rely on.
- Treat caches as potentially attacker-influenced; scope keys defensively.

## Reliability and safety defaults
- Set explicit `timeout-minutes` on new jobs.
- Use `concurrency` to prevent unsafe overlap when a workflow has deployment/release side effects
  (notably `slsa.yml`).
- Keep scripts short, fail-fast, and explicit (`set -euo pipefail` for bash steps where appropriate).
- Avoid curl-pipe-to-shell patterns; download, verify, then execute — mirror the checksum-verification
  discipline used for Docker/Compose binaries in `get_latest_release.sh` and `defaults/main.yml`.

## Review priorities
1. Privilege model (`permissions`, token use, OIDC/release scope in `slsa.yml`)
2. Trigger safety and untrusted input handling
3. Third-party dependency trust (pinning, provenance)
4. Secret exposure risks in logs, outputs, artifacts, and caches
5. Runner isolation and escalation paths

## Risk levels
- Critical: direct secret exfiltration path or untrusted-code execution in privileged context
- High: broad token permissions, unsafe event usage, or unpinned high-trust action usage
- Medium: missing safety controls (`timeout-minutes`, `concurrency`, validation gaps)
- Low: style/maintainability issues with limited security impact
