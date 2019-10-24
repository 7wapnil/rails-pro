# frozen_string_literal: true

class GraphqlController < ApiController
  include AppSignal::GraphqlExtensions
  include Cacheable

  protect_from_forgery with: :null_session

  respond_to :json

  LOGIN_REGEXP    = /"login":"([^"]*)"/
  PASSWORD_REGEXP = /"password":"([^"]*)"/

  def process_action(*args)
    super
  rescue ActionDispatch::Http::Parameters::ParseError => e
    log_params_parsing_error(e)
    render json: { message: I18n.t('graphql.internal_server_error') },
           status: :internal_server_error
  end

  def execute
    result = cache_if_enabled do
      ArcanebetSchema.execute(schema_params)
    end

    render json: result
  rescue StandardError => e
    Rails.logger.error(error_object: e)
    render json: { message: I18n.t('graphql.internal_server_error') },
           status: :internal_server_error
  ensure
    set_action_name(params[:operationName], self.class.name)
  end

  private

  def schema_params
    {
      document: document,
      operation_name: params[:operationName],
      variables: ensure_hash(params[:variables]),
      context: context
    }
  end

  def document
    GraphQL.parse(params[:query])
  end

  # Handle form data, JSON body, or a blank value
  def ensure_hash(ambiguous_param)
    case ambiguous_param
    when String
      ambiguous_param.present? ? ensure_hash(JSON.parse(ambiguous_param)) : {}
    when Hash, ActionController::Parameters
      ambiguous_param
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    end
  end

  def context
    {
      current_customer: current_customer,
      impersonated_by: impersonated_by,
      request: request
    }
  end

  def log_params_parsing_error(error_object)
    ip            = request.env['HTTP_X_FORWARDED_FOR'] || request.remote_ip
    user_agent    = request.headers['User-Agent']
    raw_post_data = request.env['RAW_POST_DATA']
    login         = raw_post_data.match(LOGIN_REGEXP)&.[](1)
    password      = raw_post_data.match(PASSWORD_REGEXP)&.[](1)

    Rails.logger.error(
      ip: ip,
      user_agent: user_agent,
      raw_post_data: raw_post_data,
      login: login,
      password: password,
      error_object: error_object
    )
  end
end
