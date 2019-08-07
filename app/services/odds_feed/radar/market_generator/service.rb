# frozen_string_literal: true

module OddsFeed
  module Radar
    module MarketGenerator
      class Service < ::ApplicationService # rubocop:disable Metrics/ClassLength
        HANDED_OVER_MARKET_STATUS = '-2'
        SKIP_MARKET_MESSAGE =
          'Got -2 market status from of for non-prematch producer.'

        class HandOverError < StandardError; end

        include JobLogger

        def initialize(event:, markets_data:, prematch_producer: false)
          @event = event
          @markets_data = markets_data
          @prematch_producer = prematch_producer
          @markets = []
          @odds = []
        end

        def call
          build
          import
        end

        private

        def build
          @markets_data.each do |market_data|
            raise HandOverError if skip_market?(market_data)

            build_market(market_data)
          rescue HandOverError
            log_job_message(
              :warn,
              market_data.merge(message: SKIP_MARKET_MESSAGE)
            )
            next
          rescue StandardError => e
            log_job_message(:debug, e.message)
            next
          end
        end

        def skip_market?(market_data)
          market_data['status'] == HANDED_OVER_MARKET_STATUS &&
            !@prematch_producer
        end

        def build_market(market_data)
          market_template =
            market_template_find_by!(external_id: market_data['id'])
          data_object = MarketData.new(@event, market_data, market_template)
          market = build_market_model(data_object)
          return unless valid?(market)

          @markets << market
          build_odds(market, data_object)
        end

        def build_market_model(data_object)
          Market.new(external_id: data_object.external_id,
                     event: @event,
                     name: data_object.name,
                     status: data_object.status,
                     category: data_object.category,
                     template_id: data_object.template_id,
                     template_specifiers: data_object.specifiers)
        end

        def market_template_find_by!(external_id:)
          template = market_template_from_cache(external_id)
          return template if template

          error_msg = 'MarketTemplate not found'
          log_job_message(:error, message: error_msg, external_id: external_id)
          raise(ActiveRecord::RecordNotFound, error_msg)
        end

        def market_template_from_cache(external_id)
          cached_templates.detect do |template|
            template.external_id == external_id
          end
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
                          columns: %i[status priority]
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
          market_template_ids =
            @markets_data.map { |market| market['id'] }

          @cached_templates ||=
            MarketTemplate
            .where(external_id: market_template_ids)
            .order(:external_id)
        end
      end
    end
  end
end
