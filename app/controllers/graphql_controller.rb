# frozen_string_literal: true

class GraphqlController < ApiController
  include AppSignal::GraphqlExtensions

  protect_from_forgery with: :null_session

  respond_to :json

  def execute # rubocop:disable Metrics/MethodLength
    operation_name = params[:operationName]
    variables = ensure_hash(params[:variables])
    query = params[:query]
    context = {
      current_customer: current_customer,
      impersonated_by: impersonated_by,
      request: request
    }
    result = ArcanebetSchema.execute(
      query,
      variables: variables,
      context: context,
      operation_name: operation_name
    )

    render json: result
  rescue StandardError => e
    Rails.logger.error(error_object: e)
    render json: { message: 'Something went wrong' }, status: 500
  ensure
    set_action_name(operation_name, self.class.name)
  end

  private

  # Handle form data, JSON body, or a blank value
  def ensure_hash(ambiguous_param) # rubocop:disable Metrics/MethodLength
    case ambiguous_param
    when String
      if ambiguous_param.present?
        ensure_hash(JSON.parse(ambiguous_param))
      else
        {}
      end
    when Hash, ActionController::Parameters
      ambiguous_param
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    end
  end
end
