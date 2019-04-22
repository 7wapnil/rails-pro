# frozen_string_literal: true

module Radar
  module MtsListeners
    class MtsTicketAcceptance
      include Sneakers::Worker

      EXCHANGE_NAME = 'arcanebet_arcanebet-Confirm'

      from_queue ENV['MTS_MQ_QUEUE_CONFIRM'],
                 connection: Mts::Session.session.connection,
                 exchange: EXCHANGE_NAME,
                 exchange_options: {
                   type: :topic,
                   exclusive: true
                 },
                 queue_options: {
                   durable: true,
                   routing_key: ENV['MTS_MQ_TICKET_CONFIRMATION_RK']
                 },
                 ack: true,
                 heartbeat: 30,
                 amqp_heartbeat: 30

      def work(deserialized_msg)
        Rails.logger.debug deserialized_msg

        ::Mts::ValidationResponseWorker.perform_async(deserialized_msg)

        ack!
      end
    end
  end
end
