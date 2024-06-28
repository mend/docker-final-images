ARG RELEASE

FROM mend/base-repo-remediate:${RELEASE}

COPY package.json yarn.lock ./
RUN yarn install --production --frozen-lockfile && yarn cache clean

COPY src/server.js src/server.js

USER $USER_ID
