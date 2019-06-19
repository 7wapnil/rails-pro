# frozen_string_literal: true

module Listeners
  class TicketAcceptanceListener
    include Singleton

    BATCH_SIZE = 10

    def listen # rubocop:disable Metrics/MethodLength
      ch = Mts::Session.instance.opened_connection.create_channel
      ch.prefetch(BATCH_SIZE)

      queue = ch.queue(ENV['MTS_MQ_QUEUE_CONFIRM'], durable: true)
      consumer = TicketAcceptanceConsumer
                 .new(ch,
                      queue,
                      ENV['MTS_MQ_USER'] + '.confirm-consumer',
                      false,
                      true)

      consumer.on_delivery do |delivery_info, _metadata, payload|
        Rails.logger.debug payload
        ::Mts::ValidationResponseWorker.perform_async(payload)

        ch.ack(delivery_info.delivery_tag)
      end

      queue.subscribe_with(consumer)
    end
  end
end
