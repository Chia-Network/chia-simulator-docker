# CHIA + DEV TOOLS BUILD STEP
FROM python:3.10 AS chia_build

ARG CHIA_BRANCH=latest
ARG CHIA_COMMIT=""
ARG DEV_TOOLS_BRANCH=main
ARG DEV_TOOLS_COMMIT=""

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        lsb-release sudo

WORKDIR /chia-blockchain

RUN echo "cloning chia-blockchain ${CHIA_BRANCH}" && \
    git clone --branch ${CHIA_BRANCH} --recurse-submodules=mozilla-ca https://github.com/Chia-Network/chia-blockchain.git . && \
    # If COMMIT is set, check out that commit, otherwise just continue
    ( [ ! -z "CHIA_COMMIT" ] && git checkout CHIA_COMMIT ) || true && \
    echo "running build-script" && \
    /bin/sh ./install.sh

# we install all the chia-blockchain deps above
WORKDIR /chia-dev-tools

# move the install script onto the root directory of the image
COPY docker-install.sh /

RUN echo "cloning chia-dev-tools ${DEV_TOOLS_BRANCH}" && \
    git clone --branch ${DEV_TOOLS_BRANCH} https://github.com/Chia-Network/chia-dev-tools.git . && \
    # If COMMIT is set, check out that commit, otherwise just continue
    ( [ ! -z "DEV_TOOLS_COMMIT" ] && git checkout DEV_TOOLS_COMMIT ) || true && \
    echo "running build-script" && \
    /bin/sh /docker-install.sh

# IMAGE BUILD
FROM python:3.10-slim
LABEL org.opencontainers.image.authors="j.nelson@chia.net"
LABEL org.opencontainers.image.source="https://github.com/Chia-Network/chia-simulator-docker"
LABEL org.opencontainers.image.url="https://github.com/Chia-Network/chia-simulator-docker"
LABEL org.opencontainers.image.licenses="Apache 2.0"
LABEL org.opencontainers.image.title="One-Click Chia Simulator"

EXPOSE 8555 58444

ENV CHIA_SIMULATOR_ROOT=/root/.chia/simulator
ENV simulator_name="main"
ENV start_wallet="true"
ENV auto_farm="true"
## if you want to use a consistant private key, paste in the words below
ENV mnemonic=""
ENV reward_address=""
ENV fingerprint=""
ENV TZ="UTC"
ENV healthcheck="true"

# Minimal list of software dependencies
#   sudo: Needed for alternative plotter install
#   tzdata: Setting the timezone
#   curl: Health-checks
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y sudo tzdata curl && \
    rm -rf /var/lib/apt/lists/* && \
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata

COPY --from=chia_build /chia-dev-tools /chia-dev-tools

# these allow one click cli access to the simulator
ENV PATH=/chia-dev-tools/venv/bin:$PATH
ENV CHIA_ROOT=$CHIA_SIMULATOR_ROOT/$simulator_name

WORKDIR /chia-dev-tools

COPY docker-start.sh /usr/local/bin/
COPY docker-entrypoint.sh /usr/local/bin/
COPY docker-healthcheck.sh /usr/local/bin/

HEALTHCHECK --interval=1m --timeout=10s --start-period=20m \
  CMD /bin/bash /usr/local/bin/docker-healthcheck.sh || exit 1

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["docker-start.sh"]
