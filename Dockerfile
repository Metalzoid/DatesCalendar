# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
FROM ruby:3.3.0

# Rails app lives here
WORKDIR /rails
ARG RAILS_MASTER_KEY
# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    SECRET_KEY_BASE_DUMMY="1" \
    DEVISE_JWT_SECRET_KEY="fake_secret" \
    GOOGLE_CLIENT_ID="fake_secret" \
    GOOGLE_CLIENT_SECRET="fake_secret" \
    POSTMARK_API_TOKEN="fake_secret" \
    RAILS_MASTER_KEY=$RAILS_MASTER_KEY

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libvips pkg-config nodejs

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/


# Install packages needed for deployment
RUN apt-get update -qq && \
apt-get install --no-install-recommends -y curl libsqlite3-0 libvips && \
rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Run and own only the runtime files as a non-root user for security
RUN useradd rails --create-home --shell /bin/bash && \
chown -R rails:rails db log storage tmp public
RUN chmod 775 /rails/public
RUN bundle exec bin/rails assets:clobber
RUN bundle exec bin/rails assets:precompile
USER rails:rails

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3001
CMD ["./bin/rails", "server"]
