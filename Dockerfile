# This file was auto-generated, do not edit it directly.
# Instead run bin/update_build_scripts from
# https://github.com/das7pad/sharelatex-dev-env

FROM node:10.16.3

CMD ["node", "--expose-gc", "app.js"]

WORKDIR /app

COPY docker_cleanup.sh /

COPY package.json npm-shrinkwrap.json /app/

RUN /docker_cleanup.sh npm ci

COPY . /app

RUN /docker_cleanup.sh make build_app

USER node

ARG RELEASE
ARG COMMIT
ENV RELEASE=${RELEASE} \
    SENTRY_RELEASE=${RELEASE} \
    COMMIT=${COMMIT}
