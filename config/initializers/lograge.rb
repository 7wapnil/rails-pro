Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Logstash.new

  config.lograge.ignore_actions = [
    'HealthChecksController#show',
    # uncomment after making shortened version of logs work
    # Webhooks::CoinsPaid::PaymentsController#create
    # Webhooks::SafeCharge::PaymentsController#create
    # Webhooks::SafeCharge::PaymentsController#show
    # Webhooks::SafeCharge::CancelledPaymentsController#show
    # Webhooks::Wirecard::PaymentsController#create
  ]

  config.lograge.custom_payload do |controller|
    unwanted_params = %w[action authenticity_token controller commit utf8]

    logging_params = controller.request.filtered_parameters.reject do |k, _|
      unwanted_params.include?(k)
    end

    params = { ip: controller.request.remote_ip,
               params: logging_params }

    if controller.respond_to?(:current_user)
      params[:user_id] = controller.current_user&.id
    end

    if controller.respond_to?(:current_customer)
      params[:customer_id] = controller.current_customer&.id
    end

    params
  end
end
