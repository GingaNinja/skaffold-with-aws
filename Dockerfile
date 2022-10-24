FROM --platform=linux/amd64 ubuntu:16.04 as build

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates \
    apt-transport-https \
    gnupg \
    unzip \
    ssh \
    curl \ 
    wget && \
    # curl=7.* \
    # unzip=6.* && \
    # curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    # echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list && \
    # apt-get update && \
    # apt-get install --no-install-recommends -y kubectl=1.21.* && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    # apt-get clean && \
    #rm -rf /var/lib/apt/lists/* && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.2.9.zip" -o "awscliv2.zip" && unzip awscliv2.zip && \
    echo 'c778f4cc55877833679fdd4ae9c94c07d0ac3794d0193da3f18cb14713af615f awscliv2.zip' | sha256sum -c - && \
    curl -Lo skaffold "https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64" && \
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash && \
    curl -Lo terraform.zip https://releases.hashicorp.com/terraform/1.0.5/terraform_1.0.5_linux_amd64.zip && \
    unzip terraform.zip && mv terraform /usr/local/bin/
RUN wget https://github.com/Azure/kubelogin/releases/download/v0.0.20/kubelogin-linux-amd64.zip && \
    unzip kubelogin-linux-amd64.zip 


FROM --platform=linux/amd64 ubuntu:16.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /

# copy kubectl cli binary and install aws cli v2
COPY --from=build /aws aws
COPY --from=build /skaffold skaffold
COPY --from=build /kustomize /usr/bin
COPY --from=build /kubectl kubectl
RUN install -o root -g root -m 0755 ./kubectl /usr/local/bin/kubectl 
COPY --from=build /usr/local/bin/terraform /usr/local/bin/terraform
COPY --from=build /bin/linux_amd64/kubelogin /usr/local/bin/kubelogin
RUN apt-get update && apt-get install --no-install-recommends -y git ssh jq curl ca-certificates apt-transport-https
RUN install ./skaffold /usr/local/bin && rm -rf skaffold
RUN ./aws/install && rm -rf aws
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

