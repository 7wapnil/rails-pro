# frozen_string_literal: true

class CustomLogger < Logger
  APPSIGNAL_ENABLED_ENVIRONMENTS = %w[production staging].freeze

  def add(severity, message = nil, progname = nil)
    super

    message = block_given? ? yield : progname
    notify(message) if appsignal_enabled? && severity >= Severity::ERROR

    true
  end

  private

  def appsignal_enabled?
    # APPSIGNAL_ENABLED_ENVIRONMENTS.include?(ENV['APPSIGNAL_APP_ENV'])

    true
  end

  def notify(message)
    return if message[:error_object].blank?

    Appsignal.set_error(message.delete(:error_object), message)
  end
end
