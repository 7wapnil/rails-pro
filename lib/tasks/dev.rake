namespace :dev do
  desc 'Populates database with sample data for local development environment'
  task prime: :environment do
    Rake::Task['dev:prime:csgo'].invoke
    Rake::Task['dev:prime:customers'].invoke
    Rake::Task['dev:prime:entries'].invoke
  end

  namespace :prime do
    desc 'Populates database with sample CSGO events'
    task csgo: :environment do
      require Rails.root.join('db/prime/csgo')
    end

    desc 'Populates database with sample customers'
    task customers: :environment do
      require Rails.root.join('db/prime/customers')
    end

    desc 'Populates database with sample trading entries'
    task entries: :environment do
      require Rails.root.join('db/prime/entries')
    end
  end
end
