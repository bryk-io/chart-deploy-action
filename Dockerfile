FROM alpine:latest

RUN \
  # kubectl
  wget https://dl.k8s.io/release/v1.24.6/bin/linux/amd64/kubectl -O /usr/bin/kubectl && \
  chmod 755 /usr/bin/kubectl && \
  # helm
  wget https://get.helm.sh/helm-v3.10.1-linux-amd64.tar.gz && \
  tar -xvzf helm-v3.10.1-linux-amd64.tar.gz && \
  mv linux-amd64/helm /usr/bin/. && \
  chmod 755 /usr/bin/helm && \
  rm -rf linux-amd64/ helm-v3.10.1-linux-amd64.tar.gz && \
  # terraform
  wget https://releases.hashicorp.com/terraform/1.3.2/terraform_1.3.2_linux_amd64.zip && \
  unzip terraform_1.3.2_linux_amd64.zip && \
  mv terraform /usr/bin/. && \
  rm terraform_1.3.2_linux_amd64.zip

COPY chart-deploy.sh /bin/chart-deploy
