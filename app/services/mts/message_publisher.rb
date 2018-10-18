module Mts
  class SubmissionPublisher
    MTS_SUBMISSION_EXCHANGE_NAME = 'arcanebet_arcanebet-Submit'.freeze

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
            persistent: false,
            headers: {
              'replyRoutingKey': ENV['MTS_MQ_ROUTING_KEY']
            }
          )
      end
    end

    private

    def create_exchange(conn)
      conn
        .create_channel
        .exchange(MTS_SUBMISSION_EXCHANGE_NAME,
                  type: :fanout,
                  durable: true)
    end

    def formatted_message
      @message.to_formatted_hash.to_json
    end
  end
end
