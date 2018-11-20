module OddsFeed
  module Radar
    module MarketGenerator
      class OddsGenerator < ::ApplicationService
        def initialize(market_data)
          @market_data = market_data
        end

        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/AbcSize
        def call
          return if @market_data.outcome.nil?

          @market_data.outcome.each do |odd_data|
            generate_odd!(odd_data)
          rescue StandardError => e
            Rails.logger.error e.message
            next
          end

          event_id = @market_data.event.external_id
          current_time = Time.now.utc.to_i * 1000
          process_time =
            ((current_time - @market_data.timestamp) / 1000.0).round(3)
          processing_msg = <<-MESSAGE
            Market updated for event ID '#{event_id}' \
            market ID '#{@market_data.id}', \
            current time: '#{current_time}', \
            message time: '#{@market_data.timestamp}',\
            execution: #{process_time} seconds
          MESSAGE
          Rails.logger.info processing_msg.squish

          WebSocket::Client.instance.emit(WebSocket::Signals::EVENT_CREATED,
                                          id: @market_data.event.id.to_s)
        end
        # rubocop:enable Metrics/AbcSize

        private

        def generate_odd!(odd_data)
          odd_id = "#{@market_data.external_id}:#{odd_data['id']}"
          odd = prepare_odd(odd_id, odd_data)
          log_msg = <<-MESSAGE
            Updating odd ID #{odd_id}, \
            market ID #{@market_data.id}, \
            event ID #{@market_data.event.id}, \
            #{odd_data}
          MESSAGE

          Rails.logger.info log_msg.squish

          begin
            odd.save!
          rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
            Rails.logger.warn ["Odd ID #{odd_id} creating failed", e]
            odd = prepare_odd(odd_id, odd_data)
            odd.save!
          end
        end
        # rubocop:enable Metrics/MethodLength

        def prepare_odd(external_id, payload)
          odd = Odd.find_or_initialize_by(external_id: external_id,
                                          market: @market_data.market_model)

          odd.assign_attributes(name: @market_data.odd_name(payload['id']),
                                status: payload['active'].to_i,
                                value: payload['odds'])
          odd
        end
      end
    end
  end
end
