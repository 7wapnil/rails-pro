# frozen_string_literal: true

module AppSignal
  module GraphqlExtensions
    def set_action_name(action_name, class_name)
      return unless Rails.env.production?

      Appsignal::Transaction
        .current
        .set_action("#{class_name}##{action_name || 'unknown'}")
    end
  end
end
