FROM ubuntu:focal-20220302
MAINTAINER RStudio Quality <qa@rstudio.com>

ARG PYTHON_VERSION=3.9.10

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN=true

# Install basic development & debugging tools
RUN set -ex; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        bash \
        curl \
        jq \
        libnss-wrapper \
        make \
        openssh-server \
        sudo \
        vim \
        wget; \
    \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*;

# Install a custom version of python
RUN apt-get update && \
    apt-get install -y \
        gcc \
        git \
        libbz2-dev \
        libc6-dev \
        libffi-dev \
        liblzma-dev \
        libreadline-dev \
        libcurl4-openssl-dev \
        libncurses5-dev \
        libssl-dev \
        libsqlite3-dev \
        libxml2-dev \
        libxmlsec1-dev \
        zlib1g-dev \
        && \
    rm -rf /var/lib/apt/lists/*

# Pyenv
# install into /opt/pyenv
RUN git clone https://github.com/pyenv/pyenv.git /opt/pyenv && \
    cd /opt/pyenv && \
    git checkout v2.2.4 && \
    src/configure && make -C src && \
    cd - && \
    git clone https://github.com/pyenv/pyenv-virtualenv.git /opt/pyenv/plugins/pyenv-virtualenv && \
    cd /opt/pyenv/plugins/pyenv-virtualenv && \
    git checkout v1.1.5 && \
    cd -

# install python into /usr/local
RUN \
    export PYENV_ROOT="/opt/pyenv" && \
    export PATH="$PYENV_ROOT/bin:$PATH" && \
    eval "$(pyenv init --path)" && \
    eval "$(pyenv init -)" && \
    eval "$(pyenv virtualenv-init -)" && \
    export PYTHON_CONFIGURE_OPTS="--enable-shared" && \
    pyenv exec python-build ${PYTHON_VERSION} /usr/local

# Copy in Python package requirements files
WORKDIR /opt/work
COPY Pipfile Pipfile.lock /opt/work/

# install pipenv and other python packages
RUN set -ex; \
    python3 -m pip install --no-cache-dir pipenv; \
    pipenv sync --system --dev --pre; \
    rm -f Pipfile Pipfile.lock;

# Prevent python from creating .pyc files and __pycache__ dirs
ENV PYTHONDONTWRITEBYTECODE=1

# Show stdout when running in docker compose (dont buffer)
ENV PYTHONUNBUFFERED=1

# Add a python startup file
COPY pystartup /usr/local/share/python/pystartup
ENV PYTHONSTARTUP=/usr/local/share/python/pystartup

# command line setup
# do minimal setup so we can be semi-efficient when using
# the command line of the container. Without PS1, we will
# get a prompt like "I have no name!@<container_id_hash>:/$"
# since we don't create a user or group.
RUN set -ex; \
    echo "PS1='\h:\w\$ '" >> /etc/bash.bashrc; \
    echo "alias ls='ls --color=auto'" >> /etc/bash.bashrc; \
    echo "alias grep='grep --color=auto'" >> /etc/bash.bashrc;

# Create user named "user" with no password
RUN useradd --create-home --shell /bin/bash user \
    && passwd user -d \
    && adduser user sudo

# Don't require a password for sudo
RUN sed -i 's/^\(%sudo.*\)ALL$/\1NOPASSWD:ALL/' /etc/sudoers

# set an entrypoint script that allows us to
# dynamically change the uid/gid of the container's user
COPY entry_point.sh /opt/bin/
ENTRYPOINT ["/opt/bin/entry_point.sh"]
CMD ["/opt/bin/entry_point.sh"]
