namespace :dev do
  desc 'Sample data for local development environment'
  task prime: 'db:setup' do
    require Rails.root.join('db', 'prime.rb')
  end
end
