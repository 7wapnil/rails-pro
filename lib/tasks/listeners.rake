# frozen_string_literal: true

namespace :listeners do
  desc 'Starts all listeners for MTS'
  task start: :environment do
    Listeners::Daemon.start
  end
end
