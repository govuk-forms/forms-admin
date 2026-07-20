ARG ALPINE_VERSION=3.22
ARG RUBY_VERSION=3.4.8

ARG DOCKER_IMAGE_DIGEST=sha256:c7687b054738956d3e409fbb335ffa711c9b2dab87a57a2f89d9141746b9fdde

FROM ruby:${RUBY_VERSION}-alpine${ALPINE_VERSION}@${DOCKER_IMAGE_DIGEST} AS base
ARG NODEJS_VERSION=22
ENV NODEJS_VERSION=${NODEJS_VERSION}

FROM base AS build

WORKDIR /app

RUN apk update
RUN apk upgrade --available
RUN apk add libc6-compat openssl-dev build-base libpq-dev nodejs=~${NODEJS_VERSION} npm git python3 yaml-dev
RUN adduser -D ruby
RUN mkdir /node_modules && chown ruby:ruby -R /node_modules /app

USER ruby

COPY --chown=ruby:ruby .ruby-version ./
COPY --chown=ruby:ruby Gemfile* ./

ARG BUNDLE_WITHOUT=development:test
RUN [ -z "$BUNDLE_WITHOUT" ] || bundle config set --local without "$BUNDLE_WITHOUT"
RUN bundle config set --local jobs "$(nproc)"

RUN bundle install

COPY --chown=ruby:ruby package.json package-lock.json ./
RUN npm ci --ignore-scripts

ARG RAILS_ENV NODE_ENV
ENV RAILS_ENV="${RAILS_ENV:-production}" \
    NODE_ENV="${NODE_ENV:-production}" \
    PATH="${PATH}:/home/ruby/.local/bin:/node_modules/.bin" \
    USER="ruby" \
    GOVUK_APP_DOMAIN="https://not-set"

COPY --chown=ruby:ruby . .

# you can't run rails commands like assets:precompile without a secret key set
# even though the command doesn't use the value itself
RUN SECRET_KEY_BASE=dummyvalue rails vite:build_all

# Remove devDependencies once assets have been built
RUN npm ci --ignore-scripts --omit=dev

FROM base AS app

ARG RAILS_ENV
ENV RAILS_ENV="${RAILS_ENV:-production}" \
    PATH="${PATH}:/home/ruby/.local/bin" \
    USER="ruby"

WORKDIR /app

RUN apk update
RUN apk upgrade --available
RUN apk add libc6-compat openssl-dev libpq


RUN adduser -D ruby
RUN chown ruby:ruby -R /app

USER ruby
COPY --chown=ruby:ruby bin/ ./bin
RUN chmod 0755 bin/*

COPY --chown=ruby:ruby --from=build /usr/local/bundle /usr/local/bundle
COPY --chown=ruby:ruby --from=build /app /app

# Add the RDS CA certificate to the container so that we can verify the RDS server's identity when connecting to it.
COPY --chown=ruby:ruby ./docker/eu-west-2-bundle.pem /home/ruby/.postgresql/root.crt

RUN mkdir -p "/app/tmp/" && chown ruby:ruby "/app/tmp/" && chown ruby:ruby "/app/db/"
VOLUME "/tmp/"
VOLUME "/app/tmp/"
VOLUME "/app/db/"

EXPOSE 3000

CMD ["/bin/sh", "-o", "xtrace", "-c", "rails s -b 0.0.0.0"]
