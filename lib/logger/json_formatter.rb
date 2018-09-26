class JsonFormatter < ActiveSupport::Logger::Formatter
  def call(severity, timestamp, _progname, message)
    {
      type: severity,
      time: timestamp,
      message: message
    }.to_json
  end
end
