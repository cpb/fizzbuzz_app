# config/initializers/async_job_adapter.rb
require "async/job/processor/inline"

Rails.application.configure do
  config.async_job.define_queue "default" do
    dequeue Async::Job::Processor::Inline
  end
end
