module Events
  class EventsLoader
    SUPPORTED_CONTEXTS = %w[live upcoming_for_time upcoming_limited].freeze
    UPCOMING_LIMIT = 16

    def initialize(query_args)
      @query_args = query_args
      @context = query_args.context
      @filter = query_args.filter
      @query = Event
               .visible
               .active
               .joins(:title)
               .order(:priority)
               .order(:start_at)
    end

    def load
      apply_context!
      apply_filters!
      query
    end

    private

    attr_reader :query_args, :context, :filter, :query

    def upcoming_for_time
      query.where('start_at > ? AND start_at <= ? AND end_at IS NULL',
                  Time.zone.now,
                  Time.zone.now + 24.hours)
    end

    def upcoming_limited
      upcoming_for_time.limit(UPCOMING_LIMIT)
    end

    def live
      query.in_play
    end

    def filter_by_id(id)
      return query if id.nil?

      query.where(id: id)
    end

    def filter_by_title_id(title_id)
      return query if title_id.nil?

      query.where(title_id: title_id)
    end

    def filter_by_title_kind(title_kind)
      return query if title_kind.nil?

      query.where(titles: { kind: title_kind })
    end

    def filter_by_category_id(category_id)
      return query if category_id.nil?

      query
        .eager_load(:scoped_events)
        .where(scoped_events: { event_scope_id: category_id })
    end

    def filter_by_tournament_id(tournament_id)
      return query if tournament_id.nil?

      query
        .eager_load(:scoped_events)
        .where(scoped_events: { event_scope_id: tournament_id })
    end

    def apply_context!
      return unless context_required?

      verify_context!
      @query = send(context)
    end

    def apply_filters!
      filter.to_h.each do |filter, value|
        if value.is_a? TrueClass
          @query = @query.public_send(filter)
        else
          unless value.is_a? FalseClass
            filter_name = "filter_by_#{filter}"
            @query = send(filter_name, value)
          end
        end
      end
    end

    def verify_context!
      error_msg = 'Context is required!'
      raise StandardError, error_msg if context_required? && context.blank?

      check_context_support!
    end

    def context_required?
      filter&.tournament_id.nil?
    end

    def check_context_support!
      return if context.blank?

      error_msg = <<~MSG
        Unsupported context '#{context}'.Supported contexts are #{SUPPORTED_CONTEXTS.join(', ')}
      MSG

      raise StandardError, error_msg unless SUPPORTED_CONTEXTS.include? context
    end
  end
end
