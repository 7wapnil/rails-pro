namespace :sidekiq do
  desc 'Clear Sidekiq data from Redis'
  task clear: :environment do
    Sidekiq.redis { |r| puts r.flushall }
  end
end
