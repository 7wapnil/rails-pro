module OddsFeed
  module Radar
    module MarketGenerator
      class MarketData
        attr_reader :event

        def initialize(event, payload)
          @event = event
          @payload = payload
          @interpreter = OddsFeed::Radar::Transpiling::Interpreter.new(event,
                                                                       tokens)
        end

        def id
          @payload['id']
        end

        def name
          @interpreter.parse(template.market_name)
        end

        def odd_name(odd_id)
          @interpreter.parse(template.odd_name(odd_id))
        end

        def external_id
          @external_id ||= OddsFeed::Radar::ExternalId
                           .new(event_id: @event.external_id,
                                market_id: id,
                                specs: specifiers)
                           .generate
        end

        def specifiers
          @payload['specifiers'] || ''
        end

        def status
          status_map[@payload['status']] || Market::DEFAULT_STATUS
        end

        def outcome
          @payload['outcome']
        end

        def template
          @template ||= TemplateLoader.new(id, tokens['variant'])
        end

        private

        def tokens
          @tokens ||= specifiers
                      .split('|')
                      .map { |spec| spec.split('=') }
                      .to_h
        end

        def status_map
          {
            '-2': :handed_over,
            '-1': :suspended,
            '0': :inactive,
            '1': :active
          }.stringify_keys
        end
      end
    end
  end
end
