module Graphql
  # rubocop:disable Metrics/LineLength
  class ArcanebetSubscriptions < GraphQL::Subscriptions::ActionCableSubscriptions
    # rubocop:enable Metrics/LineLength

    def initialize(serializer: Graphql::Serializer, **rest)
      super
    end

    def trigger(event_name, args, object, scope: nil)
      super
    end

    def deliver(subscription_id, result)
      # TODO: Decide on what to send to front-end
      payload = { result: result.to_h,
                  more: true }
      ActionCable.server.broadcast(SUBSCRIPTION_PREFIX + subscription_id,
                                   payload)
    end
  end
end
