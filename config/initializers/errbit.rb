Airbrake.configure do |config|
  config.host = 'https://arcanebet-errbit.herokuapp.com'
  config.project_id = 1
  config.project_key = ENV['ERRBIT_PROJECT_KEY']

  config.environment = ENV['ERRBIT_ENV'] || Rails.env
  config.ignore_environments = %w[development test]
end

runtime_error_message_pattern =
  %r{middleware/debug_exceptions\.rb|ActionController::RoutingError}
ignored_errors = %w[SilentRetryJobError]

filter = lambda do |error|
  error[:message].to_s.strip.blank? ||
    ignored_errors.include?(error[:type]) ||
    (error[:type] == 'RuntimeError' &&
     error[:message].match?(runtime_error_message_pattern)) ||
    (error[:type] == 'SignalException' && error[:message] == 'SIGTERM')
end

Airbrake.add_filter do |notice|
  notice.ignore! if notice[:errors].any?(filter)
end
