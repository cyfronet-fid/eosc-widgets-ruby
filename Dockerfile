# syntax=docker/dockerfile:1.7

ARG RUBY_VERSION=4.0.0
FROM ruby:${RUBY_VERSION}-slim

ENV APP_HOME=/app \
    BUNDLE_DEPLOYMENT=true \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development test" \
    RACK_ENV=production \
    PORT=9292

WORKDIR $APP_HOME

# System dependencies for building native gems (pg) and SSL
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends build-essential libpq-dev ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*

# Install gems first to leverage Docker layer caching
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Then copy the rest of the application
COPY . .

EXPOSE 9292

# Basic healthcheck hitting the root page
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD curl -fsS http://localhost:${PORT}/ || exit 1

# Start the app with Puma on 0.0.0.0
CMD ["bundle", "exec", "puma", "-b", "tcp://0.0.0.0:9292", "-e", "production"]
