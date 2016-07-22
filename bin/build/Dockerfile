FROM buildpack-deps:jessie-scm
MAINTAINER Marat Garafutdinov <marat.g@samsung.com>

ENV TERRAFORM_VERSION=0.6.16 \
    TERRAFORM_EXECUTE_VERSION=v0.0.2 \
    TERRAFORM_COREOSBOX_VERSION=v0.0.1 \
    KUBERNETES_VERSION=v1.2.5

# system dependencies
RUN apt-get update \
    && apt-get install -y --force-yes \
      build-essential \
      curl \
      jq \
      libffi-dev \
      python-dev \
      python-pip \
      python-yaml \
      openssh-client \
      libssl-dev \
      unzip \
      vim \
      apt-transport-https \
      ca-certificates \
      socat

# docker repo keys
RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 \
      --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

# Add docker repo
RUN echo "deb https://apt.dockerproject.org/repo debian-jessie main" > /etc/apt/sources.list.d/docker.list

# Install docker
RUN apt-get update \
    && apt-get install -y --force-yes \
    docker-engine \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# python dependencies
COPY bin/build/requirements.txt /tmp/requirements.txt
RUN pip install --upgrade --requirement /tmp/requirements.txt \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# terraform and custom providers
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && wget https://github.com/samsung-cnct/terraform-provider-execute/releases/download/${TERRAFORM_EXECUTE_VERSION}/terraform-provider-execute_linux_amd64.tar.gz \
    && wget https://github.com/samsung-cnct/terraform-provider-coreosbox/releases/download/${TERRAFORM_COREOSBOX_VERSION}/terraform-provider-coreosbox_linux_amd64.tar.gz \
    && unzip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin \
    && tar -xvf terraform-provider-coreosbox_linux_amd64.tar.gz \
    && tar -xvf terraform-provider-execute_linux_amd64.tar.gz \
    && cp terraform* /usr/local/bin \
    && rm terraform*

# kubectl
RUN wget https://github.com/GoogleCloudPlatform/kubernetes/releases/download/${KUBERNETES_VERSION}/kubernetes.tar.gz \
    && tar -xvf kubernetes.tar.gz \
    && cp kubernetes/platforms/linux/amd64/kubectl /usr/bin \
    && rm kubernetes.tar.gz

# generate a keypair
RUN ssh-keygen -q -t rsa -N '' -f /root/.ssh/id_rsa

COPY ansible/build/ansible.cfg /etc/ansible/ansible.cfg
COPY ansible /opt/kraken/ansible/
COPY terraform /opt/kraken/terraform
COPY hack /opt/kraken/hack
COPY bin/build/*.sh /opt/kraken/
