<!--
Vendored from https://github.com/konstruktoid/agent-instructions-skills
skills/ansible/ansible-verification-loop/references/yaml-quoting.md
Upstream commit: f4696ac18174422ba873bac1630628d49123c7c0
Do not edit locally; re-vendor from upstream instead.
-->

# YAML Quoting and Scalar Resolution

Read this when a change adds, removes, or argues about quoting in a YAML file, or when
explaining to a reviewer why a particular value must stay quoted.

## Authoritative source

The [YAML 1.2.2 Specification](https://yaml.org/spec/1.2.2/) is the authoritative
reference for scalar resolution, quoting, and tag semantics.

## Why values need quoting

Use the specification to explain *why* a value needs quoting, and be precise about which
YAML version resolves what. The difference is the whole reason quoting is needed: a value
whose type depends on the loader is a value that must be quoted.

- YAML 1.2.2's core schema resolves exactly six spellings as booleans: `true`, `True`,
  `TRUE`, `false`, `False`, and `FALSE`. Not every capitalization, so `tRue` is a string.
  The rest of the "Norway problem" family, unquoted `yes`, `no`, `on`, `off`, `y`, and `n`,
  is YAML 1.1 behavior that many loaders still implement.
- Ansible reads YAML through PyYAML, which follows YAML 1.1, so those spellings do become
  booleans in a playbook even though YAML 1.2.2 leaves them as strings. Quote them
  wherever the string is what is wanted.
- YAML 1.1 resolves two numeric forms that YAML 1.2.2 drops, and both are narrower than
  "anything with a leading zero or a colon":
  - Octal is `0` followed by digits `0` to `7`, so `012` is 10 under YAML 1.1 and the
    integer 12 under YAML 1.2.2. A leading zero alone does not do it: `08` and `09` are
    not valid octal and stay strings, and `0x1f` is hexadecimal in both.
  - Sexagesimal is two or more colon-separated groups of digits, the groups after the
    first being `00` to `59`, so `12:30` is 750 under YAML 1.1 and a string under
    YAML 1.2.2. A colon in ordinary text does not do it: `note: 12:ab` stays a string, and
    a mapping's own `key: value` colon is structure rather than a scalar.
  Quote a value in either form so it does not change meaning with the loader.

## Relationship to the repository's linters

Ansible's YAML loader accepts unquoted `yes`, `no`, `on`, and `off` rather than rejecting
them, which is exactly why the lint rule exists: `ansible-lint`'s default `yaml`/`truthy`
rule requires `true`/`false` and flags the other spellings. The specification explains why
that rule is there; it does not replace it.

Never use the specification to justify removing existing quoting, the `---`
document-start marker, or any other convention that `ansible-lint` or `yamllint`
already enforces in the target repository. The repository's configured linters win.
