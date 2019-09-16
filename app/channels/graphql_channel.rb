# Be sure to restart your server when you modify this file.
# Action Cable runs in a loop that does not support auto reloading.
class GraphqlChannel < ApplicationCable::Channel
  include AppSignal::GraphqlExtensions

  def subscribed
    @subscription_ids = []
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def execute(data)
    operation_name = data['operationName']
    set_action_name(operation_name, self.class.name)

    query = data['query']
    variables = ensure_hash(data['variables'])

    context = {
      current_customer: customer,
      customer_id: customer&.id,
      impersonated_by: impersonated_by,
      channel: self
    }

    result = schema.execute(
      query: query,
      context: context,
      variables: variables,
      operation_name: operation_name
    )

    payload = {
      result: result.subscription? ? { data: nil } : result.to_h,
      more: result.subscription?
    }

    # Track the subscription here so we can remove it
    # on unsubscribe.

    Rails.logger.debug "Subscription: #{result.context[:subscription_id]}"
    if result.context[:subscription_id]
      @subscription_ids << context[:subscription_id]
    end

    transmit(payload)
  rescue StandardError => e
    Rails.logger.error(error_object: e)
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def unsubscribed
    @subscription_ids.each do |sid|
      schema.subscriptions.delete_subscription(sid)
    end
  end

  private

  def schema
    ArcanebetSchema
  end

  # rubocop:disable Metrics/MethodLength
  #
  # TODO: we are facing too often with this issue. It would be nice
  # to place it in some helper class
  def ensure_hash(ambiguous_param)
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
  # rubocop:enable Metrics/MethodLength
end
