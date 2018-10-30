require 'sidekiq-scheduler'

class FetchSportsAndScopesWorker
  include Sidekiq::Worker

  def perform
    OddsFeed::Radar::TournamentFetcher.call
  end
end
