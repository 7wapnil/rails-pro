Airbrake.configure do |config|
  config.host = 'https://arcanebet-errbit.herokuapp.com'
  config.project_id = 1
  config.project_key = ENV['ERRBIT_PROJECT_KEY']

  config.environment = Rails.env
  config.ignore_environments = %w[development test]
end

Airbrake.add_filter do |notice|
  if notice[:errors].any? do |error|
       error[:type] == 'SignalException' && error[:message] == 'SIGTERM'
     end
    notice.ignore!
  end
end
