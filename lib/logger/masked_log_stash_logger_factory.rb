class MaskedLogStashLoggerFactory
  def self.build(params)
    passed_filter = params[:customize_event]

    params[:customize_event] =
      ->(event) do
        ::SensitiveDataFilter.filter(event)
        passed_filter.call(params) if passed_filter
      end
    params[:logger_class] = Rails.logger.class
    ::LogStashLogger.new(params)
  end
end
