# Packwerk Gem Compatibility

## Current Gem Version

| Gem | Version | Released | Ruby Requirement |
|-----|---------|----------|-----------------|
| packwerk | 3.3.0 | May 6, 2026 | >= 3.3 |
| packwerk-extensions | 0.3.0 | June 28, 2024 | >= 2.7 |
| packs-rails | 0.1.0 | February 4, 2026 | >= 3.1 |

fizzbuzz_app's `ruby "~> 3.3"` satisfies packwerk 3.3.0's Ruby >= 3.3 requirement exactly.

## Rails 8.1 Compatibility

Packwerk has no declared Rails version requirement in its gemspec — it depends on `activesupport >= 6.0` and `zeitwerk >= 2.6.1`, both of which Rails 8.1 provides. The gem works by reading autoload paths from the Rails app via Zeitwerk; this mechanism has been stable across Rails 6, 7, and 8.

The `railsbump.org` compatibility table confirms packwerk-extensions (the privacy/visibility checker companion) is tested through Rails 8.1.

**There are no known Rails 8.1-specific breaking changes or workarounds needed for packwerk 3.x.**

## Runtime Dependencies (packwerk 3.3.0)

| Dependency | Purpose |
|-----------|---------|
| activesupport >= 6.0 | Core Rails utilities |
| ast | Ruby AST parsing |
| benchmark | Performance measurement |
| better_html | ERB file parsing |
| bundler | Gemfile/gemspec parsing |
| constant_resolver >= 0.3 | Resolves constant definitions to files |
| parallel < 2 | Subprocess-based parallel parsing |
| parser | Ruby source parsing |
| prism >= 1.4.0 | High-performance Ruby parser (used since 3.2.0) |
| zeitwerk >= 2.6.1 | Autoload path introspection |

## Gem Group Placement

Packwerk is a static analysis tool used only during development and CI. It does not need to load in production. Add it to the `:development` group:

```ruby
group :development do
  gem "packwerk", require: false
end
```

`require: false` prevents it from loading on every `rails` invocation — Packwerk is invoked via its binstub (`bin/packwerk`), not as a Rails initializer.

If you want `bin/packwerk check` to run in CI (non-development environment), add it to `:development, :test`:

```ruby
group :development, :test do
  gem "packwerk", require: false
end
```

## Propshaft Compatibility

Propshaft is the asset pipeline; it has no interaction with Packwerk. Packwerk performs static analysis of Ruby/ERB files and reads autoload paths from Zeitwerk — it does not touch the asset pipeline. No special configuration or workaround is needed.

## Falcon Compatibility

Falcon is the web server (runtime concern); Packwerk runs outside the web server as a CLI tool (`bin/packwerk check`). There is no runtime overlap. No incompatibilities exist.

The only theoretical concern would be if Falcon's async/fiber architecture changed how `Rails.application` initializes during `bin/packwerk validate` (which boots the app to read autoload paths). In practice, `bin/packwerk validate` boots Rails in a standard way that does not start the server, so Falcon is irrelevant to Packwerk's operation.

## Companion Gems

### packwerk-extensions (optional, recommended)

Maintained by Gusto Engineers (`rubyatscale`). Provides checker extensions that Shopify removed from packwerk 3.0:

| Checker | `package.yml` key | Purpose |
|---------|------------------|---------|
| Privacy | `enforce_privacy` | Limits access to `app/public/` API |
| Visibility | `enforce_visibility` | Restricts which packages may depend on this one |
| Folder Privacy | `enforce_folder_privacy` | Limits sibling/child access in hierarchies |
| Layer | `enforce_layers` | Enforces architectural layer ordering |

For Issue #117 (links and fizzbuzz packs), `enforce_privacy` is valuable for clearly defining each pack's public API. Add to Gemfile:

```ruby
group :development, :test do
  gem "packwerk", require: false
  gem "packwerk-extensions"
end
```

Register the extension in `packwerk.yml`:

```yaml
require:
  - packwerk-extensions
```

### packs-rails (optional)

Maintained by Gusto Engineers. Auto-registers `packs/*/app/` subdirectories as Rails autoload/eager load paths so new packs are immediately recognized by Zeitwerk without modifying `config/application.rb`.

```ruby
group :development, :test do
  gem "packs-rails"
end
```

**Trade-off**: packs-rails adds a Rails initializer that runs on every boot. For this app's small number of packs (links, fizzbuzz, possibly surveys), the manual `config/application.rb` approach is simpler and avoids an extra dependency:

```ruby
# config/application.rb
config.paths.add "packs", glob: "*/app/{*,*/concerns}", eager_load: true
```

Either approach works; packs-rails is the lower-friction choice if more packs are expected.
