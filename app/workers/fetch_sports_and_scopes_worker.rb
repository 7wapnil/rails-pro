require 'sidekiq-scheduler'

class FetchSportsAndScopesWorker
  include Sidekiq::Worker

  def perform
    api_client = OddsFeed::Radar::Client.new
    api_client.tournaments['tournaments']['tournament']
              .each do |tournament|
      ::Radar::TournamentCreateWorker.perform_async(tournament)
    end
  end
end
