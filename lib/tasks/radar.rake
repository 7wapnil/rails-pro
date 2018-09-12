namespace :radar do
  desc 'Book next day\'s matches for live coverage'
  task book_live_coverage: :environment do
    client = OddsFeed::Radar::Client.new

    Rails.logger.info 'Querying upcoming events ...'
    client.events_to_date(Date.tomorrow).each do |event_adapter|
      Radar::LiveCoverageBookingWorker.new.perform(event_adapter.payload['id'])
    end
  end

  desc 'Update market templates'
  task update_market_templates: :environment do
    Radar::MarketsUpdateWorker.new.perform
  end
end
