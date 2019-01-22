Airbrake.configure do |config|
  config.host = 'https://arcanebet-errbit.herokuapp.com'
  config.project_id = 1
  config.project_key = ENV['ERRBIT_PROJECT_KEY']

  config.environment = Rails.env
  config.ignore_environments = %w[development test]
end

filter = lambda do |error|
  error[:message].to_s.strip.blank? ||
    (error[:type] == 'RuntimeError' &&
     error[:message].match?(%r{middleware/debug_exceptions.rb})) ||
    # (error[:type] == 'RuntimeError' &&
    #   error[:message].match?(/ActionController::RoutingError/)) ||
    (error[:type] == 'SignalException' && error[:message] == 'SIGTERM')
end

Airbrake.add_filter do |notice|
  notice.ignore! if notice[:errors].any?(filter)
end

