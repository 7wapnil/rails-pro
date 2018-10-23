module EventDetails
  class Radar < EventDetails::Base
    def competitors
      @competitors ||= build_competitors
    end

    private

    def build_competitors
      event_competitors = competitors_payload
      debug_msg = "No competitors found in event ID #{@event.id}"
      return Rails.logger.debug debug_msg if event_competitors.nil?

      competitors_payload.map do |item|
        Competitor.new(id: item['id'], name: item['name'])
      end
    end

    def competitors_payload
      return if @event.payload.nil?

      return if @event.payload['competitors'].nil?

      competitors = @event.payload['competitors']['competitor']
      return [competitors] unless competitors.is_a?(Array)

      competitors
    end
  end
end
