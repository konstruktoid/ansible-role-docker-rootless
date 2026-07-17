# Repository Instructions for GitHub Copilot

This repository is a single Ansible role (`konstruktoid.docker_rootless`) that installs and
configures a Docker daemon running rootless, with optional rootful support. Prefer secure-by-default,
operationally reliable, maintainable, and auditable changes.

## Mission and baseline
- Preserve rootless-first security intent unless an explicit deviation is requested.
- Keep rootful support (`docker_rootful`) an explicit opt-in, never a silent default.
- Bias recommendations toward the upstream [Docker rootless mode](https://docs.docker.com/engine/security/rootless/)
  hardening guidance (user namespaces, subuid/subgid ranges, `user.max_user_namespaces`, restrictive
  `daemon.json`, AppArmor confinement).
- Prefer minimal, reviewable, reversible diffs.

## Engineering expectations
- Use declarative, idempotent Ansible solutions.
- Prefer built-in and well-supported modules over ad hoc shell/command usage.
- Use clear task names, explicit conditions, and deterministic behavior.
- Favor maintainability over clever one-liners.
- Binary downloads (Docker, Compose) must keep checksum verification against the `shasums` values in
  `defaults/main.yml` — never fetch and install a release without verifying it.

## Security requirements
- Enforce least privilege; do not broaden `become`/`become_user` scope without need. Most Docker
  operations should run as `docker_user`, not root.
- Use restrictive ownership and permissions by default (see `daemon.json`, systemd unit files,
  `docker_rootless.sh`, subuid/subgid entries).
- Never hardcode secrets, credentials, keys, tokens, or passwords.
- Treat these as high-sensitivity areas: the `docker_user` account and its subuid/subgid ranges,
  sysctl values (`docker_sysctl_file`, `user.max_user_namespaces`), systemd service units
  (`docker_rootless.service`, `docker_rootful.service`), AppArmor profiles, and anything that toggles
  `docker_rootful`, `docker_allow_privileged_ports`, or `docker_allow_ping`.
- Avoid security relaxations (privileged ports, ping/raw sockets, rootful mode, permissive
  `daemon.json` options) unless explicitly requested and documented.

## Preferred patterns
- Module-first authoring (`ansible.builtin.*`, `ansible.posix.*`, `community.docker.*`,
  `community.general.*`, `community.crypto.*` per `requirements.yml`).
- Always use the fully-qualified collection name (FQCN) for every module, with no exceptions in this
  codebase.
- Explicit `owner`, `group`, and quoted octal string `mode` values (for example `mode: "0640"`) for
  managed files.
- Double-quoted YAML strings; use single quotes only when the value itself contains a double quote.
- Variable names prefixed `docker_` in `defaults/main.yml`, matching existing convention.
- Handlers (`handlers/main.yml`) for restart/reload on config changes, scoped to the user systemd
  instance for rootless services.
- Keep `meta/main.yml` `galaxy_info.platforms` accurate for any OS-conditional task logic.

## Discouraged patterns
- `shell`/`command` when an Ansible module exists.
- Non-idempotent logic without proper guards.
- Broad network exposure, permissive firewall/`daemon.json` rules, or world-writable modes.
- Implicit behavior that reduces auditability.
- Skipping checksum verification on downloaded binaries.

## Docker security posture guidance
- Prefer rootless execution, reduced attack surface, and least functionality.
- Keep user namespace remapping, subuid/subgid allocation, and sysctl enforcement explicit.
- Do not weaken rootless isolation or enable rootful/privileged-port/ping defaults silently.

## Template and Jinja guidance
- Keep templates (`templates/*.j2`) deterministic and explicit.
- Do not embed secrets in templates.
- Avoid permissive fallback values unless explicitly required.

## Testing and validation
- Changes must pass `ansible-lint` at `profile: production` (see `.ansible-lint`); do not silence
  findings introduced by new work.
- Validate role changes with `tox -e docker` (installs `requirements.yml`, runs `ansible-lint`, then
  `molecule test -s docker` across almalinux10, ubuntu resolute, and debian trixie containers,
  including an idempotence check).
- The `molecule/default` scenario boots QEMU/UEFI cloud images (no Vagrant/VirtualBox) and requires
  `qemu-system-x86_64`, `qemu-img`, `genisoimage`, and OVMF firmware on the host; it is not exercised
  by CI (`.github/workflows/molecule.yml` only runs the `docker` scenario) and depends on host
  virtualization support, so treat local failures there as environment-dependent rather than assuming
  role code is at fault.
- On some local/dev machines, `tox -e docker` / `molecule test -s docker` itself fails at the
  container-`create` step with a `community.docker`-driver/`runc` error unrelated to role content —
  a known pre-existing local environment issue, not a regression from role changes. `ansible-lint`
  (production profile) remains the reliable fast local check in that case; let CI provide the
  authoritative pass/fail for the `docker` scenario.
- Prefer fixing lint/test failures over suppressing them; treat suppression as a last resort requiring
  justification.

## Documentation guidance
- Explain security rationale and operational impact for sensitive changes.
- Note compatibility tradeoffs and any intentional deviation from rootless-first intent.
- Keep the README's "Role Variables with defaults" block in sync with `defaults/main.yml`.

## Review expectations
Prioritize findings on:
- security misconfiguration,
- privilege escalation (rootful opt-in, `become` scope),
- file ownership/mode,
- idempotency,
- unsafe module choice,
- missing checksum verification on downloaded binaries,
- exposure via privileged ports, ping, or permissive `daemon.json` options.

For meaningful findings, provide: Finding, Risk (Critical/High/Medium/Low), Location, Recommendation,
and safer example as a short code snippet.

## Change safety rules
- Do not remove or weaken rootless isolation without explicit instruction.
- Do not silently broaden access or reduce enforcement (e.g. flipping `docker_rootful`,
  `docker_allow_privileged_ports`, or `docker_allow_ping` defaults).
- Flag high-impact changes affecting the Docker daemon's privilege model, systemd service definitions,
  or the user namespace/sysctl configuration.
