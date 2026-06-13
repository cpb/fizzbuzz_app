require_relative "config/application"
Rails.application.load_tasks

# Override :test to discover pack tests alongside root tests
Rake::Task[:test].clear
task :test do
  argv = Array(ENV["TEST"])
  if argv.empty?
    argv = Rake::FileList["test/**/*_test.rb", "packs/*/test/**/*_test.rb"].to_a
  end
  Rails::TestUnit::Runner.run_from_rake("test", argv)
end
