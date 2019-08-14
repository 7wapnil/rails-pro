# frozen_string_literal: true

module OddsFeed
  module Radar
    module MarketGenerator
      class MarketData
        attr_reader :event, :market_template

        def initialize(event, payload, market_template)
          @event = event
          @payload = payload
          @interpreter = OddsFeed::Radar::Transpiling::Interpreter.new(event,
                                                                       tokens)
          @market_template = market_template
        end

        def name
          @interpreter.parse(template.market_name)
        end

        def odd_name(odd_id)
          @interpreter.parse(template.odd_name(odd_id))
        end

        def external_id
          @external_id ||= OddsFeed::Radar::ExternalId
                           .generate(event_id: event.external_id,
                                     market_id: market_template.external_id,
                                     specs: specifiers)
        end

        def specifiers
          @payload['specifiers'] || ''
        end

        def status
          status_map[@payload['status']] ||
            StateMachines::MarketStateMachine::DEFAULT_STATUS
        end

        def outcome
          @payload['outcome']
        end

        def template
          @template ||=
            TemplateLoader.new(@event, market_template, tokens['variant'])
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
            '-2': :inactive,
            '-1': :suspended,
            '0': :inactive,
            '1': :active
          }.stringify_keys
        end
      end
    end
  end
end
