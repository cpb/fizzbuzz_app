require_relative "config/application"
Rails.application.load_tasks
Dir[File.join(__dir__, "packs/*/lib/tasks/**/*.rake")].each { |f| load f }

# Rails hardcodes test/system; repoint to pack system test directories.
Rake::Task["test:system"].clear
desc "Run system tests in all packs"
task "test:system" do
  dirs = Dir[File.join(__dir__, "packs/*/test/system")]
  success = system("bin/rails", "test", *dirs)
  success || exit(false)
end
