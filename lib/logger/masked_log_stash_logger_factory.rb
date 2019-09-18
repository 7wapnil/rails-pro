# frozen_string_literal: true

class MaskedLogStashLoggerFactory
  def self.build(params)
    customize_event = ->(event) do
      ::SensitiveDataFilter.filter(event)
      params[:customize_event]&.call(params)
    end
    logger_class = params.fetch(:logger_class) { Rails.logger.class }

    ::LogStashLogger.new(
      params.merge(customize_event: customize_event, logger_class: logger_class)
    )
  end
end
