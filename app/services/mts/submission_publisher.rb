module Mts
  class SubmissionPublisher
    SUBMISSION_EXCHANGE_NAME = 'arcanebet_arcanebet-Submit'.freeze
    NONPERSISTENT_MODE = 1

    def initialize(message)
      @message = message
    end

    def self.publish!(message)
      new(message).publish!
    end

    def publish!
      ::Mts::SingleSession.instance.session.within_connection do |conn|
        create_exchange(conn)
          .publish(
            formatted_message,
            content_type: 'application/json',
            delivery_mode: NONPERSISTENT_MODE,
            headers: {
              'replyRoutingKey':
                Radar::MtsResponseListener::
                    MTS_CONFIRMATION_EXCHANGE_ROUTING_KEY
            }
          )
      end
    end

    private

    def create_exchange(conn)
      conn
        .create_channel
        .exchange(SUBMISSION_EXCHANGE_NAME,
                  type: :fanout,
                  durable: true)
    end

    def formatted_message
      @message.to_formatted_hash.to_json
    end
  end
end