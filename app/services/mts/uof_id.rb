module Mts
  class UofId
    include JobLogger

    def self.id(odd)
      new(odd).uof_id
    end

    def initialize(odd)
      @odd = odd

      event_producer_failure! unless producer
    end

    # "uof:<product_id>/<sport id>/<market id>/<outcome
    # id>?<specifier1>=<value1>[&<specifierN=valueN>]*"
    def uof_id
      [
        'uof:',
        product_id,
        '/',
        sport_id,
        '/',
        market_id,
        '/',
        outcome_id,
        specifiers_part
      ].join
    end

    private

    delegate :producer, :title, to: :event

    def event_producer_failure!
      error = ArgumentError.new('Error with getting producer for event')

      log_job_failure(error)
      raise error
    end

    def specifiers_part
      specifiers.empty? ? nil : "?#{specifiers}"
    end

    def product_id
      producer.id
    end

    def event
      @event ||= @odd.market.event
    end

    def outcome_id
      parse_odd_external_id[4]
    end

    def market_id
      parse_odd_external_id[2]
    end

    def sport_id
      title.external_id
    end

    def specifiers
      parse_odd_external_id[3].tr('|', '&')
    end

    def parse_odd_external_id
      %r{[a-z]*:[a-z]*:([0-9]*):([0-9]*)[/]?([^:]*):([0-9]*)}
        .match(@odd.external_id)
    end
  end
end
