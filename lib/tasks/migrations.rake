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

  namespace :scoped_events do
    desc 'Remove duplicates'
    task clean_duplicates: :environment do
      ScopedEvent.where(
        <<~SQL
          id <> (
            SELECT id
            FROM scoped_events duplicatable
            WHERE
              duplicatable.event_scope_id = scoped_events.event_scope_id AND
              duplicatable.event_id = scoped_events.event_id
            ORDER BY created_at DESC
            LIMIT 1
          )
        SQL
      ).delete_all
    end
  end

  namespace :event_scopes do
    desc 'Change COUNTRY kind to CATEGORY'
    task country_to_category: :environment do
      EventScope
        .where(kind: 'country')
        .update_all(kind: EventScope::CATEGORY)
    end
  end
end
