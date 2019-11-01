# frozen_string_literal: true

# TODO: move this to listeners rake task

namespace :casino_listener do
  desc 'Starts listener for Every Matrix feed'
  task start: :environment do
    EveryMatrix::MixDataFeed::Daemon.start
  end
end
