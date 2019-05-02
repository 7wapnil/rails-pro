namespace :sidekiq do
  desc 'Clear Sidekiq data from Redis'
  task clear: :environment do
    Sidekiq.redis { |r| puts r.flushall }
  end

  namespace :counters do
    task clear: :environment do
      Sidekiq.redis do |r|
        puts r.del('stat:processed')
        puts r.del('stat:failed')
      end
    end
  end
end
