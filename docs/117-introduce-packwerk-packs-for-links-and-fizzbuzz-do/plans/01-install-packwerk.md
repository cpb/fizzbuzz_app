# Plan: Install Packwerk

**Decision:** Add packwerk 3.x + packwerk-extensions to the Gemfile, generate
`bin/packwerk`, create `packwerk.yml` and root `package.yml`, and configure
autoload/view paths for future packs.

**Rationale:** Packwerk 3.3.0 requires Ruby >= 3.3 (satisfied by `~> 3.3`),
is compatible with Rails 8.1, and has no conflicts with Propshaft or Falcon.
packwerk-extensions provides `enforce_privacy` which was extracted from core
packwerk in 3.0. Manual path configuration in `config/application.rb` is
preferred over the `packs-rails` gem for this small two-pack app.

See: [gem-compatibility.md](../research/packwerk-setup/gem-compatibility.md),
[packwerk-yml-format.md](../research/packwerk-setup/packwerk-yml-format.md),
[autoloading.md](../research/pack-conventions/autoloading.md)

---

## Steps

### 1. Add gems to Gemfile

```ruby
group :development, :test do
  gem "packwerk", require: false
  gem "packwerk-extensions"
end
```

Run: `bundle install`

### 2. Generate binstub and config files

```sh
bundle binstub packwerk
bin/packwerk init
```

`bin/packwerk init` creates:
- `packwerk.yml` (all options commented out)
- `package.yml` (root package, enforcement off)

### 3. Customize packwerk.yml

Replace the generated content with:

```yaml
# packwerk.yml
package_paths:
  - "./"
  - "packs/*/"

require:
  - packwerk-extensions

parallel: true
cache: true
cache_directory: tmp/cache/packwerk
```

### 4. Verify root package.yml

`bin/packwerk init` generates:

```yaml
# package.yml
enforce_dependencies: false
enforce_privacy: false
```

This is correct as-is. No changes needed.

### 5. Configure autoload and view paths in config/application.rb

```ruby
module FizzbuzzApp
  class Application < Rails::Application
    config.load_defaults 8.1
    config.autoload_lib(ignore: %w[assets tasks])
    config.active_job.queue_adapter = :async_job

    # Autoload Ruby constants from pack app/ subdirectories
    config.paths.add "packs", glob: "*/app/{*,*/concerns}", eager_load: true

    # Register pack view directories with ActionView
    config.paths["app/views"] += Dir[root.join("packs/*/app/views")]
  end
end
```

### 6. Validate

```sh
bin/packwerk validate
```

Expected output: `Validation successful.`

### 7. Initial check (should pass with zero violations)

```sh
bin/packwerk check
```

Expected: `No violations detected.` (no packs exist yet, so nothing to check)

### 8. Run tests

```sh
bin/rails test
```

All tests must pass — this step changes no application behavior.

### 9. Commit

```sh
git add Gemfile Gemfile.lock bin/packwerk packwerk.yml package.yml config/application.rb
git commit -m "feat: install packwerk with extensions and configure autoload paths"
```

---

## Open Questions

- None — this step is purely additive; the app behavior is unchanged.

## Verification

- `bin/packwerk validate` exits 0 with "Validation successful."
- `bin/packwerk check` exits 0 with "No violations detected."
- `bin/rails test` passes (all existing tests green)
- `bin/rails zeitwerk:check` exits 0 with "All is good!"
