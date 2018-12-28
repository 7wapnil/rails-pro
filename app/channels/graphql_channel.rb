class GraphqlChannel < ApplicationCable::Channel
  def subscribed
    @subscription_ids = []
  end

  def execute(data)
    context = { current_user: nil, channel: self }
    result = result(data, context)

    payload = {
      result: result.subscription? ? { data: nil } : result.to_h,
      more: result.subscription?
    }

    if result.context[:subscription_id]
      @subscription_ids << context[:subscription_id]
    end

    transmit(payload)
  end

  def unsubscribed
    @subscription_ids.each do |sid|
      schema.subscriptions.delete_subscription(sid)
    end
  end

  private

  def result(data, context)
    query = data['query']
    variables = ensure_hash(data['variables'])
    operation_name = data['operationName']

    schema.execute(query: query,
                   context: context,
                   variables: variables,
                   operation_name: operation_name)
  end

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
