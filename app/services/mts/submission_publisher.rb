module Mts
  class SubmissionPublisher
    SUBMISSION_EXCHANGE_NAME = 'arcanebet_arcanebet-Submit'.freeze
    REPLY_KEY = 'rk_for_arcanebet_arcanebet-Confirm_ruby_created_queue'.freeze
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
            headers: { 'replyRoutingKey': REPLY_KEY }
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
