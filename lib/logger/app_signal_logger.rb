# frozen_string_literal: true

class AppSignalLogger < Logger
  def add(severity, message = nil, progname = nil)
    super

    message = block_given? ? yield : progname
    notify(message) if severity >= Severity::ERROR

    true
  end

  private

  def notify(message)
    return if message[:error_object].blank?

    Appsignal.set_error(message.delete(:error_object), message)
  end
end
