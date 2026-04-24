#!/usr/bin/env bash
# bootstrap.sh — scaffold a Rails app with Docker + tooling
# Called by /chef:bootstrap after it parses sous-chef/ARCHITECTURE.md
set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
BOLD='\033[1m'; CYAN='\033[0;36m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; RED='\033[0;31m'; DIM='\033[2m'; RESET='\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────────
step()  { echo; echo -e "${BOLD}${CYAN}==> [$1] $2${RESET}"; }
info()  { echo -e "    ${YELLOW}→${RESET}  $1"; }
ok()    { echo -e "    ${GREEN}✓${RESET}  $1"; }
cmd()   { echo -e "    ${DIM}\$${RESET} $*"; "$@"; }
die()   { echo -e "\n${RED}${BOLD}FATAL${RESET} ${RED}$1${RESET}" >&2; exit 1; }

# Print file path + line number on unexpected failure
trap 'die "Unexpected failure at line $LINENO — see output above."' ERR

# ── Parse flags ───────────────────────────────────────────────────────────────
APP_NAME="" RUBY="3.3" AUTH="none" JOBS="none" CSS="none" FRONTEND="hotwire" UPLOADS="none"

for arg in "$@"; do
  case $arg in
    --app-name=*)  APP_NAME="${arg#*=}"  ;;
    --ruby=*)      RUBY="${arg#*=}"      ;;
    --auth=*)      AUTH="${arg#*=}"      ;;
    --jobs=*)      JOBS="${arg#*=}"      ;;
    --css=*)       CSS="${arg#*=}"       ;;
    --frontend=*)  FRONTEND="${arg#*=}"  ;;
    --uploads=*)   UPLOADS="${arg#*=}"   ;;
    --help)
      echo "Usage: bootstrap.sh --app-name=<slug> [options]"
      echo "  --ruby=VERSION      Ruby image tag (default: 3.3)"
      echo "  --auth=VALUE        devise | rodauth | none (default: none)"
      echo "  --jobs=VALUE        sidekiq | solid_queue | none (default: none)"
      echo "  --css=VALUE         tailwind | none (default: none)"
      echo "  --frontend=VALUE    hotwire | react (default: hotwire)"
      echo "  --uploads=VALUE     shrine | active_storage | none (default: none)"
      exit 0
      ;;
    *) die "Unknown flag: $arg" ;;
  esac
done

[[ -z "$APP_NAME" ]] && die "--app-name is required"

# ── Banner ────────────────────────────────────────────────────────────────────
echo
echo -e "${BOLD}${CYAN}Bootstrap: ${APP_NAME}${RESET}"
echo -e "${DIM}──────────────────────────────────────────${RESET}"
printf "  %-14s %s\n" "Ruby:"     "$RUBY"
printf "  %-14s %s\n" "Auth:"     "$AUTH"
printf "  %-14s %s\n" "Jobs:"     "$JOBS"
printf "  %-14s %s\n" "CSS:"      "$CSS"
printf "  %-14s %s\n" "Frontend:" "$FRONTEND"
printf "  %-14s %s\n" "Uploads:"  "$UPLOADS"
echo -e "${DIM}──────────────────────────────────────────${RESET}"

# ── Step 3: Docker files ──────────────────────────────────────────────────────
step "3/10" "Writing Docker files"

info "Dockerfile.dev (ruby:${RUBY})"
cat > Dockerfile.dev << DOCKERFILE
FROM ruby:${RUBY}
RUN apt-get update -qq && apt-get install -y \\
    build-essential \\
    libpq-dev \\
    nodejs \\
    yarn \\
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install
EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
DOCKERFILE
ok "Dockerfile.dev written"

info "compose.yml"
REDIS_SERVICE_BLOCK=""
REDIS_VOLUME_ENTRY=""
if [[ "$JOBS" == "sidekiq" ]]; then
  info "Sidekiq detected — adding Redis service to compose.yml"
  REDIS_SERVICE_BLOCK=$(printf '\n  redis:\n    image: redis:7-alpine\n    volumes:\n      - redis_data:/data')
  REDIS_VOLUME_ENTRY=$(printf '\n  redis_data:')
fi

cat > compose.yml << COMPOSE
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    volumes:
      - .:/app
      - bundle_cache:/usr/local/bundle
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgresql://postgres:password@db:5432/${APP_NAME}_development
      RAILS_ENV: development
    depends_on:
      - db
    stdin_open: true
    tty: true

  db:
    image: postgres:16-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: password
${REDIS_SERVICE_BLOCK}
volumes:
  postgres_data:
  bundle_cache:
${REDIS_VOLUME_ENTRY}
COMPOSE
ok "compose.yml written"

info "Appending .env entries to .gitignore"
printf '\n# Bootstrap — local env files\n.env.development\n.env.test\n' >> .gitignore
ok ".gitignore updated"

info "Makefile"
cat > Makefile << 'MAKEFILE'
.PHONY: build run shell test lint logs

build:
	docker compose build

run:
	docker compose up -d

shell:
	docker compose exec app bash

test:
	docker compose exec app bundle exec rspec

lint:
	docker compose exec app bundle exec rubocop

logs:
	docker compose logs -f app
MAKEFILE
ok "Makefile written"

# ── Step 4: rails new ─────────────────────────────────────────────────────────
step "4/10" "Running rails new inside Docker"

RAILS_FLAGS="--database=postgresql --skip-test"
if [[ "$CSS"      == "tailwind" ]]; then RAILS_FLAGS="$RAILS_FLAGS --css=tailwind";   fi
if [[ "$FRONTEND" == "react"    ]]; then RAILS_FLAGS="$RAILS_FLAGS --skip-hotwire";   fi

info "Rails flags: ${RAILS_FLAGS}"
info "Image: ruby:${RUBY} (pull may take a moment if not cached)"
cmd docker run --rm \
  -v "$(pwd):/app" \
  -w /app \
  "ruby:${RUBY}" \
  sh -c "gem install rails --no-document && rails new . ${RAILS_FLAGS} --force"
ok "Rails scaffold complete"

# ── Step 5: Gemfile additions ─────────────────────────────────────────────────
step "5/10" "Adding tooling gems to Gemfile"

# Stack-specific top-level gems first
CONDITIONAL_GEMS=""
if [[ "$AUTH"    == "devise"  ]]; then CONDITIONAL_GEMS+=$'gem "devise"\n';        info "Auth: devise gem added";       fi
if [[ "$AUTH"    == "rodauth" ]]; then CONDITIONAL_GEMS+=$'gem "rodauth-rails"\n'; info "Auth: rodauth-rails gem added"; fi
if [[ "$JOBS"    == "sidekiq" ]]; then CONDITIONAL_GEMS+=$'gem "sidekiq"\n';       info "Jobs: sidekiq gem added";      fi
if [[ "$UPLOADS" == "shrine"  ]]; then CONDITIONAL_GEMS+=$'gem "shrine"\n';        info "Uploads: shrine gem added";    fi

if [[ -n "$CONDITIONAL_GEMS" ]]; then
  printf '\n%s' "$CONDITIONAL_GEMS" >> Gemfile
fi

# Fixed tooling groups
info "Adding tooling gem groups (dev/test, dev, test)"
cat >> Gemfile << 'GEMS'

group :development, :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "bullet"
end

group :development do
  gem "rubocop",                require: false
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-rspec",         require: false
  gem "rubocop-performance",   require: false
  gem "erb_lint",              require: false
  gem "rubycritic",            require: false
  gem "brakeman",              require: false
  gem "bundler-audit",         require: false
  gem "strong_migrations"
  gem "database_consistency",  require: false
end

group :test do
  gem "simplecov",    require: false
  gem "mutant-rspec", require: false
end
GEMS
ok "Gemfile updated"

# ── Step 6: Build and install ─────────────────────────────────────────────────
step "6/10" "Building Docker image and installing gems"

info "docker compose build (downloads base image + installs system packages)"
cmd docker compose build
ok "Image built"

info "bundle install (resolves + caches gems)"
cmd docker compose run --rm app bundle install
ok "Gems installed"

# ── Step 7: RSpec and tooling configuration ───────────────────────────────────
step "7/10" "Configuring RSpec, SimpleCov, FactoryBot, Bullet, RuboCop"

info "Generating RSpec boilerplate"
cmd docker compose run --rm app rails generate rspec:install

# Prepend SimpleCov to spec_helper.rb
info "Patching spec/spec_helper.rb — prepending SimpleCov"
{ printf 'require "simplecov"\nSimpleCov.start "rails"\n\n'; cat spec/spec_helper.rb; } > spec/spec_helper.rb.new
mv spec/spec_helper.rb.new spec/spec_helper.rb
ok "spec/spec_helper.rb — SimpleCov prepended"

# Add FactoryBot to rails_helper.rb (after the RSpec.configure opening line)
info "Patching spec/rails_helper.rb — adding FactoryBot"
awk '/RSpec\.configure do \|config\|/ { print; print "  config.include FactoryBot::Syntax::Methods"; next } { print }' \
  spec/rails_helper.rb > spec/rails_helper.rb.new
mv spec/rails_helper.rb.new spec/rails_helper.rb
ok "spec/rails_helper.rb — FactoryBot::Syntax::Methods included"

# Bullet in development.rb — insert block before the last bare `end`
info "Patching config/environments/development.rb — Bullet config"
awk '{ lines[NR] = $0 }
END {
  last = 0
  for (i = NR; i >= 1; i--) { if (lines[i] ~ /^end$/) { last = i; break } }
  for (i = 1; i <= NR; i++) {
    if (i == last) {
      print ""
      print "  config.after_initialize do"
      print "    Bullet.enable       = true"
      print "    Bullet.rails_logger = true"
      print "    Bullet.add_footer   = true"
      print "  end"
    }
    print lines[i]
  }
}' config/environments/development.rb > config/environments/development.rb.new
mv config/environments/development.rb.new config/environments/development.rb
ok "config/environments/development.rb — Bullet configured (logger + footer)"

# Bullet in test.rb — raise on N+1
info "Patching config/environments/test.rb — Bullet raise on N+1"
awk '{ lines[NR] = $0 }
END {
  last = 0
  for (i = NR; i >= 1; i--) { if (lines[i] ~ /^end$/) { last = i; break } }
  for (i = 1; i <= NR; i++) {
    if (i == last) {
      print ""
      print "  config.after_initialize do"
      print "    Bullet.enable = true"
      print "    Bullet.raise  = true"
      print "  end"
    }
    print lines[i]
  }
}' config/environments/test.rb > config/environments/test.rb.new
mv config/environments/test.rb.new config/environments/test.rb
ok "config/environments/test.rb — Bullet configured (raise: true)"

info "Writing .rubocop.yml"
cat > .rubocop.yml << 'RUBOCOP'
require:
  - rubocop-rails-omakase
  - rubocop-rspec
  - rubocop-performance

AllCops:
  NewCops: enable
  Exclude:
    - "db/schema.rb"
    - "bin/**/*"
    - "node_modules/**/*"
RUBOCOP
ok ".rubocop.yml written"

info "Writing .rubycritic_minimum_score"
echo "70" > .rubycritic_minimum_score
ok ".rubycritic_minimum_score set to 70"

# ── Step 8: Database ──────────────────────────────────────────────────────────
step "8/10" "Creating database"

info "rails db:create — starts db service + creates ${APP_NAME}_development and ${APP_NAME}_test"
cmd docker compose run --rm app rails db:create
ok "Databases created: ${APP_NAME}_development, ${APP_NAME}_test"

# ── Step 9: Smoke tests ───────────────────────────────────────────────────────
step "9/10" "Smoke tests (rspec dry-run + brakeman + bundler-audit)"

info "[1/3] rspec --dry-run (verifies RSpec loads and config is valid)"
cmd docker compose run --rm app bundle exec rspec --dry-run
ok "RSpec: dry-run passed"

info "[2/3] brakeman (static security analysis)"
cmd docker compose run --rm app bundle exec brakeman -q --no-pager
ok "Brakeman: no vulnerabilities"

info "[3/3] bundler-audit (CVE scan on Gemfile.lock)"
cmd docker compose run --rm app bundle exec bundler-audit check --update
ok "bundler-audit: no CVEs"

# ── Step 10: Commit ───────────────────────────────────────────────────────────
step "10/10" "Initial commit"

cmd git add -A
cmd git commit -m "chore: initial rails setup"
ok "Committed: chore: initial rails setup"

# ── Done ──────────────────────────────────────────────────────────────────────
echo
echo -e "${BOLD}${GREEN}Bootstrap complete.${RESET}"
echo
echo "  Start the dev server:   docker compose up"
echo "  Next step:              /chef:milestone"
echo
