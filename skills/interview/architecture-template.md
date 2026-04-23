# Architecture — {App Name}

---

## Stack

| Layer | Choice | Notes |
|-------|--------|-------|
| Ruby on Rails | {version} | |
| Database | {choice} | |
| Auth | {choice} | |
| Authorization | {choice} | |
| Background jobs | {choice} | |
| Frontend | {choice} | |
| CSS | {choice} | |
| Component library | {choice} | |
| File uploads | {choice} | |
| Tests | RSpec + FactoryBot + SimpleCov + Mutant | |
| Linting | RuboCop (+ rails, rspec) | |
| Code quality | RubyCritic | |
| Security | Brakeman + bundler-audit | |
| DB integrity | database_consistency + strong_migrations | |

---

## Conventions

{Short, prescriptive rules every slice must follow. Standard Rails MVC/ActiveRecord/RESTful routes are assumed — do not repeat them.}

**Authorization**
- {e.g., All controller actions covered by a Pundit policy.}

**Frontend**
- {e.g., Form submissions use Turbo Streams. Stimulus for JS behaviour.}

**Testing**
- {e.g., Request specs for controllers. System specs for critical flows only. FactoryBot, no fixtures.}

**Service objects**
- {e.g., Cross-model logic in `app/services/`, `VerbNounService`, returns result object.}

---

## Decisions

**{Decision title}** — {chosen}, {rejected}, {why}.
