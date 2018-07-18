Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new

  config.lograge.ignore_actions = %w[HealthChecksController#show]

  config.lograge.custom_payload do |controller|
    unwanted_params = %w[action authenticity_token controller commit utf8]

    logging_params = controller.request.filtered_parameters.reject do |k, _|
      unwanted_params.include?(k)
    end

    {
      ip: controller.request.remote_ip,
      params: logging_params,
      user_id: controller.current_user&.id,
      customer_id: controller.current_customer&.id
    }
  end
end
