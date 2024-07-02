FROM mend/base-repo-remediate:24.6.1

WORKDIR ${APP_ROOT}

COPY package.json yarn.lock ./
RUN yarn install --production --frozen-lockfile && yarn cache clean

ARG SERVER_SRC=src/server.js
ARG SERVER_DST=src/server.js

COPY ${SERVER_SRC} ${SERVER_DST}

ARG WS_PLATFORM=enterprise
ENV WS_PLATFORM=${WS_PLATFORM}
ENV RENOVATE_X_MATCH_PACKAGE_NAMES_MORE=true
ENV RENOVATE_X_DOCKER_HUB_TAGS=true

# This entry point ensures that dumb-init is run
ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD [ "node", "src/server.js" ]

EXPOSE 8080

# Override home for openshift and add user bin to path
ENV HOME=/home/$USER_NAME PATH=/home/$USER_NAME/bin:$PATH

ENV RENOVATE_BINARY_SOURCE=install

USER $USER_ID
