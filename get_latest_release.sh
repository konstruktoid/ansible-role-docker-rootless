#!/bin/bash

docker_release="$(curl -fsSL https://api.github.com/repos/moby/moby/releases/latest | jq -r '.name' | sed 's/^v//')"
compose_release="$(curl -fsSL https://api.github.com/repos/docker/compose/releases/latest | jq -r '.name')"

archs=("aarch64" "x86_64")
for arch in "${archs[@]}"; do
    temp_dir="$(mktemp -d --suffix=-"${arch}")"
    curl -fsSL "https://download.docker.com/linux/static/stable/${arch}/docker-${docker_release}.tgz" -o "${temp_dir}/docker-${docker_release}.tgz"
    curl -fsSL "https://download.docker.com/linux/static/stable/${arch}/docker-rootless-extras-${docker_release}.tgz" -o "${temp_dir}/docker-rootless-extras-${docker_release}.tgz"

    docker_shasum="$(sha256sum "${temp_dir}/docker-${docker_release}.tgz" | awk '{print $1}')"
    rootless_shasum="$(sha256sum "${temp_dir}/docker-rootless-extras-${docker_release}.tgz" | awk '{print $1}')"
    rm -rf "${temp_dir}"

    if [ "${arch}" == "aarch64" ]; then
        aarch64_docker_shasum="${docker_shasum}"
        aarch64_rootless_shasum="${rootless_shasum}"
    elif [ "${arch}" == "x86_64" ]; then
        x86_64_docker_shasum="${docker_shasum}"
        x86_64_rootless_shasum="${rootless_shasum}"
    fi
done

sed -i "s/docker_compose_release:.*/docker_compose_release: ${compose_release}/" defaults/main.yml
sed -i "s/docker_release:.*/docker_release: ${docker_release}/" defaults/main.yml
sed -i '/shasums:/,$d' defaults/main.yml

echo "shasums:
  docker_release:
    aarch64: ${aarch64_docker_shasum}
    x86_64: ${x86_64_docker_shasum}
  docker_rootless_release:
    aarch64: ${aarch64_rootless_shasum}
    x86_64: ${x86_64_rootless_shasum}
  docker_compose_release:
    aarch64: $(curl -fsSL https://github.com/docker/compose/releases/download/"${compose_release}"/checksums.txt | grep -E "docker-compose-linux-aarch64$" | awk '{print $1}')
    x86_64: $(curl -fsSL https://github.com/docker/compose/releases/download/"${compose_release}"/checksums.txt | grep -E "docker-compose-linux-x86_64$" | awk '{print $1}')" >> defaults/main.yml
