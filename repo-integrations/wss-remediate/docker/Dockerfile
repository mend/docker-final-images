FROM mend/base-repo-remediate:25.4.1.2

# The containerbase supports custom user but Renovate requires ubuntu
ARG USER_NAME=ubuntu
ARG USER_ID=1000
ARG APP_ROOT=/usr/src/app

# Set env and shell
ENV BASH_ENV=/usr/local/etc/env
SHELL ["/bin/bash" , "-c"]

# START OF FINAL IMAGE

WORKDIR ${APP_ROOT}

COPY package.json package-lock.json ./
RUN npm install --only=production && npm cache clean --force

ARG SERVER_SRC=src/server.js
ARG SERVER_DST=src/server.js

COPY ${SERVER_SRC} ${SERVER_DST}

ARG WS_PLATFORM=enterprise
ENV WS_PLATFORM=${WS_PLATFORM}
ENV RENOVATE_X_MATCH_PACKAGE_NAMES_MORE=true
ENV RENOVATE_X_DOCKER_HUB_TAGS=true
ENV RENOVATE_X_EXEC_GPID_HANDLE=true

# This entry point ensures that dumb-init is run
ENTRYPOINT [ "docker-entrypoint.sh" ]

RUN node_default -v

CMD [ "node_default", "/usr/src/mend/src/server.js" ]

EXPOSE 8080

# Override home for openshift and add user bin to path
ENV HOME=/home/$USER_NAME PATH=/home/$USER_NAME/bin:$PATH

ENV RENOVATE_BINARY_SOURCE=global

# Use the working dir Renovate cli expects
WORKDIR /usr/src/app

USER $USER_ID
