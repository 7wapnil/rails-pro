module Radar
  class MarketsUpdateWorker < ApplicationWorker
    def perform
      Rails.logger.debug 'Updating BetRadar market templates'
      templates.each do |market_data|
        create_or_update_market!(market_data)
      rescue StandardError => error
        Rails.logger.error error
        next
      end
    end

    def templates
      client.markets['market_descriptions']['market']
    end

    def create_or_update_market!(market_data)
      template = MarketTemplate
                 .find_or_initialize_by(external_id: market_data['id'])
      template.name = market_data['name']
      template.groups = market_data['groups']
      template.payload = { outcomes: market_data['outcomes'],
                           specifiers: market_data['specifiers'],
                           attributes: market_data['attributes'] }
      template.save!
      Rails.logger.debug "Market template id '#{template.id}' updated"
    end

    def client
      @client ||= OddsFeed::Radar::Client.new
    end
  end
end
