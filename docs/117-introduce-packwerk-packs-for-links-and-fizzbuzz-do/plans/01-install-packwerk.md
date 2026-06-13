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

# Architecture layers (highest → lowest).
# A pack may depend on packs in the same or lower layers.
# Enforced per-pack via enforce_layers: true in package.yml.
architecture_layers:
  - feature     # domain feature packs (fizzbuzz, links)
  - utility     # shared Rails infrastructure (root package)

parallel: true
cache: true
cache_directory: tmp/cache/packwerk
```

### 4. Update root package.yml

`bin/packwerk init` generates a minimal file. Update it to declare the
root's layer and enable layer enforcement:

```yaml
# package.yml (root)
enforce_dependencies: false
enforce_privacy: false
enforce_layers: true
layer: utility
```

The root package is the `utility` layer — shared Rails infrastructure
(ApplicationRecord, ApplicationController, ApplicationJob) that feature
packs depend on, not the other way around.

### 5. Update Rakefile to discover pack tests

```ruby
# Rakefile
require_relative "config/application"
Rails.application.load_tasks

# Override default test task to include tests in packs alongside root tests
Rake::Task[:test].clear
Rails::TestTask.new(:test) do |t|
  t.pattern = FileList[
    "test/**/*_test.rb",
    "packs/*/test/**/*_test.rb"
  ]
  t.verbose = false
end
```

### 6. Configure autoload and view paths in config/application.rb

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

### 7. Validate

```sh
bin/packwerk validate
```

Expected output: `Validation successful.`

### 8. Initial check (should pass with zero violations)

```sh
bin/packwerk check
```

Expected: `No violations detected.` (no packs exist yet, so nothing to check)

### 9. Run tests

```sh
bin/rails test
```

All tests must pass — this step changes no application behavior.

### 10. Commit

```sh
git add Gemfile Gemfile.lock bin/packwerk packwerk.yml package.yml config/application.rb Rakefile
git commit -m "feat: install packwerk with extensions, configure autoload paths and test discovery"
```

---

## Open Questions

- None — this step is purely additive; the app behavior is unchanged.

## Verification

- `bin/packwerk validate` exits 0 with "Validation successful."
- `bin/packwerk check` exits 0 with "No violations detected."
- `bin/rails test` passes (all existing tests green)
- `bin/rails zeitwerk:check` exits 0 with "All is good!"
