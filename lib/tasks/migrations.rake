namespace :migrations do
  desc 'Migrate event producers from payload to database'
  namespace :event_producers do
    desc 'Deletes all odds feed produced data'
    task migrate: :environment do
      puts 'Migrating producers from payload to database.'
      puts '(1/3) Seeding database...'
      require Rails.root.join('db/seeds/radar_producers')
      puts '(2/3) Migrating provider 1 ...'
      Event.where("payload->'producer'->>'id' = '1'").update_all(producer_id: 1)
      puts '(3/3) Migrating provider 3 ...'
      Event.where("payload->'producer'->>'id' = '3'").update_all(producer_id: 3)
      puts 'Finished.'
    end
  end
end
