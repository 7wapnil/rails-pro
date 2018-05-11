namespace :dev do
  desc 'Sample data for local development environment'
  task :prime do
    require Rails.root.join('config', 'environment.rb')
    require Rails.root.join('db', 'prime.rb')
  end
end
