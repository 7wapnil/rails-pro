Airbrake.configure do |config|
  config.host = 'https://arcanebet-errbit.herokuapp.com'
  config.project_id = 1
  config.project_key = ENV['ERRBIT_PROJECT_KEY']

  config.environment = Rails.env
  config.ignore_environments = %w[development test]
  config.ignore << 'ActiveRecord::IgnoreThisError'
end
