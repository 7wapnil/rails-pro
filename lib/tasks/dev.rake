namespace :dev do
  desc 'Populates database with sample data for local development environment'
  task prime: :environment do
    Rake::Task['dev:prime:customers'].invoke
  end

  namespace :prime do
    desc 'Populates database with sample customers'
    task customers: :environment do
      require Rails.root.join('db/prime/customers')
    end
  end
end
