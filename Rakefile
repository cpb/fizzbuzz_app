require_relative "config/application"
Rails.application.load_tasks
Dir[File.join(__dir__, "packs/*/lib/tasks/**/*.rake")].each { |f| load f }
