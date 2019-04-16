# frozen_string_literal: true

module QueueName
  extend ActiveSupport::Concern

  class_methods do
    def queue_name
      to_s
        .underscore
        .tr('/', '_')
        .chomp('_worker')
    end
  end
end
