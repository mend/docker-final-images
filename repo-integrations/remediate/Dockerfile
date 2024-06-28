FROM mend/base-repo-remediate:24.6.1

COPY package.json yarn.lock ./
RUN yarn install --production --frozen-lockfile && yarn cache clean

COPY src/server.js src/server.js

USER $USER_ID
