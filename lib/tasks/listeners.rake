# frozen_string_literal: true

namespace :listeners do
  namespace :mts do
    desc 'Starts all listeners for MTS'
    task start: :environment do
      Listeners::Daemon.start
    end
  end

  namespace :every_matrix do
    desc 'Starts listener for Every Matrix feed'
    task start: :environment do
      EveryMatrix::MixDataFeed::Daemon.start
    end
  end
end
