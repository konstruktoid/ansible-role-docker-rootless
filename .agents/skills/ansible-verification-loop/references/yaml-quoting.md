<!--
Vendored from https://github.com/konstruktoid/agent-instructions-skills
skills/ansible/ansible-verification-loop/references/yaml-quoting.md
Upstream commit: 4983695a16ac349dfcac90c4ab27c86d272c2d6e
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

- YAML 1.2.2's core schema resolves only `true` and `false`, in any capitalization, as
  booleans. The rest of the "Norway problem" family, unquoted `yes`, `no`, `on`, `off`,
  `y`, and `n`, is YAML 1.1 behavior that many loaders still implement.
- Ansible reads YAML through PyYAML, which follows YAML 1.1, so those spellings do become
  booleans in a playbook even though YAML 1.2.2 leaves them as strings. Quote them
  wherever the string is what is wanted.
- Numbers with leading zeros resolve to octal, and values with embedded colons to
  sexagesimal integers, under YAML 1.1. YAML 1.2.2 drops both: `012` is the integer 12 and
  `12:30` is a string. Quote them so the value does not change meaning with the loader.

## Relationship to the repository's linters

Ansible's YAML loader accepts unquoted `yes`, `no`, `on`, and `off` rather than rejecting
them, which is exactly why the lint rule exists: `ansible-lint`'s default `yaml`/`truthy`
rule requires `true`/`false` and flags the other spellings. The specification explains why
that rule is there; it does not replace it.

Never use the specification to justify removing existing quoting, the `---`
document-start marker, or any other convention that `ansible-lint` or `yamllint`
already enforces in the target repository. The repository's configured linters win.
