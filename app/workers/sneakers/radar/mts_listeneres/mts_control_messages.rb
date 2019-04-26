# frozen_string_literal: true

module Radar
  module MtsListeners
    class MtsControlMessages
      include Sneakers::Worker

      EXCHANGE_NAME = 'arcanebet_arcanebet-Reply'

      from_queue ENV['MTS_MQ_QUEUE_REPLY'],
                 connection: Mts::Session.instance.connection,
                 exchange: EXCHANGE_NAME,
                 exchange_options: {
                   type: :topic,
                   exclusive: true
                 },
                 queue_options: {
                   durable: true,
                   routing_key: ENV['MTS_MQ_TICKET_CANCELLATION_RK']
                 },
                 ack: true,
                 heartbeat: 30,
                 amqp_heartbeat: 30

      def work(deserialized_msg)
        Rails.logger.debug deserialized_msg

        ::Mts::CancellationResponseWorker.perform_async(deserialized_msg)

        ack!
      end
    end
  end
end
