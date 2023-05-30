# FROM ubuntu:22.04 AS terraform_binary
#
# WORKDIR /download
#
# RUN apt-get update -y && apt-get install -y wget unzip
#
# RUN wget https://releases.hashicorp.com/terraform/1.4.6/terraform_1.4.6_linux_amd64.zip
# RUN ls -la
#
# RUN unzip /download/terraform_1.4.6_linux_amd64.zip
# RUN ls -la


# wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
#
# wget -O- https://apt.releases.hashicorp.com/gpg | \
# gpg --dearmor | \
# sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg


FROM debian:11.7-slim
# python:3.11.2-alpine3.17
WORKDIR /yaook-k8s
# RUN apk add openssh && apk add sshpass
# COPY --from=terraform_binary /download/terraform /usr/local/bin


RUN DEBIAN_FRONTEND=noninteractive apt-get update -y && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-wheel openssh-client jsonnet git-crypt curl gnupg2

RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-keyring.gpg && \
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-keyring.gpg] https://apt.releases.hashicorp.com bullseye main" > /etc/apt/sources.list.d/hashicorp.list && \
  apt-get update && apt-get install -y terraform vault

# Install helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
  chmod 700 get_helm.sh && \
  ./get_helm.sh

RUN curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && apt-get install -y kubectl

COPY . .
RUN ls -la
RUN pip3 install --no-cache-dir -r requirements.txt

RUN ansible-galaxy install -r ansible/requirements.yaml

# RUN python3 -m pip install --user ansible

RUN terraform --version
RUN ansible --version

CMD ["./actions/apply.sh"]

# # Install ansible galaxy requirements
# RUN curl -fsSl -o galaxy_requirements.yaml https://gitlab.com/yaook/k8s/-/raw/devel/ansible/requirements.yaml && \
#   ansible-galaxy install -r galaxy_requirements.yaml
#
# # Install jsonnet-bundler
# ENV GO111MODULE=on
# RUN go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@latest
# ENV PATH=$PATH:/usr/lib/go/bin:/root/go/bin
#
#
#
#
# # Install Terraform and Vault
# RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-keyring.gpg && \
#   echo "deb [signed-by=/usr/share/keyrings/hashicorp-keyring.gpg] https://apt.releases.hashicorp.com bullseye main" > /etc/apt/sources.list.d/hashicorp.list && \
#   apt-get update && apt-get install -y terraform vault && \
#   setcap -r /usr/bin/vault
#
# # Install kubectl
# RUN curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg && \
# echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list && \
# apt-get update && apt-get install -y kubectl
#
# ###
#
#
# 1
# RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends software-properties-common \
#   locales python3-pip make moreutils git openssh-client wget ca-certificates jq python3-setuptools curl unzip \
#   python3-wheel iproute2 iputils-ping netcat-openbsd pass golang apt-transport-https wireguard-tools \
#   jsonnet git-crypt && \
#   python3 -m pip install -U pip
#
# # Install python requirements.txt
# RUN curl -fsSl -o yk8s_requirements.txt https://gitlab.com/yaook/k8s/-/raw/devel/requirements.txt && \
#   python3 -m pip install -r yk8s_requirements.txt && \
#   python3 -m pip install -r /tmp/requirements.txt && \
#   rm -rf /root/.cache
#