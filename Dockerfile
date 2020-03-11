# Setup build arguments with default versions
ARG AWS_CLI_VERSION=1.16.313
ARG TERRAFORM_VERSION=0.12.16
ARG PYTHON_MAJOR_VERSION=3.7

# Download Terraform binary
FROM debian:buster-20191224-slim as terraform
ARG TERRAFORM_VERSION
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y unzip
RUN apt-get install -y gnupg
RUN curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS
RUN curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
RUN curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig
COPY hashicorp.asc hashicorp.asc
RUN gpg --import hashicorp.asc
RUN gpg --verify terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig terraform_${TERRAFORM_VERSION}_SHA256SUMS
RUN grep terraform_${TERRAFORM_VERSION}_linux_amd64.zip terraform_${TERRAFORM_VERSION}_SHA256SUMS | sha256sum -c -
RUN unzip -j terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Install AWS CLI using PIP
FROM debian:buster-20191224-slim as aws-cli
ARG AWS_CLI_VERSION
ARG PYTHON_MAJOR_VERSION
RUN apt-get update
RUN apt-get install -y python3=${PYTHON_MAJOR_VERSION}.3-1
RUN apt-get install -y python3-pip=18.1-5
RUN pip3 install awscli==${AWS_CLI_VERSION}

# Build final image
FROM debian:buster-20191224-slim
ARG PYTHON_MAJOR_VERSION
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates=20190110 \
    git=1:2.20.1-2+deb10u1 \
    jq=1.5+dfsg-2+b1 \
    python3=${PYTHON_MAJOR_VERSION}.3-1 \
    python3-pip=18.1-5 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_MAJOR_VERSION} 1
COPY --from=terraform /terraform /usr/local/bin/terraform
COPY --from=aws-cli /usr/local/bin/aws* /usr/local/bin/
COPY --from=aws-cli /usr/local/lib/python${PYTHON_MAJOR_VERSION}/dist-packages /usr/local/lib/python${PYTHON_MAJOR_VERSION}/dist-packages
COPY --from=aws-cli /usr/lib/python3/dist-packages /usr/lib/python3/dist-packages
WORKDIR /workspace
CMD ["bash"]
