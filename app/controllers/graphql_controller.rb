# frozen_string_literal: true

class GraphqlController < ApiController
  include AppSignal::GraphqlExtensions

  protect_from_forgery with: :null_session

  respond_to :json

  def execute
    result = ArcanebetSchema.execute(
      params[:query],
      operation_name: params[:operationName],
      variables: ensure_hash(params[:variables]),
      context: context
    )

    render json: result
  rescue StandardError => e
    Rails.logger.error(error_object: e)
    render json: { message: I18n.t('graphql.internal_server_error') },
           status: :internal_server_error
  ensure
    set_action_name(params[:operationName], self.class.name)
  end

  private

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
end
