# frozen_string_literal: true

module Listeners
  class TicketAcceptanceListener
    include Singleton

    def listen
      ch = Mts::Session.instance.opened_connection.create_channel
      queue = ch.queue(ENV['MTS_MQ_QUEUE_CONFIRM'], durable: true)

      consumer = TicketAcceptanceConsumer.new(ch, queue, '', false, true)

      consumer.on_delivery do |delivery_info, _metadata, payload|
        Rails.logger.debug payload
        ::Mts::ValidationResponseWorker.perform_async(payload)
        ch.acknowledge(delivery_info.delivery_tag, false)
      end

      queue.subscribe_with(consumer)
    end
  end
end
