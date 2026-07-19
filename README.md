# Docker rootless Ansible role

An [Ansible](https://www.ansible.com/) role to configure install and configure
a [Docker](https://www.docker.com/) daemon running as a non-root user.

```shell
Do not use any of this without first testing in a non-operational environment.
```

> Rootless mode allows running the Docker daemon and containers as a non-root
user to mitigate potential vulnerabilities in the daemon and the container
runtime. ([docker](https://docs.docker.com/engine/security/rootless/))

> **Note**
> There is a [SLSA](https://slsa.dev/) artifact present under the
> [slsa action workflow](https://github.com/konstruktoid/ansible-role-docker-rootless/actions/workflows/slsa.yml)
> for verification.

## Requirements

```yaml
---
roles:
  - name: konstruktoid.docker_rootless
    version: v1.25.0
    src: https://github.com/konstruktoid/ansible-role-docker-rootless.git
    scm: git
```

## Playbook example

```yaml
---
- hosts: all
  any_errors_fatal: true
  tasks:
    - name: Include the konstruktoid.docker_rootless role
      ansible.builtin.import_role:
        name: konstruktoid.docker_rootless
```

## Role Variables with defaults

```yaml
---
configure_sysctl: true
create_docker_user: true
install_dependencies: true

docker_arch: "{{ ansible_facts.architecture }}"
docker_sysctl_file: /etc/sysctl.d/90-docker-rootless.conf
docker_add_alias: true
docker_allow_ping: false
docker_allow_privileged_ports: false
docker_compose: false
docker_compose_release: v5.3.1
docker_compose_url: https://github.com/docker/compose/releases/download
docker_daemon_json_template: daemon.json.j2
docker_driver_network: slirp4netns
docker_driver_port: builtin
docker_migrate_legacy_bin: true
docker_release: 29.6.2
docker_repository_template: docker.repo.j2
docker_rootful_enabled: false
docker_rootful: false
docker_rootful_opts: false
docker_rootful_service_template: docker_rootful.service.j2
docker_rootless_script_template: docker_rootless.sh.j2
docker_rootless_service_template: docker_rootless.service.j2
docker_service_restart: true
docker_unattended_upgrades: false
docker_url: "https://download.docker.com/linux/static/stable/{{ docker_arch }}"
docker_user_bashrc: false
docker_user: dockeruser
docker_user_uid: false
docker_user_gid: false
shasums:
  docker_release:
    aarch64: 8d16d8b3b158c132a9fb9963d4b4345746f925e287e154c9ed880ac257baf292
    x86_64: d6204aea92238e2453d5445c885b9d2e5eb8f82915568ec50edf9dbe12a3ac74
  docker_rootless_release:
    aarch64: 5f5f379166ac52e54941b3fe31e73b0796e20f2628e6a4e82b4863ed52e6751b
    x86_64: 72c863f215d873c251e95f3818f96493d2b733dc66d2c7f154f983091a3a5cd9
  docker_compose_release:
    aarch64: aa611e811d0ea25897839c404bfb5bf93ce706dc51c500a4457890f5d0606a86
    x86_64: f9ebc6ebdb19d769b793c245a736caaeb198c62587f13b25c660c13b4987f959
```

Before using this role you first have to decide if you want to install Docker
using the packages available to the distribution, also known as the "rootful"
installation since it requires `root` permissions and installs the upstream
Docker daemon or if you want to download the static binaries and do a manual
install.

If you run the role on a system without having `root` permissions, you will
need to set `configure_sysctl: false`, `create_docker_user: false` and
`install_dependencies: false` and ensure that the system has the
required dependencies installed and the `docker` user created beforehand.

If you set `docker_rootful: false` you will download the static binaries and do
a manual install, not requiring any `root` permissions.

If `docker_rootful: true`, then `docker_rootful_enabled` will decide if the
daemon should be enabled as a service or not.

`docker_service_restart` will restart the rootless service after the Docker
binaries has been extracted. This may affect any running containers.

Using `docker_rootful: true` and `docker_rootful_enabled: true`, will result in
a standard Docker installation, with an additional Docker daemon, running as a
non-root user.

> Note that Debian 10 and earlier requires `docker_rootful: false` due to missing
dependencies.

The `docker_url`, `docker_release`, `docker_compose_url` and `docker_compose_release`
variables define where you find the relevant binaries and which version you
should use when doing a manual installation.

The `docker` and `docker-compose` binaries, along with the rootless install
scripts, are installed into `~/.local/bin` of the `docker_user`. The legacy
`~/bin` directory is still kept in every `PATH` the role configures, after
`~/.local/bin`, so any binaries or scripts you place there manually continue
to take effect.

If `docker_migrate_legacy_bin: true` (the default), any binaries the role
previously installed into `~/bin` are moved into `~/.local/bin` the first
time the updated role runs against a host, so the Docker binaries end up in
a single location and `~/bin` is left free for your own use. Set it to
`false` to leave the contents of `~/bin` untouched.

You define the name of the Docker user that will be created with the
`docker_user` variable. This user will download and install the binaries if
`docker_rootful: false` or else the user will be the one running the
rootless installation script and starting an isolated daemon. UID and GID
can be set using the `docker_user_uid` and `docker_user_gid` variables.

> Note that the sole purpose of the `docker_user` is to run the Docker
daemon and related containers, and not for system administration or used as a
regular user.

`docker_release_shasum`, `docker_release_rootless_shasum` and
`docker_compose_release_shasum` are used to verify the files when
downloaded using the [get_url](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/get_url_module.html)
module. The `docker_release_shasum` is used for the Docker `.tgz` file and
`docker_release_rootless_shasum` for the `docker-ce-rootless-extras` package.

`docker_rootful_opts` is the options to apply to the Docker daemon if
running in rootful mode, if unset the settings in
`docker_rootful_service_template` will be used.

If `docker_add_alias: true`, then a `docker` alias will be added to either `.bashrc`
or `.bash_aliases` of the Ansible user. If `false`, a shell script named `docker_rootless.sh` is
created in the Ansible user home directory. This works as a substitute to the
`docker` command so that the Ansible user can execute the rootless Docker installation from the `docker_user`.

If `docker_compose: true`, then the Docker `compose` plugin or `docker-compose`
will be installed. `docker_compose_arch` are used to define the architecture of
the `docker-compose` binary.

If `docker_user_bashrc: true`, a .bashrc with completion for the `docker` and
`docker compose` command will be placed inside the `docker_user` home.

If `docker_unattended_upgrades: true` and the `unattended-upgrades` package is installed,
the `docker` and `docker-compose` binaries will be updated automatically.

The `docker_allow_privileged_ports` variable configures if exposing
[privileged ports (< 1024)](https://docs.docker.com/engine/security/rootless/#exposing-privileged-ports)
is allowed.

The `docker_allow_ping` variable configures if unprivileged users can open
[ICMP echo sockets](https://docs.docker.com/engine/security/rootless/#routing-ping-packets).
On some distributions, this is not allowed, and thereby containers cannot ping
to the outside.

The `docker_driver_network` and `docker_driver_port` variables configure RootlessKit's
[network driver](https://github.com/rootless-containers/rootlesskit/blob/master/docs/network.md) or
[port driver](https://github.com/rootless-containers/rootlesskit/blob/master/docs/port.md),
respectively. This is useful for
[optimising network performance](https://docs.docker.com/engine/security/rootless/#networking-errors)
and necessary if
[source IP propagation](https://docs.docker.com/engine/security/rootless/#docker-run--p-does-not-propagate-source-ip-addresses)
is required. By default, the `builtin` port driver does not expose the actual source IP; instead,
all connections appear to the container as originating from the Docker gateway (e.g. 172.19.0.1).
Set `docker_driver_port: slirp4netns` to enable source IP propagation.

The variables named `*_template` are the locations of the
[templates](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/template_module.html)
in use, this to make it easier to replace them with custom ones.

The most important template is most likely
`docker_daemon_json_template: daemon.json.j2`, which is the location of the
Docker `daemon.json` configuration file template.

## Container management

### Standalone container

Running containers is not that much different from when a rootful Docker daemon
is used, but you still need to become the unprivileged user and adapt any paths
to the user working directores.

If `docker_add_alias: true` is used, the `docker` command will be
available as usual for the Ansible user, too. Type `alias` in the shell to see the keyword
configuration.

```yaml
- name: Register Docker user info
  become: true
  ansible.builtin.user:
    name: "{{ docker_user }}"
  check_mode: true
  register: docker_user_info

- name: Example container block
  environment:
    XDG_RUNTIME_DIR: "/run/user/{{ docker_user_info.uid }}"
    PATH: "{{ docker_user_info.home }}/.local/bin:{{ docker_user_info.home }}/bin:{{ ansible_env.PATH }}"
    DOCKER_HOST: "unix:///run/user/{{ docker_user_info.uid }}/docker.sock"
  block:
    - name: Nginx container
      become: true
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
        pull: true
        hostname: "{{ ansible_nodename }}"
        container_default_behavior: compatibility
```

### Docker compose service

```yaml
- name: Register Docker user info
  become: true
  ansible.builtin.user:
    name: "{{ docker_user }}"
  check_mode: true
  register: docker_user_info

- name: Example docker compose block
  become: true
  become_user: "{{ docker_user }}"
  environment:
    XDG_RUNTIME_DIR: /run/user/{{ docker_user_info.uid }}
    PATH: "{{ docker_user_info.home }}/.local/bin:{{ docker_user_info.home }}/bin:{{ ansible_env.PATH }}"
    DOCKER_HOST: "unix:///run/user/{{ docker_user_info.uid }}/docker.sock"
  block:
    - name: Install pip dependencies
      ansible.builtin.pip:
        name:
          - docker<7 # https://github.com/docker/docker-py/issues/3194
          - docker-compose

    - name: Create and start services
      community.docker.docker_compose:
        project_src: /var/tmp/
        files: "{{ docker_user }}-docker-compose.yml"
      register: compose_output
```

## Testing with molecule

If [Ansible Molecule](https://molecule.readthedocs.io/en/latest/)
and related software is installed, running `molecule test` is supported.

Both scenarios use the built-in `default` (driverless) Molecule driver:

- the `default` scenario boots QEMU/UEFI cloud images
  (`almalinux10`, `resolute`, `resoluteroot` and `trixie`) using
  Molecule's ansible-native driver (`driver: name: default`, no
  Docker/Vagrant plugin required), and
- the `docker` scenario provisions containers through the
  `community.docker` collection.

Both converge by running the role, and `verify.yml` checks rootless and
rootful Docker installation, service state, container execution, and
`docker compose`.

```shell
uv pip install ansible-core ansible-lint molecule
ansible-galaxy install --force -r requirements.yml
molecule test
molecule test -s docker
```

The `default` scenario requires `qemu-system-x86_64`, `qemu-img`,
`genisoimage`, and OVMF firmware (`/usr/share/OVMF/OVMF_{CODE,VARS}_4M.fd`)
on the host running the tests; base cloud images are downloaded once and
cached under `~/.cache/molecule-qemu/images`.

`tox -l` will list all available `tox` test environments.

## Contributing

Do you want to contribute? Great! Contributions are always youlcome,
no matter how large or small. If you found something odd, feel free to submit a
issue, improve the code by creating a pull request, or by
[sponsoring this project](https://github.com/sponsors/konstruktoid).

## License

Apache License Version 2.0

## Author Information

[https://github.com/konstruktoid](https://github.com/konstruktoid "github.com/konstruktoid")
