---
name: ansible-verification-loop
description: Use this skill when reviewing or modifying this Ansible role's tasks, handlers, defaults, templates, or molecule scenarios.
---

# ansible-verification-loop

## Purpose
Provide a structured approach for reviewing and modifying the `konstruktoid.docker_rootless` role in
this repository. It ensures changes are made consistently, verified thoroughly, and documented
clearly.

## When to use this
- When reviewing or modifying `tasks/`, `handlers/`, `defaults/`, `vars/`, `templates/`, `meta/`, or
  the `molecule/` scenarios.
- When you need to ensure that changes are made consistently and verified thoroughly.

## When NOT to use this
- When making changes that do not involve this role's Ansible content (e.g. only README prose,
  `.github/` workflow tweaks, or repo metadata unrelated to the role's behavior).

## Steps
1. Read `defaults/main.yml`, `tasks/main.yml`, `handlers/main.yml`, and `meta/main.yml` before making
   any changes, plus `requirements.yml` for collection dependencies. `tasks/main.yml` includes the
   other `tasks/*.yml` files conditionally — trace which ones apply to the change (rootless vs.
   rootful, user management, sysctl, bashrc, compose).
2. Follow `.github/copilot-instructions.md` and `.github/instructions/*.instructions.md` — the
   authoritative security/quality rules for this repo (FQCN only, double-quoted strings, quoted
   octal `mode` with explicit `owner`/`group`, `docker_`-prefixed variable names, checksum
   verification on downloaded binaries, treat the `docker_user` account, subuid/subgid, sysctl,
   systemd units, AppArmor profiles, and rootful/privileged-port/ping toggles as high-sensitivity).
3. Read the [YAML 1.2.2 specification](https://yaml.org/spec/1.2.2/) before writing or reviewing
   YAML content — it's the authoritative reference for scalar resolution, quoting, and syntax that
   `ansible-lint`/`yamllint` don't fully enforce. In particular, watch for:
   - Ambiguous plain scalars that the core schema would resolve as boolean/null instead of a string
     (`y`/`n`/`yes`/`no`/`on`/`off`/`null`/`~`) — quote them if a string is intended.
   - Numeric-looking plain scalars that could be misread as int/float/octal/sexagesimal (this repo
     already quotes octal `mode` values, e.g. `mode: "0755"`; keep doing that for any new scalar
     that looks numeric but must stay a string).
   - Tabs used for indentation (YAML block structure requires spaces).
   - Anchors/aliases (`&`/`*`) or explicit tags (`!!`) — this repo currently uses neither; avoid
     introducing them unless there's a clear win, since they reduce readability of task files.
   Do not change quoting/formatting purely for spec-purity if it would fight `ansible-lint`'s
   `production` profile or the repo's `.yamllint`/`.ansible-lint` rules — those take precedence on
   any conflict.
4. Follow the existing conventions and patterns in the codebase: naming, file structure, and style.
5. If OS-conditional logic changes (`ansible_facts.os_family` / `ansible_facts.distribution`
   branches), keep `meta/main.yml` `galaxy_info.platforms` in sync with it.
6. If a `defaults/main.yml` variable is added, renamed, or removed, update the "Role Variables with
   defaults" block in `README.md` to match.
7. If a Docker or Compose release version changes, update the matching `shasums` entry in
   `defaults/main.yml` alongside the version/URL variables.
8. Add or update test coverage for the change:
   - `molecule/default/converge.yml` and `molecule/docker/molecule.yml` (which reuses
     `../default/converge.yml` and `../default/verify.yml`) both exercise this single role — there is
     no per-scenario role split.
   - Extend `molecule/default/verify.yml` with assertions for new/changed behavior (file
     ownership/mode, systemd unit state, sysctl values, container behavior), following the existing
     `ansible.builtin.assert` pattern.
   - If new scenario-specific variables are needed, add them under the relevant host in
     `molecule/default/inventory/host_vars/*/main.yml` (and `molecule/docker/inventory/...` if the
     `docker` scenario needs different values).
9. Verify the change (see checklist below) in a bounded loop. One **attempt** is one full
   fix-and-rerun cycle: apply fixes for the findings from the previous run, then rerun the
   verification commands to completion. Reading output or re-reading a file without changing
   anything is not an attempt.
   - Baseline the loop at 3 attempts.
   - Continue past 3 only while making measurable progress, meaning each cycle ends with strictly
     fewer findings than the one before it.
   - Stop early, before 3 attempts, if the loop is oscillating: the same findings recur, the count
     stops dropping, or a fix for one finding reintroduces another.
   - When stopping for either reason, report to the user rather than proceeding or silently giving
     up. Name the failing check, include its output, and state what was tried.

   Stop at 6 attempts regardless. "Strictly fewer findings" permits an unbounded run when each
   cycle clears one finding out of many, and every cycle here costs a full container converge.
   Count findings per check rather than as one total, since `ansible-lint` and `molecule` report
   unrelated things: progress means the check that failed improved and no other check regressed.
10. Report any issues found during verification, with detailed reproduction steps and relevant
    logs/output. Ansible output is unusually rich in machine detail: play recaps and `--diff` output
    name the target host, gathered facts carry hostnames, interfaces and internal addresses, and
    failure messages quote absolute paths under the invoking user's home. Strip that before pasting
    output anywhere it will be stored, and never commit it into the repository. The same applies to
    anything checked in as a fixture: use `localhost`, `example.com`, or RFC 5737 addresses
    (`192.0.2.0/24`) in inventories, host vars, and templates rather than a real host.

    Machine identifiers are not the only exposure. Ansible output can also carry passwords, API
    tokens, private keys, vaulted or `no_log`-worthy variable values, and credential-bearing URLs:
    `--diff` on a templated secret prints both versions, a failed `uri` or `get_url` task echoes
    its headers, and a verbose module failure dumps the arguments it was called with. Redact those
    before the output is pasted, stored, uploaded as a CI artifact, or attached to an issue, not
    only before it is committed. When a task handles a secret, `no_log: true` is the fix, so that
    there is nothing to redact in the first place.

## Verify
- Run `ansible-lint` and confirm a clean exit / expected output (`profile: production`, see
  `.ansible-lint`). This is the primary quality gate — do not add suppressions to silence findings
  from new changes.
- Run `tox -e docker` and confirm exit code 0. This installs role dependencies (`requirements.yml`),
  runs `ansible-lint`, then invokes `molecule test -s docker` to converge and verify the role in
  containers (almalinux10, ubuntu resolute, debian trixie), including an idempotence check.
- Running `molecule test -s docker` directly skips the dependency install and lint steps that
  `tox -e docker` performs first — run `ansible-galaxy install --force -r requirements.yml` and
  `ansible-lint` yourself beforehand if you use this form instead of `tox`.
- While iterating, use `molecule converge -s docker` / `molecule verify -s docker` instead of the
  full `test` cycle to save time, but always finish with a full `molecule test -s docker`
  (or `tox -e docker`) before declaring the change verified.
- The `molecule/default` scenario (driven by `tox -e devel`/`upstream`) boots QEMU/UEFI cloud images
  (no Vagrant/VirtualBox) and requires `qemu-system-x86_64`, `qemu-img`, `genisoimage`, and OVMF
  firmware on the host. It is not run in CI (`.github/workflows/molecule.yml` only runs `tox -e
  docker` and `tox -e docker-upstream`), so local `create`/`prepare`/`converge` failures there may
  reflect host virtualization support rather than role content — verify host tooling before assuming
  a regression.
- On some local/dev machines, `tox -e docker` / `molecule test -s docker` itself fails at the
  container-`create` step with a `community.docker`-driver/`runc` error unrelated to role content —
  a known pre-existing local environment issue. If that happens, `ansible-lint` (production profile)
  is the reliable fast local check, and CI provides the authoritative pass/fail for the `docker`
  scenario.
- If the change touches release versions or checksums, also sanity-check `get_latest_release.sh`
  still produces matching output for the updated `shasums` entries.

## Verification checklist
Never declare this done based on the edit alone. Confirm each of the following:
- [ ] Lint passes: `ansible-lint`
- [ ] Tests pass: `tox -e docker` / `molecule test -s docker`
- [ ] Idempotence holds (no changes reported on molecule's second converge)
- [ ] `molecule/default/verify.yml` updated if the role's observable behavior changed
- [ ] `molecule/*/inventory/host_vars/*/main.yml` updated if new scenario-specific variables are
      needed
- [ ] `README.md` "Role Variables with defaults" block matches `defaults/main.yml`
- [ ] `shasums` in `defaults/main.yml` updated if a binary release version changed
- [ ] `meta/main.yml` `galaxy_info.platforms` still matches any OS-conditional logic
- [ ] No user or system information committed: inventories, host vars, templates, and any captured
      lint or molecule output use placeholder hosts and addresses, with no real hostname, home
      directory path, username, or internal IP
- [ ] No secrets in anything reported, stored, or uploaded: no passwords, API tokens, private
      keys, vault contents, or credential-bearing URLs in pasted output, CI artifacts, or issue
      attachments, and `no_log: true` set on any task that handles one
- [ ] No unrelated files changed
- [ ] New/changed YAML scalars are unambiguous per the
      [YAML 1.2.2 spec](https://yaml.org/spec/1.2.2/) (no unquoted `y`/`n`/`on`/`off`/`null`-like
      strings, no unquoted numeric-looking strings that must stay strings, no tabs)

## References

- [references/yaml-quoting.md](references/yaml-quoting.md): YAML 1.2.2 scalar resolution and
  quoting, including the "Norway problem". Read it when a change touches quoting in a YAML file,
  or when justifying why a value must stay quoted.
