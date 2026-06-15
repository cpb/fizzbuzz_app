Dir[Rails.root.join("packs/*/evals/register.rb")].sort.each { |f| require f }

EvalRegistry.fixture_dirs.each do |dir|
  ActiveRecord::FixtureSet.create_fixtures(dir, %w[prompts samples runs executions])
end

ActiveRecord::FixtureSet.create_fixtures(
  Rails.root.join("db/seeds/fixtures"),
  %w[links gists]
)
