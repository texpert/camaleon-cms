# Camaleon CMS

A Ruby on Rails content management system (Rails Engine). Ruby >= 3.0, Rails >= 6.1.

## Agent Behaviour

When providing "Further Considerations," wait for explicit confirmation before proceeding with any next steps or implementations.

## Quality Gate

Before completing any task, verify:
1. Code passes RuboCop: `bundle exec rubocop`
2. Specs pass: `RAILS_ENV=test bundle exec rspec`
3. New functionality has test coverage
4. No security issues introduced (eval, SQL injection, unsanitized input)

See [docs/ai/quality/criteria.md](docs/ai/quality/criteria.md) for full criteria.

## Architectural Decisions

When making significant decisions (new gems, API changes, schema changes), document them in [docs/ai/decisions/](docs/ai/decisions/).

## Learned Knowledge

Insights and patterns learned during development are stored in [docs/ai/knowledge/](docs/ai/knowledge/).

## Quick Reference

- [Testing Commands](docs/ai/testing.md)
- [Code Style](docs/ai/code-style.md)
- [Rails Conventions](docs/ai/rails-conventions.md)
- [Reference](docs/ai/reference.md)
