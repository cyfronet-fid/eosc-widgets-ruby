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

# System dependencies for building native gems (pg, psych) and JS assets
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    libyaml-dev \
    ca-certificates \
    curl \
    git \
    nodejs \
    npm \
    netcat-openbsd && \
    rm -rf /var/lib/apt/lists/*

# Install gems first to leverage Docker layer caching
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Install JS dependencies
COPY package.json yarn.lock* ./
RUN npm install --global yarn
RUN yarn install

# Then copy the rest of the application
COPY . .

RUN chmod +x entrypoint.sh
RUN SECRET_KEY_BASE_DUMMY=1 SESSION_SECRET=dummy bundle exec rake assets:precompile

EXPOSE 9292

# Basic healthcheck hitting the root page
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD curl -fsS http://localhost:${PORT}/ || exit 1

# Start the app with entrypoint
ENTRYPOINT ["./entrypoint.sh"]
