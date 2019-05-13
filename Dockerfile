FROM node:10.15.3 as app

WORKDIR /app

#wildcard as some files may not be in all repos
COPY package*.json npm-shrink*.json /app/

RUN npm install --quiet

COPY . /app


RUN npm run compile:all

FROM node:10.15.3

CMD ["node", "--expose-gc", "app.js"]

WORKDIR /app



COPY --from=app /app /app

USER node

ARG RELEASE
ARG COMMIT
ENV RELEASE=${RELEASE} \
    SENTRY_RELEASE=${RELEASE} \
    COMMIT=${COMMIT}
