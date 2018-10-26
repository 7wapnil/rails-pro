Sidekiq::Logging.logger = ::LogStashLogger.new(type: :stdout)

LogStashLogger.configure do |config|
  config.customize_event do |event|
    SensitiveDataFilter.filter(event)
  end
end
