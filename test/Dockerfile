FROM gcr.io/cloud-builders/gcloud-slim
RUN curl http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/?recursive=true -H "Metadata-Flavor: Google"
RUN gcloud auth list
RUN gcloud auth list 2>/dev/null | grep "*" >/dev/null 2>&1
