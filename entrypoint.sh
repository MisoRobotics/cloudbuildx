#!/usr/bin/env sh

# Copyright (c) 2022 Miso Robotics, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# This script is intended for use on Google Cloud Build.
network=cloudbuild
binfmt_version=v0.8
buildkit_version=v0.10.3

run_args="--privileged"
driver_opts="image=moby/buildkit:${buildkit_version}"

if [ -n "${network}" ]; then
	run_args="${run_args} --network=${network}"
	driver_opts="${driver_opts},network=${network}"
fi

if [ -n "${MULTIARCH}" ]; then
	echo "Running user mode emulation of selected binfmt(s) with QEMU."
	docker run ${run_args} "linuxkit/binfmt:${binfmt_version}"
	docker run ${run_args} --rm multiarch/qemu-user-static --reset -p yes
fi

echo "Creating BuildKit builder on ${network} network."
export DOCKER_BUILDKIT=1 DOCKER_CLI_EXPERIMENTAL=enabled
buildx create --use --name=mybuilder --driver-opt="${driver_opts}" \
	--buildkitd-flags '--allow-insecure-entitlement network.host'
buildx inspect --bootstrap

# Buildkit creates the builder on the cloudbuild network, so use host-mode
# networking to reuse the network stack of the builder container.
# When invoking build, explicitly pass the address of the GCE Metadata service
# because otherwise it ends up with the wrong address which does resolve but
# does not authenticate properly.
metadata_host=metadata.google.internal
metadata_ip="$(dig +short "${metadata_host}")"

if [ -z "${DISABLE_SSH}" ]; then
	if [ -n "${SSH_SECRET_ID}" ]; then
		args="--secret=${SSH_SECRET_ID}"
		if [ -n "${SSH_SECRET_PROJECT}" ]; then
			args="${args} --project=${SSH_SECRET_PROJECT}"
		fi
		mkdir -m0700 -p ~/.ssh
		gcloud secrets versions access latest ${args} > ~/.ssh/id_rsa
		chmod 400 ~/.ssh/id_rsa
	fi

	if [ -z "${SSH_AUTH_SOCK}" ]; then
		echo "Instantiating ssh-agent and adding default key."
		eval "$(ssh-agent -s)"
		ssh-add ~/.ssh/id_rsa
	fi

	ssh_args="--ssh=default"
fi

echo "Invoking docker build with host entry ${metadata_host}:${metadata_ip}"
buildx build \
	--add-host "${metadata_host}:${metadata_ip}" \
	"${ssh_args}" --allow=network.host --network=host "$@"
