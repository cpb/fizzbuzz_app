# Autoloading with Packwerk Packs

## How Zeitwerk Handles Packs

Zeitwerk autoloads constants based on file paths relative to registered
"autoload roots." Rails registers each `app/<layer>/` directory automatically
— e.g., `app/models/`, `app/controllers/`, `app/jobs/`.

When files move to `packs/<name>/app/<layer>/`, those directories are NOT
automatically registered. They must be added explicitly so Zeitwerk can resolve
constants from pack files.

## Required config/application.rb Change

fizzbuzz_app's current `config/application.rb` (Rails 8.1, no packs):

```ruby
module FizzbuzzApp
  class Application < Rails::Application
    config.load_defaults 8.1
    config.autoload_lib(ignore: %w[assets tasks])
    config.active_job.queue_adapter = :async_job
  end
end
```

After introducing packs, add one line:

```ruby
module FizzbuzzApp
  class Application < Rails::Application
    config.load_defaults 8.1
    config.autoload_lib(ignore: %w[assets tasks])
    config.active_job.queue_adapter = :async_job

    # Register pack app/ subdirectories as Zeitwerk autoload roots.
    config.paths.add "packs", glob: "*/app/{*,*/concerns}", eager_load: true
  end
end
```

`config.paths.add "packs", glob: "*/app/{*,*/concerns}", eager_load: true`
expands to all matching directories under `packs/`:

- `packs/links/app/models/`
- `packs/links/app/controllers/`
- `packs/links/app/jobs/`
- `packs/fizzbuzz/app/models/`
- `packs/fizzbuzz/app/controllers/`
- `packs/fizzbuzz/app/jobs/`
- (and any `concerns/` subdirectories within those)

Each directory becomes an autoload root, so `Link` resolves from
`packs/links/app/models/link.rb` — no namespace required.

## View Paths

`app/views/` is not managed by Zeitwerk — ActionView has its own view path
registry. Moving views into packs requires adding those paths separately:

```ruby
# config/application.rb
config.paths.add "packs", glob: "*/app/{*,*/concerns}", eager_load: true

# Register pack view directories with ActionView
config.paths["app/views"] += Dir[root.join("packs/*/app/views")]
```

This makes Rails look in `packs/links/app/views/` and `packs/fizzbuzz/app/views/`
for templates, in addition to the standard `app/views/`.

## Verification

After adding the autoload config, verify Zeitwerk is satisfied:

```sh
bin/rails zeitwerk:check
```

A clean output looks like:

```
Hold on, I am eager loading the application.
All is good!
```

Any constant resolution errors will be reported here before Packwerk runs.

## Alternative: packs-rails gem

The `packs-rails` gem (Gusto, v0.1.0) automates both the Zeitwerk autoload
path registration and ActionView view path registration for all packs. Instead
of the manual `config.paths.add` call, add to Gemfile:

```ruby
gem "packs-rails"
```

With `packs-rails`, no `config/application.rb` changes are needed for paths.

**Recommendation for fizzbuzz_app:** Use the manual approach. With only two
packs, the manual `config.paths.add` line is transparent and avoids an
additional gem dependency. packs-rails is worth adding if the number of packs
grows substantially.

## Rails 8.1 Specifics

Rails 8.1 uses Zeitwerk exclusively (classic autoloader was removed in
Rails 7.1). The `config.autoload_lib` call handles `lib/` separately.
Pack paths via `config.paths.add` are additive and compatible with all
existing Rails 8.1 autoloading behavior.

There are no known gotchas specific to Rails 8.1 + Zeitwerk + Packwerk. The
combination has been in production use at Shopify (Rails 7/8) and Gusto
(Rails 7/8) without reported issues.
