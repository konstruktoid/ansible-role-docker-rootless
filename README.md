# Docker rootless Ansible role

An [Ansible](https://www.ansible.com/) role to configure install and configure
a [Docker](https://www.docker.com/) daemon running as a non-root user.

```shell
Do not use any of this without first testing in a non-operational environment.
```

Note: If you're looking for role examples and documentation, it's available
in the [documentation branch](https://github.com/konstruktoid/ansible-docker-rootless/tree/documentation).

> Rootless mode allows running the Docker daemon and containers as a non-root
user to mitigate potential vulnerabilities in the daemon and the container
runtime. ([docker](https://docs.docker.com/engine/security/rootless/))

## Requirements

None.

## Playbook example

```yaml
---
- hosts: all
  any_errors_fatal: true
  tasks:
    - include_role:
        name: konstruktoid.docker_rootless
...
```

## Role Variables with defaults

```yaml
docker_add_alias: true
docker_release: "20.10.12"
docker_release_shasum: "ee9b5be14e54bf92f48c82c2e6a83fbdd1c5329e8f247525a9ed2fe90d9f89a5"
docker_release_rootless_shasum: "24b793b79d2cf56e8a63be21829433e079c8d14d18d0b739df2e95738f7f841b"
docker_rootful: false
docker_rootful_enabled: false
docker_rootful_opts: "--live-restore --icc=false --default-ulimit nproc=512:1024 --default-ulimit nofile=100:200 -H fd://"
docker_url: "https://download.docker.com/linux/static/stable/x86_64"
docker_user: dockeruser
docker_allow_privileged_ports: false
```

Before using this role you first have to decide if you want to install Docker
using the packages available to the distribution, also known as the "rootful"
installation since it requires `root` permissions and installs the upstream
Docker daemon or if you want to download the static binaries and do a manual
install.

If you set `docker_rootful: false` you will download the static binaries and do
a manual install, not requiring any `root` permissions.

If `docker_rootful: true`, then `docker_rootful_enabled` will decide if the
daemon should be enabled as a service or not.

Using `docker_rootful: true` and `docker_rootful_enabled: true`, will result in
a standard Docker installation, with an additional Docker daemon, running as a
non-root user.

> Note that Debian 10 and earlier requires `docker_rootful: false` due to missing
dependencies.

The `docker_url` and `docker_release` variables defines where you find the
relevant binaries and which version you should use when doing a manual
installation.

You define the name of the Docker user that will be created with the
`docker_user` variable. This user will download and install the binaries if
`docker_rootful: false` or else the user will be the one running the
rootless installation script and starting a isolated daemon.

> Note that the sole purpose of the `docker_user` is to run the Docker
daemon and related containers, and not for system administration or used as a
regular user.

`docker_release_shasum` and `docker_release_rootless_shasum` are used to verify
the files when downloaded using the [get_url](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/get_url_module.html)
module.

`docker_rootful_opts` is the options to apply to the Docker daemon if
running in rootful mode.

If `docker_add_alias: true`, then a `docker` alias will be added to either `.bashrc`
or `.bash_aliases`, otherwise a shell script named `docker_rootless.sh` is
created in the Ansible user home directory that works as a substitute to the
`docker` command.

The `docker_allow_privileged_ports` variable configures if exposing
[privileged ports (< 1024)](https://docs.docker.com/engine/security/rootless/#exposing-privileged-ports)
is allowed.

## Container management

Running containers is not that much different from when a rootful Docker daemon
is used, but you still need to become the unprivileged user and adapt any paths
to the user working directores.

If `docker_add_alias: true` is used then the `docker` command should be
available as usual for the Ansible user, use `alias` to see the see keyword
configuration.

```yaml
- name: register "{{ docker_user }}" info
  become: 'yes'
  user:
    name: "{{ docker_user }}"
  check_mode: 'yes'
  register: docker_user_info
  tags:
    - user

- name: example container block
  environment:
    XDG_RUNTIME_DIR: "/run/user/{{ docker_user_info.uid }}"
    PATH: "{{ docker_user_info.home }}/bin:{{ ansible_env.PATH }}"
    DOCKER_HOST: "unix:///run/user/{{ docker_user_info.uid }}/docker.sock"
  block:
    - name: nginx container
      become: 'yes'
      become_user: "{{ docker_user }}"
      community.docker.docker_container:
        name: nginx
        image: konstruktoid/nginx
        state: started
        cap_drop: all
        capabilities:
          - chown
          - dac_override
          - net_bind_service
          - setgid
          - setuid
        pull: 'yes'
        hostname: "{{ ansible_nodename }}"
        container_default_behavior: compatibility
```

## Testing with molecule

If [Ansible Molecule](https://molecule.readthedocs.io/en/latest/)
with the [molecule-vagrant](https://github.com/ansible-community/molecule-vagrant)
plugin and related software is installed, running `molecule test` is supported.

## Contributing

Do you want to contribute? Great! Contributions are always youlcome,
no matter how large or small. If you found something odd, feel free to submit a
issue, improve the code by creating a pull request, or by
[sponsoring this project](https://github.com/sponsors/konstruktoid).

## License

Apache License Version 2.0

## Author Information

[https://github.com/konstruktoid](https://github.com/konstruktoid "github.com/konstruktoid")
