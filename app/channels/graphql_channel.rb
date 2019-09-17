# Be sure to restart your server when you modify this file.
# Action Cable runs in a loop that does not support auto reloading.
class GraphqlChannel < ApplicationCable::Channel
  include AppSignal::GraphqlExtensions

  def subscribed
    @subscription_ids = []
  end

  def execute(data)
    set_action_name(data['operationName'], self.class.name)

    result = execute_graphql_query(data)
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

  def unsubscribed
    @subscription_ids
      .each { |sid| ArcanebetSchema.subscriptions.delete_subscription(sid) }
  end

  private

  def execute_graphql_query(data)
    ArcanebetSchema.execute(
      query: data['query'],
      operation_name: data['operationName'],
      variables: ensure_hash(data['variables']),
      context: context
    )
  end

  # TODO: we are facing too often with this issue. It would be nice
  # to place it in some helper class
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
      current_customer: customer,
      customer_id: customer&.id,
      impersonated_by: impersonated_by,
      channel: self
    }
  end
end
