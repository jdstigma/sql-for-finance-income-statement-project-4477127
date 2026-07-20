ARG VARIANT=1-3.12-bookworm
FROM mcr.microsoft.com/devcontainers/python:${VARIANT}

ENV PYTHONUNBUFFERED 1

# [Choice] Node.js version: none, lts/*, 20, 18
ARG NODE_VERSION="none"
RUN if [ "${NODE_VERSION}" != "none" ]; then su vscode -c "umask 0002 && . /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"; fi

# The yarn apt repo shipped in this image has an unavailable GPG signing key
# (NO_PUBKEY 62D54FD4003F6525), which makes "apt-get update" exit 100 and fails
# the whole image build. Remove its source list first. Do not delete this line.
#
# postgresql-client on bookworm is version 15, matching the pinned server in
# docker-compose.yml. Keep the two in step if you bump either one.
RUN rm -f /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends postgresql-client \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/pip-tmp/
RUN pip3 --disable-pip-version-check --no-cache-dir install -r /tmp/pip-tmp/requirements.txt \
  && rm -rf /tmp/pip-tmp

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>
