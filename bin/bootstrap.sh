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
die()   { echo -e "\n${RED}${BOLD}FATAL${RESET} ${RED}$1${RESET}" >&2; [[ -n "${LOG_FILE:-}" ]] && echo -e "${DIM}Full log: ${LOG_FILE}${RESET}" >&2; exit 1; }

# Print file path + line number on unexpected failure
trap 'die "Unexpected failure at line $LINENO — see output above."' ERR

# ── Parse flags ───────────────────────────────────────────────────────────────
APP_NAME="" RUBY="" AUTH="none" JOBS="none" CSS="none" FRONTEND="hotwire" UPLOADS="none"

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
      echo "  --ruby=VERSION      Ruby version (default: latest stable, resolved from endoflife.date)"
      echo "  --auth=VALUE        devise | rodauth | none (default: none)"
      echo "  --jobs=VALUE        sidekiq | solid_queue | none (default: none)"
      echo "  --css=VALUE         tailwind | none (default: none)"
      echo "  --frontend=VALUE    hotwire | react | none (default: hotwire; use none for API-only)"
      echo "  --uploads=VALUE     shrine | active_storage | none (default: none)"
      exit 0
      ;;
    *) die "Unknown flag: $arg" ;;
  esac
done

[[ -z "$APP_NAME" ]] && die "--app-name is required"

# ── Log file ──────────────────────────────────────────────────────────────────
mkdir -p sous-chef/tmp
LOG_FILE="sous-chef/tmp/${APP_NAME}-bootstrap-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "Full log: $LOG_FILE"

# ── Resolve Ruby version ───────────────────────────────────────────────────────
if [[ -z "$RUBY" ]]; then
  command -v curl &>/dev/null || die "Could not resolve Ruby version: curl not found. Pass --ruby=X.Y.Z explicitly."
  command -v jq   &>/dev/null || die "Could not resolve Ruby version: jq not found. Pass --ruby=X.Y.Z explicitly."
  echo -e "    ${YELLOW}→${RESET}  Resolving latest stable Ruby from endoflife.date..."
  RUBY=$(curl -sf --max-time 10 https://endoflife.date/api/ruby.json \
    | jq -r --arg today "$(date +%Y-%m-%d)" \
    '[.[] | select(.eol == false or ((.eol | type) == "string" and .eol > $today))] | sort_by(.releaseDate) | last | .latest' 2>/dev/null) \
    || die "Could not resolve Ruby version: endoflife.date unreachable or returned unexpected data. Pass --ruby=X.Y.Z explicitly."
  [[ -z "$RUBY" || "$RUBY" == "null" ]] \
    && die "Could not resolve Ruby version: endoflife.date returned no valid release. Pass --ruby=X.Y.Z explicitly."
fi
RUBY_MINOR=$(echo "$RUBY" | cut -d. -f1-2)

# ── Banner ────────────────────────────────────────────────────────────────────
echo
echo -e "${BOLD}${CYAN}Bootstrap: ${APP_NAME}${RESET}"
echo -e "${DIM}──────────────────────────────────────────${RESET}"
printf "  %-14s %s\n" "Ruby:"     "${RUBY} (image: ruby:${RUBY_MINOR})"
printf "  %-14s %s\n" "Auth:"     "$AUTH"
printf "  %-14s %s\n" "Jobs:"     "$JOBS"
printf "  %-14s %s\n" "CSS:"      "$CSS"
printf "  %-14s %s\n" "Frontend:" "$FRONTEND"
printf "  %-14s %s\n" "Uploads:"  "$UPLOADS"
echo -e "${DIM}──────────────────────────────────────────${RESET}"

# ── Step 3: Docker files ──────────────────────────────────────────────────────
step "3/11" "Writing Docker files and Ruby version files"

info "Writing .ruby-version (${RUBY})"
echo "$RUBY" > .ruby-version
ok ".ruby-version written"

info "Writing .tool-versions (ruby ${RUBY})"
echo "ruby $RUBY" > .tool-versions
ok ".tool-versions written"

info "Dockerfile.dev (ruby:${RUBY_MINOR})"
YARN_INSTALL_LINE=""
if [[ "$FRONTEND" == "react" ]]; then
  YARN_INSTALL_LINE="RUN npm install -g yarn"
fi
CHROME_INSTALL_BLOCK=""
if [[ "$FRONTEND" != "none" ]]; then
  info "UI frontend detected — adding Chromium for system specs"
  CHROME_INSTALL_BLOCK="RUN apt-get update -qq && apt-get install -y chromium chromium-driver && rm -rf /var/lib/apt/lists/*"
fi
cat > Dockerfile.dev << DOCKERFILE
FROM ruby:${RUBY_MINOR}
RUN apt-get update -qq && apt-get install -y \\
    build-essential \\
    libpq-dev \\
    nodejs \\
    && rm -rf /var/lib/apt/lists/*
${YARN_INSTALL_LINE}
${CHROME_INSTALL_BLOCK}
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
    image: postgres:17-alpine
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
step "4/11" "Running rails new inside Docker"

RAILS_FLAGS="--database=postgresql --skip-test"
if [[ "$FRONTEND" == "none"     ]]; then RAILS_FLAGS="$RAILS_FLAGS --api";             fi
if [[ "$CSS"      == "tailwind" ]]; then RAILS_FLAGS="$RAILS_FLAGS --css=tailwind";    fi
if [[ "$FRONTEND" == "react"    ]]; then RAILS_FLAGS="$RAILS_FLAGS --skip-hotwire";    fi

info "Rails flags: ${RAILS_FLAGS}"
info "Image: ruby:${RUBY_MINOR} (pull may take a moment if not cached)"
cmd docker run --rm \
  -v "$(pwd):/app" \
  -w /app \
  "ruby:${RUBY_MINOR}" \
  sh -c "gem install rails --no-document && rails new . ${RAILS_FLAGS} --force"
ok "Rails scaffold complete"

info "Appending entries to .gitignore"
printf '\n# Bootstrap — local env files\n.env.development\n.env.test\n\n# Sous-chef plugin tmp\nsous-chef/tmp/**\n\n# Test coverage\ncoverage/\n' >> .gitignore
ok ".gitignore updated"

# ── Step 5: Gemfile additions ─────────────────────────────────────────────────
step "5/11" "Adding tooling gems to Gemfile"

# Build conditional gem lines (alphabetical within each group)
TOP_LEVEL_GEMS=""
if [[ "$AUTH"    == "devise"  ]]; then TOP_LEVEL_GEMS+=$'gem "devise"\n';        info "Auth: devise gem added";       fi
if [[ "$AUTH"    == "rodauth" ]]; then TOP_LEVEL_GEMS+=$'gem "rodauth-rails"\n'; info "Auth: rodauth-rails gem added"; fi
if [[ "$JOBS"    == "sidekiq" ]]; then TOP_LEVEL_GEMS+=$'gem "sidekiq"\n';       info "Jobs: sidekiq gem added";      fi
if [[ "$UPLOADS" == "shrine"  ]]; then TOP_LEVEL_GEMS+=$'gem "shrine"\n';        info "Uploads: shrine gem added";    fi

# Browser testing gems — included for all UI apps, omitted for API-only
# Build the :test group as a variable so it's always a single block,
# alphabetically ordered, with no blank lines regardless of conditionals.
TEST_GROUP=$'group :test do'
if [[ "$FRONTEND" != "none" ]]; then
  info "UI frontend — adding capybara and selenium-webdriver to test group"
  TEST_GROUP+=$'\n  gem "capybara"'
fi
TEST_GROUP+=$'\n  gem "mutant-rspec", require: false'
if [[ "$FRONTEND" != "none" ]]; then
  TEST_GROUP+=$'\n  gem "selenium-webdriver"'
fi
TEST_GROUP+=$'\n  gem "simplecov",    require: false'
TEST_GROUP+=$'\nend'

[[ -n "$TOP_LEVEL_GEMS" ]] && printf '\n%s' "$TOP_LEVEL_GEMS" >> Gemfile

# Remove gems that rails new already adds to avoid duplicates
sed -i '' '/gem "brakeman"/d; /gem "rubocop-rails-omakase"/d' Gemfile

# Write all tooling groups in one pass — alphabetical within each group,
# each group name appears exactly once.
info "Adding tooling gem groups (dev/test, dev, test)"
cat >> Gemfile << 'GEMS'

group :development, :test do
  gem "bullet"
  gem "factory_bot_rails"
  gem "faker"
  gem "rspec-rails"
end

group :development do
  gem "brakeman",              require: false
  gem "database_consistency",  require: false
  gem "erb_lint",              require: false
  gem "rubocop",               require: false
  gem "rubocop-performance",   require: false
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-rspec",         require: false
  gem "rubycritic",            require: false
  gem "strong_migrations"
end

GEMS
printf '%s\n' "$TEST_GROUP" >> Gemfile
ok "Gemfile updated"

# ── Step 6: Build and install ─────────────────────────────────────────────────
step "6/11" "Building Docker image and installing gems"

info "docker compose build (downloads base image + installs system packages)"
cmd docker compose build --progress=quiet
ok "Image built"

info "bundle install (resolves + caches gems)"
cmd docker compose run --rm app bundle install
ok "Gems installed"

# ── Step 7: RSpec and tooling configuration ───────────────────────────────────
step "7/11" "Configuring RSpec, SimpleCov, FactoryBot, Bullet, RuboCop"

info "Generating RSpec boilerplate"
cmd docker compose run --rm app rails generate rspec:install

# Prepend SimpleCov to spec_helper.rb
info "Patching spec/spec_helper.rb — prepending SimpleCov"
{ printf 'require "simplecov"\nSimpleCov.start "rails"\n\n'; cat spec/spec_helper.rb; } > spec/spec_helper.rb.new
mv spec/spec_helper.rb.new spec/spec_helper.rb
ok "spec/spec_helper.rb — SimpleCov prepended"

# Add FactoryBot to rails_helper.rb and enable support file auto-require
info "Patching spec/rails_helper.rb — FactoryBot + support file loading"
awk '
  /Dir\[Rails\.root\.join/ { sub(/^# /, ""); print; next }
  /RSpec\.configure do \|config\|/ { print; print "  config.include FactoryBot::Syntax::Methods"; next }
  { print }
' spec/rails_helper.rb > spec/rails_helper.rb.new
mv spec/rails_helper.rb.new spec/rails_helper.rb
ok "spec/rails_helper.rb — FactoryBot included, support files enabled"

# System spec support — Chrome headless inside Docker (UI apps only)
if [[ "$FRONTEND" != "none" ]]; then
  info "Writing spec/support/system.rb — Capybara + headless Chrome"
  mkdir -p spec/support
  cat > spec/support/system.rb << 'SYSTEM_SPEC'
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ] do |options|
      options.add_argument("--no-sandbox")
      options.add_argument("--disable-dev-shm-usage")
      options.add_argument("--disable-gpu")
    end
  end
end
SYSTEM_SPEC
  ok "spec/support/system.rb written"
fi

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
inherit_gem:
  rubocop-rails-omakase: rubocop.yml

plugins:
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
step "8/11" "Creating database"

info "rails db:create — starts db service + creates ${APP_NAME}_development and ${APP_NAME}_test"
cmd docker compose run --rm app rails db:create
ok "Databases created: ${APP_NAME}_development, ${APP_NAME}_test"

# ── Step 9: Smoke tests ───────────────────────────────────────────────────────
step "9/11" "Smoke tests (rspec dry-run + brakeman)"

info "[1/2] rspec --dry-run (verifies RSpec loads and config is valid)"
cmd docker compose run --rm app bundle exec rspec --dry-run
ok "RSpec: dry-run passed"

info "[2/2] brakeman (static security analysis)"
cmd docker compose run --rm app bundle exec brakeman -q --no-pager
ok "Brakeman: no vulnerabilities"

# ── Step 10: Integration verification ────────────────────────────────────────
step "10/11" "Integration verification (start stack, verify server + DB)"

info "Starting stack"
cmd docker compose up -d
ok "Containers started"

info "Waiting for Rails to respond on localhost:3000 (up to 60s)"
TRIES=30
RESPONDED=0
for i in $(seq 1 $TRIES); do
  if curl -s --max-time 2 -o /dev/null http://localhost:3000; then
    ok "Server responded (attempt ${i}/${TRIES})"
    RESPONDED=1
    break
  fi
  sleep 2
done
if [[ $RESPONDED -eq 0 ]]; then
  docker compose down 2>/dev/null || true
  die "Server did not respond after 60s — check: docker compose logs app"
fi

info "Checking DB connectivity"
cmd docker compose exec app rails db:version
ok "DB connected"

info "Stopping stack"
cmd docker compose down
ok "Stack stopped"

# ── Step 11: Commit ───────────────────────────────────────────────────────────
step "11/11" "Initial commit"

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
