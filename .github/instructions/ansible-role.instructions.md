---
applyTo: "{tasks,handlers,defaults,vars,meta}/**/*.{yml,yaml},templates/**/*.j2"
---

# Docker Rootless Role Instructions

Apply these rules to Ansible YAML and Jinja changes in this role.

## Authoring priorities
- Module-first implementation; avoid `shell`/`command` unless no safe module exists (existing
  exceptions such as the `dockerd` process check in `molecule/default/verify.yml` are acceptable
  precedent, not a license to add more).
- Always use the fully-qualified collection name (FQCN, for example `ansible.builtin.lineinfile`,
  `community.docker.docker_container`) for every module call.
- Declarative, idempotent tasks with descriptive names.
- Explicit `owner`, `group`, and restrictive quoted octal string `mode` values (for example
  `mode: "0640"`) for managed files.
- Double-quoted YAML strings; variables prefixed `docker_` (for example `docker_sysctl_file`,
  `docker_rootless_service_template`), matching `defaults/main.yml`.
- Restrictive defaults in `defaults/main.yml`/templates: rootless-only, no privileged ports, no ping,
  no rootful mode, unless a variable is explicitly flipped by the consumer.
- Handlers (`handlers/main.yml`) for config-driven restart/reload behavior — keep rootless handlers
  scoped with `become_user: "{{ docker_user }}"` and `scope: user` on `systemd_service`.
- Any change to OS-conditional task logic (`tasks/*.yml` using `ansible_facts.os_family` /
  `ansible_facts.distribution`) must keep `meta/main.yml` `galaxy_info.platforms` accurate.
- New or changed release binaries must update the matching entry under `shasums:` in
  `defaults/main.yml` and keep checksum verification in the download task.

## Conservative security handling
Treat these domains as high sensitivity and change conservatively:
- The `docker_user` account, its creation (`tasks/manage_user.yml`), and subuid/subgid ranges.
- sysctl/kernel tuning (`docker_sysctl_file`, `user.max_user_namespaces`) in `tasks/pre.yml`.
- systemd service units (`docker_rootless.service`, `docker_rootful.service`) and their scope
  (user vs. system).
- AppArmor profiles (`apparmor_rootlesskit.j2`, `apparmor_unprivileged_userns.j2`).
- `daemon.json` contents and anything toggling `docker_rootful`,
  `docker_allow_privileged_ports`, or `docker_allow_ping`.
- Binary download/verification logic (`get_latest_release.sh`, checksum comparisons against
  `shasums`).

## Compliance-aware behavior
- Favor patterns aligned with Docker's own rootless-mode security guidance and general least-privilege
  container-host hardening.
- Improve auditability, traceability, and enforcement consistency.
- Reference exact upstream Docker documentation or CVEs only when verified in repository context;
  otherwise cite likely risk areas and rationale.

## Review priorities
1. Security regression or weakening of rootless isolation
2. Over-privileged execution (`become`, rootful opt-in, broad permissions)
3. Non-idempotent logic or risky shell pipelines
4. Missing explicit ownership/mode on sensitive files, or missing checksum verification on downloads
5. Operational reliability issues (unsafe restarts, brittle conditions, missing handler)

## Risk levels
- Critical: clear security bypass, credential exposure, or severe privilege expansion (e.g. silently
  defaulting to rootful, disabling checksum verification)
- High: significant rootless-isolation regression or broad exposure (privileged ports, ping enabled
  by default)
- Medium: moderate hardening gap or reliability risk
- Low: maintainability/readability issue with minimal security impact
