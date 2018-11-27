module Radar
  class MarketsUpdateWorker < ApplicationWorker
    include ::QueueName

    sidekiq_options queue: queue_name,
                    unique_across_queues: true

    def perform
      Rails.logger.debug 'Updating BetRadar market templates'
      templates.each do |market_data|
        create_or_update_market!(market_data)
      rescue StandardError => error
        Rails.logger.error error.message
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
      template.payload = { outcomes: prepare_outcomes(market_data),
                           specifiers: market_data['specifiers'],
                           attributes: market_data['attributes'] }
      template.save!
      Rails.logger.debug "Market template id '#{template.id}' updated"
    end

    def client
      @client ||= OddsFeed::Radar::Client.new
    end

    private

    def prepare_outcomes(market_data)
      return unless market_data['outcomes']

      market_data['outcomes'].tap do |outcomes|
        outcome_list = outcomes['outcome']
        outcomes['outcome'] =
          outcome_list.is_a?(Hash) ? [outcome_list] : outcome_list
      end
    end
  end
end
