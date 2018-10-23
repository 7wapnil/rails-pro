module EventDetails
  class Radar < EventDetails::Base
    def competitors
      @competitors ||= build_competitors
    end

    private

    def build_competitors
      event_competitors = competitors_payload
      if event_competitors.nil?
        Rails.logger.debug "No competitors found in event ID #{@event.id}"
        return []
      end

      event_competitors.map do |item|
        Competitor.new(id: item['id'], name: item['name'])
      end
    end

    def competitors_payload
      return nil if @event.payload.nil?

      return nil if @event.payload['competitors'].nil?

      competitors = @event.payload['competitors']['competitor']
      return [competitors] unless competitors.is_a?(Array)

      competitors
    end
  end
end
