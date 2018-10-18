module Mts
  class UofId
    def self.id(odd)
      new(odd).uof_id
    end

    def initialize(odd)
      @odd = odd
      raise ArgumentError 'Not radar Event' unless radar_event?
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
        '?',
        specifiers
      ].join
    end

    private

    def radar_event?
      producer['origin'] == 'radar'
    end

    def product_id
      producer['id'].to_i
    end

    def producer
      producer_value = @odd.market.event.payload['producer']
      raise 'Missing producer' unless producer_value

      producer_value
    end

    def outcome_id
      parse_odd_external_id[4]
    end

    def market_id
      parse_odd_external_id[2]
    end

    def sport_id
      @odd.market.event.title.external_id
    end

    def specifiers
      parse_odd_external_id[3].tr('|', '&')
    end

    def parse_odd_external_id
      %r{[a-z]*:[a-z]*:([0-9]*):([0-9]*)/([^:]*):([0-9]*)}
        .match(@odd.external_id)
    end
  end
end
