# cloudbuildx

Build multiarch containers on Google Cloud Build with Moby BuildKit, Docker Buildx, and QEMU.

## SSH Agent

By default, this builder starts an SSH agent, adds the default key, and
forwards it to the build step like:

```bash
eval "$(ssh-agent -s)"
ssh-add
docker build --ssh=default
```

You have two options for getting the SSH key.

### Option 1: GCP Secret Manager Service

Store your private key in the
[GCP Secret Manager](https://cloud.google.com/secret-manager) service. Then
pass the secret ID (and optionally a different GCP project ID) through
environment variables like:

```yaml
steps:
  - name: misorobotics/cloudbuildx
    args: [--push, .]
    env:
      - SSH_SECRET_ID=my-secret
      - SSH_SECRET_PROJECT=my-different-project
```

### Option 2: Mount a volume with a key

Obtain a key in a previous step and stick it in a volume. Then mount the
volume to `/root/.ssh` like:

```yaml
steps:
  - name: gcr.io/cloud-builders/gcloud
    entrypoint: bash
    args:
      - -c
      - |
        gcloud secrets versions access latest --secret=my-secret > /secret/id_rsa
        chmod 400 /secret/id_rsa
    volumes: [{ name: ssh, path: /secret }]
  - name: misorobotics/cloudbuildx
    args: [--push, .]
    volumes: [{ name: ssh, path: /root/.ssh }]
```

## Environment Variables

The following environment variables can be set to configure functionality:

- `DISABLE_SSH`: Do not start and forward an SSH agent during build. If this
  parameter is an empty string, then an SSH agent will be started and forwarded
  to Buildkit via the `docker build --ssh=default` option.

- `SSH_SECRET_ID`: If set, obtain the specified secret from the
  [GCP Secret Manager](https://cloud.google.com/secret-manager) service and
  load it into the SSH agent. This option has no effect if `DISABLE_SSH` is
  set.

- `SSH_SECRET_PROJECT`: If set, specify the GCP project when fetching the
  secret.

Note that technically the above shell parameters do not _have_ to be exported
to the environment, but you're probably going to set them using the
[`env`](https://cloud.google.com/build/docs/build-config-file-schema#env) key
in a `cloudbuild.yaml` file.
