# Rootless Docker role

An [Ansible](https://www.ansible.com/) role to configure a rootless
[Docker](https://www.docker.com/) server.

```shell
Work In Progress. Soon available as a Ansible role.

Do not use any of this without first testing in a non-operational environment.
```

Note: If you're looking for role examples and documentation, it's available
in the [documentation branch](https://github.com/konstruktoid/ansible-docker-rootless/tree/documentation).

## The Security Layers

> Rootless mode allows running the Docker daemon and containers as a non-root
user to mitigate potential vulnerabilities in the daemon and the container
runtime. ([docker](https://docs.docker.com/engine/security/rootless/))

## The Variables

Before using this role you first have to decide if you want to install Docker
using the packages available to the distribution, also known as the "rootful"
installation since it requires `root` permissions and installs the upstream
Docker daemon or download the static binaries and do a manual install.

If you set `docker_rootful: false` you will download the static binaries and do
a manual install, not requiring any `root` permissions.

The `docker_url` and `docker_release` variables defines where you find the
relevant binaries and which version you should use when doing a manual
installation.

You define the name of the Docker user that will be created with the
`docker_user` variable. This user will download and install the binaries if
`docker_rootful: false` or else the user will be the one only running the
rootless installation script and starting a isolated daemon.

`docker_release_shasum` and `docker_release_rootless_shasum` are used to verify
the files when downloaded using the [get_url](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/get_url_module.html)
module.

`docker_rootful_opts` is the options to apply to the Docker daemon if
running in rootful mode.

```yaml
docker_release: "20.10.2"
docker_release_rootless_shasum: "4ebdad1d4743ccca68d183fccdb978aa8b62e7b24743fff36099bd29e46380e0"
docker_release_shasum: "97017e32a8ecbdd1826bb3c7b1424303ee0dea3f900d33591b1df5e394ed4eed"
docker_rootful: false
docker_rootful_opts: "--live-restore --icc=false -s overlay2 --default-ulimit nproc=512:1024 --default-ulimit nofile=100:200 -H fd://"
docker_url: "https://download.docker.com/linux/static/stable/x86_64"
docker_user: dockeruser
```

> All tasks, templates and related code are available in this repository and can
be tested and tried using [Ansible Molecule](https://molecule.readthedocs.io/en/latest/)
with the [molecule-vagrant](https://github.com/ansible-community/molecule-vagrant)
plugin.

### User creation and systemd lingering

Using the [user](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/user_module.html)
module the roles creates the `{{ docker_user }}`, and also the `docker_user_registered`
variable. `docker_user_registered` will be used as a easy way to get the
`{{ docker_user }}` environment settings.

> Enabling lingering means that user@.service is started automatically during
boot, even if the user is not logged in, and that the service is not terminated
when the user logs out. Enabling lingering allows the user to run processes
without being logged in. ([systemd-run](https://www.freedesktop.org/software/systemd/man/systemd-run.html))

### User directories

Since you are installing the Docker daemon in a directory owned by
`{{ docker_user }}`, in this example the user home directory, you also
need to create the required Ansible, Docker and systemd directories.

Note that you use `become_user: "{{ docker_user }}"` and the
`{{ docker_user_registered.home }}` variable to create the directories
with the correct ownership and locations.

### Manual Docker installation

After creating the necessary directories you, download the packages defined by
`url: "{{ docker_url }}/docker-{{ docker_release }}.tgz"` and
`url: "{{ docker_url }}/docker-rootless-extras-{{ docker_release }}.tgz"`
and verify them using the [get_url](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/get_url_module.html)
module.

Extracting the downloaded packages are done by the [unarchive](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/unarchive_module.html)
module, with the `{{ docker_user_registered.home }}/bin` directory as a destination.

The rootless Docker systemd service file requires some modifications before the
daemon can be managed. We use the previously created `docker_user_registered`
variable to set the correct environment values and `ExecStart` setting in the
`docker.service` template before rendering the template in the
`{{ docker_user_registered.home }}/.config/systemd/user/`
directory.

```sh
Environment="DOCKER_HOST=unix:///run/user/{{ docker_user_registered.uid }}/docker.sock"
Environment="PATH={{ docker_user_registered.home }}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Environment="XDG_RUNTIME_DIR=/run/user/{{ docker_user_registered.uid }}"
ExecStart="{{ docker_user_registered.home }}/bin/dockerd-rootless.sh"
```

The `docker.service` is enabled and started using the [systemd](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/systemd_module.html)
module. In addition to using `become: 'yes'` and
`become_user: "{{ docker_user }}"`, you need to set `scope: user`.

### Package Docker installation

If you're installing using `apt`, you'll only need to install
the `docker-ce` and `docker-ce-rootless-extras` packages.

After installation, you'll disable the rootful Docker daemon
since our priority is reducing any attack surface and the usage
of `root` privileges.

We then install the rootless Docker daemon as the `{{ docker_user }}` unless
`/run/user/{{ docker_user_registered.uid }}/docker.sock` exists.

After the installation you enable and start the user daemon.

### Container management

Running containers is not that much different from when a rootful Docker daemon
is used, but you still need to become the unprivileged user and adapt any paths
to the user working directory.

## The Result: Running molecule

If [Ansible Molecule](https://molecule.readthedocs.io/en/latest/)
with the [molecule-vagrant](https://github.com/ansible-community/molecule-vagrant)
plugin and related software is installed, running
`molecule test` is supported.

## Contributing

Do you want to contribute? Great! Contributions are always youlcome,
no matter how large or small. If you found something odd, feel free to submit a
issue, improve the code by creating a pull request, or by
[sponsoring this project](https://github.com/sponsors/konstruktoid).

## License

Apache License Version 2.0

## Author Information

[https://github.com/konstruktoid](https://github.com/konstruktoid "github.com/konstruktoid")
