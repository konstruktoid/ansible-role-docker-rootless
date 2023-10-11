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
>
> There is a [SLSA](https://slsa.dev/) artifact present under the
> [slsa action workflow](https://github.com/konstruktoid/ansible-role-docker-rootless/actions/workflows/slsa.yml)
> for verification.

## Requirements

None.

## Playbook example

```yaml
---
- hosts: all
  any_errors_fatal: true
  tasks:
    - name: Include the konstruktoid.docker_rootless role
      ansible.builtin.include_role:
        name: konstruktoid.docker_rootless
```

## Role Variables with defaults

```yaml
---
docker_add_alias: true
docker_allow_ping: false
docker_allow_privileged_ports: false
docker_bash_completion_shasum: cd9c70120bc5f7e6772b6a5350abf63099004c357814abc8a8a3689a7f2e3df0
docker_compose_bash_completion_shasum: 9926c945b466fad570ad574089d6a90f7d9ba452a2d6a8ba67611a664707f0de
docker_compose: false
docker_compose_release: 2.22.0
docker_compose_release_shasum: e849450f1c5c20123aa7d63291e2a818b7a117f2e03e432853ece463dd09e67a
docker_daemon_json_template: daemon.json.j2
docker_release: 24.0.6
docker_release_rootless_shasum: 4282750458fcae75351a95bbcf7762fb117035fd0ee2663dfc3ad8280627984c
docker_release_shasum: 99792dec613df93169a118b05312a722a63604b868e4c941b1b436abcf3bb70f
docker_repository_template: docker.repo.j2
docker_rootful_enabled: false
docker_rootful: false
docker_rootful_opts: false
docker_rootful_service_template: docker_rootful.service.j2
docker_rootless_script_template: docker_rootless.sh.j2
docker_rootless_service_template: docker_rootless.service.j2
docker_service_restart: true
docker_url: https://download.docker.com/linux/static/stable/x86_64
docker_user_bashrc: false
docker_user: dockeruser
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

`docker_service_restart` will restart the rootless service after the Docker
binaries has been extracted. This may affect any running containers.

Using `docker_rootful: true` and `docker_rootful_enabled: true`, will result in
a standard Docker installation, with an additional Docker daemon, running as a
non-root user.

> Note that Debian 10 and earlier requires `docker_rootful: false` due to missing
dependencies.

The `docker_url`, `docker_release`, and `docker_compose_release`
variables defines where you find the relevant binaries and which version you
should use when doing a manual installation.

You define the name of the Docker user that will be created with the
`docker_user` variable. This user will download and install the binaries if
`docker_rootful: false` or else the user will be the one running the
rootless installation script and starting a isolated daemon.

> Note that the sole purpose of the `docker_user` is to run the Docker
daemon and related containers, and not for system administration or used as a
regular user.

`docker_release_shasum`, `docker_release_rootless_shasum`,
`docker_compose_release_shasum` and `docker_bash_completion_shasum`
are used to verify the files when downloaded using the [get_url](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/get_url_module.html)
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
will be installed.

If `docker_user_bashrc: true`, a .bashrc with completion for the `docker`  and
`docker-compose command will be placed inside the `docker_user` home.

The `docker_allow_privileged_ports` variable configures if exposing
[privileged ports (< 1024)](https://docs.docker.com/engine/security/rootless/#exposing-privileged-ports)
is allowed.

The `docker_allow_ping` variable configures if unprivileged users can open
[ICMP echo sockets](https://docs.docker.com/engine/security/rootless/#routing-ping-packets).
On some distributions, this is not allowed, and thereby containers cannot ping
to the outside.

The variables named `\*\_template` are the locations of the
[templates](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/template_module.html)
in use, this to make it easier to replace them with custom ones.

The most important template is most likely
`docker_daemon_json_template: daemon.json.j2`, which is the location of the
Docker `daemon.json` configuration file template.

## Container management

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
    PATH: "{{ docker_user_info.home }}/bin:{{ ansible_env.PATH }}"
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

## Testing with molecule

If [Ansible Molecule](https://molecule.readthedocs.io/en/latest/)
with the [vagrant plugin](https://github.com/ansible-community/molecule-plugins)
and related software is installed, running `molecule test` is supported.

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
