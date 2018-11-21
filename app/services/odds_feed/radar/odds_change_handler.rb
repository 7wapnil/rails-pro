module OddsFeed
  module Radar
    # rubocop:disable Metrics/ClassLength
    class OddsChangeHandler < RadarMessageHandler
      def handle
        log_processing(moment: 'started')
        create_or_update_event!
        touch_event!
        generate_markets
        log_processing(moment: 'finished')

        event
      end

      private

      def create_or_update_event!
        if event
          check_message_time
        else
          msg = <<-MESSAGE
            Event with external ID #{external_id} \
            not found, creating new
          MESSAGE

          Rails.logger.info msg.squish

          create_or_find_event!
        end
      end

      def touch_event!
        event.add_to_payload(
          producer: { origin: :radar, id: event_data['product'] },
          event_status:
            OddsFeed::Radar::EventStatusService.new.call(
              event_id: event.id, data: event_data['sport_event_status']
            )
        )
        updates = { remote_updated_at: timestamp,
                    status: event_status,
                    end_at: event_end_time }
        log_updates!(updates)
        event.assign_attributes(updates)
        event.save!
      end

      def log_updates!(updates)
        msg = <<-MESSAGE
            Updating event with ID #{external_id}, \
            product ID #{event_data['product']}, attributes #{updates}
        MESSAGE
        Rails.logger.info msg
      end

      def log_processing(moment:)
        timestamp_integer = event_data['timestamp'].to_i
        current_time = Time.now.utc.to_i * 1000
        process_time =
          ((current_time - timestamp_integer) / 1000.0).round(3)
        processing_msg = <<-MESSAGE
          Odds change message for event ID '#{external_id}' \
          processing #{moment}. \
          message time: '#{timestamp_integer}',\
          current time: '#{current_time}', \
          execution: #{process_time} seconds
        MESSAGE

        Rails.logger.info processing_msg.squish
      end

      def markets_data
        odds_payload = event_data['odds']

        unless odds_payload.is_a?(Hash)
          Rails.logger.info("Odds payload is missing for Event #{external_id}")
          return []
        end

        markets_payload = odds_payload['market']

        return markets_payload if markets_payload.is_a?(Array)
        return [markets_payload] if markets_payload.is_a?(Hash)

        []
      end

      def generate_markets
        markets_data.each do |market_data|
          generate_market!(market_data)
        rescue StandardError => e
          Rails.logger.error e.message
          Rails.logger.debug({ error: e, payload: @payload }.to_json)
          next
        end
      end

      def event_data
        @payload['odds_change']
      rescue StandardError => e
        Rails.logger.debug({ error: e, payload: @payload }.to_json)
      end

      def event_status
        status = event_data['sport_event_status']['status'] ||
                 Event.statuses[:not_started]
        event_statuses_map[status]
      end

      def event_end_time
        return nil unless event_status == Event.statuses[:ended]

        timestamp
      end

      def event_statuses_map
        {
          '0': Event.statuses[:not_started],
          '1': Event.statuses[:started],
          '3': Event.statuses[:ended],
          '4': Event.statuses[:closed]
        }.stringify_keys
      end

      def event
        @event ||= Event.find_by(external_id: external_id)
      end

      def api_event
        @api_event ||= api_client.event(external_id).result
      end

      def timestamp
        Time.at(event_data['timestamp'].to_i / 1000).utc
      end

      def external_id
        event_data['event_id']
      end

      def create_or_find_event!
        @event = api_event
        begin
          event.save!
          ::Radar::LiveCoverageBookingWorker.perform_async(event.external_id)
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
          Rails.logger.warn ["Event ID #{external_id} creating failed",
                             e.message]
          @event = Event.find_by!(external_id: external_id)
        end
      end

      def check_message_time
        return unless event.remote_updated_at

        last_update = event.remote_updated_at.utc
        return if event.remote_updated_at.utc <= timestamp

        msg = "Message came at #{timestamp}, but last update was #{last_update}"
        Rails.logger.warn msg
      end

      def generate_market!(market_data)
        ::OddsFeed::Radar::MarketGenerator::Service.call(
          event.id,
          market_data,
          event_data['timestamp'].to_i
        )
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
