# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    SidekiqUniqueJobs.config.enabled = false
  end
end
