# frozen_string_literal: true

module Events
  class ContextEnum < Base::Enum
    description 'Event context'

    EventsQueryResolver::SUPPORTED_CONTEXTS.each do |context|
      value context
    end
  end
end
