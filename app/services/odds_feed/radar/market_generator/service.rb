# frozen_string_literal: true

module OddsFeed
  module Radar
    module MarketGenerator
      class Service < ::ApplicationService # rubocop:disable Metrics/ClassLength
        HANDED_OVER_MARKET_STATUS = '-2'
        SKIP_MARKET_MESSAGE =
          'Got -2 market status from or for non-prematch producer.'

        class HandOverError < StandardError; end

        include JobLogger

        def initialize(event:, markets_data:, message_producer_id:)
          @event = event
          @markets_data = markets_data
          @message_producer_id = message_producer_id
          @markets = []
          @odds = []
        end

        def call
          build
          import
        end

        private

        attr_reader :message_producer_id

        def build
          @markets_data.each do |market_data|
            raise HandOverError if skip_handover_with_warning?(market_data)

            build_market(market_data)
          rescue HandOverError
            log_job_message(:warn,
                            message: SKIP_MARKET_MESSAGE,
                            **extra_log_info(market_data))
            next
          rescue StandardError => e
            log_job_message(:debug, e.message)
            next
          end
        end

        def skip_handover_with_warning?(market_data)
          market_data['status'] == HANDED_OVER_MARKET_STATUS &&
            message_producer_id != ::Radar::Producer::PREMATCH_PROVIDER_ID
        end

        def handed_over_and_suspended?(market_data, event_market)
          market_data['status'] == HANDED_OVER_MARKET_STATUS &&
            message_producer_id == ::Radar::Producer::PREMATCH_PROVIDER_ID &&
            event_market&.producer_id == ::Radar::Producer::PREMATCH_PROVIDER_ID
        end

        def handed_over_and_overridden?(market_data, event_market)
          market_data['status'] == HANDED_OVER_MARKET_STATUS &&
            event_market&.producer_id == ::Radar::Producer::LIVE_PROVIDER_ID
        end

        def build_market(market_data)
          market_template =
            market_template_find_by!(external_id: market_data['id'])
          data_object = MarketData.new(@event, market_data, market_template)
          market = build_market_model(data_object)

          event_market =
            event_market_find_by(external_id: market.external_id)

          return if handed_over_and_overridden?(market_data, event_market)

          if handed_over_and_suspended?(market_data, event_market)
            market.status = StateMachines::MarketStateMachine::SUSPENDED
          end

          return unless valid?(market)

          @markets << market
          build_odds(market, data_object)
        end

        def build_market_model(data_object)
          Market.new(external_id: data_object.external_id,
                     event: @event,
                     producer_id: message_producer_id,
                     name: data_object.name,
                     status: data_object.status,
                     template: data_object.market_template,
                     template_specifiers: data_object.specifiers)
        end

        def market_template_find_by!(external_id:)
          template = market_template_from_cache(external_id)
          return template if template

          error_msg = 'MarketTemplate not found'
          raise ActiveRecord::RecordNotFound, error_msg
        rescue ActiveRecord::RecordNotFound => e
          log_job_message(:error, message: e.message,
                                  external_id: external_id,
                                  error_object: e)

          raise e
        end

        def market_template_from_cache(external_id)
          cached_templates.detect do |template|
            template.external_id == external_id
          end
        end

        def event_market_find_by(external_id:)
          @event_markets_by_external_id ||=
            @event.markets.index_by(&:external_id)

          @event_markets_by_external_id[external_id]
        end

        def valid?(market)
          return true if market.valid?

          log_job_message(
            :warn,
            message: 'Market is invalid',
            market_id: market.external_id,
            errors: market.errors.full_messages.join("\n")
          )
          false
        end

        def build_odds(market, data_object)
          @odds.push(*OddsGenerator.call(market, data_object))
        end

        def import
          import_markets
          import_odds
        end

        def import_markets
          Market.import(@markets,
                        validate: false,
                        on_duplicate_key_update: {
                          conflict_target: %i[external_id],
                          columns: %i[status priority producer_id]
                        })
        end

        def import_odds
          Odd.import(@odds,
                     validate: false,
                     on_duplicate_key_update: {
                       conflict_target: %i[external_id],
                       columns: %i[status value]
                     })
        end

        def cached_templates
          market_template_ids = @markets_data.map { |market| market['id'] }

          @cached_templates ||= MarketTemplate
                                .where(external_id: market_template_ids)
                                .order(:external_id)
        end

        def event_id
          Thread.current[:event_id]
        end

        def event_producer_id
          Thread.current[:event_producer_id]
        end

        def extra_log_info(market_data)
          {
            event_id:            event_id,
            event_producer_id:   event_producer_id,
            message_producer_id: message_producer_id,
            market_data:         market_data
          }
        end
      end
    end
  end
end
