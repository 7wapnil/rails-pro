module Validators
  class EventsQueryParamsValidator < ApplicationService
    BLOCKED_STATUSES = %w[upcoming_unlimited].freeze
    REQUIRED_FIELDS  = %w[tournament_id].freeze

    def initialize(filter:, context:, from_event_context:)
      @filter  = filter
      @context = context
      @from_event_context = from_event_context
    end

    def call
      from_event_context || esports? || blocked_status? || required_fields?
    end

    private

    attr_reader :filter, :context, :from_event_context

    def esports?
      filter.title_kind.eql?(Title::ESPORTS)
    end

    def blocked_status?
      BLOCKED_STATUSES.exclude?(context)
    end

    def required_fields?
      REQUIRED_FIELDS.map { |field| filter.try(field) }.compact.any?
    end
  end
end
