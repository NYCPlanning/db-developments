# See here for image contents: https://github.com/NYCPlanning/docker-geosupport

# [Choice] Geosupport version
ARG VERSION_GEO="22.2.2"
FROM nycplanning/docker-geosupport:${VERSION_GEO}

# [Choice] Node.js version: none, lts/*, 16, 14, 12, 10
ARG NODE_VERSION="none"
RUN if [ "${NODE_VERSION}" != "none" ]; then su vscode -c "umask 0002 && . /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"; fi

## Install postgres
RUN apt-get update 
# && export DEBIAN_FRONTEND=noninteractive \
RUN apt-get -y install --no-install-recommends postgresql-client 
RUN apt-get install -y jq
RUN curl -O https://dl.min.io/client/mc/release/linux-amd64/mc\
    && chmod +x mc\
    && mv ./mc /usr/bin

# [Optional] If your pip requirements rarely change, uncomment this section to add them to the image.
# COPY requirements.txt /tmp/pip-tmp/
# RUN pip3 --disable-pip-version-check --no-cache-dir install -r /tmp/pip-tmp/requirements.txt \
#    && rm -rf /tmp/pip-tmp

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>
# RUN apt-get install jq

# Install poetry
RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="~/.local/bin:$PATH"

# RUN poetry install
RUN /usr/local/bin/python3 -m pip install -U bandit
RUN /usr/local/bin/python3 -m pip install -U black