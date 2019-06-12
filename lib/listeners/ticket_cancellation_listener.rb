# frozen_string_literal: true

module Listeners
  class TicketCancellationListener
    include Singleton

    def listen
      ch = Mts::Session.instance.opened_connection.create_channel(nil, 3)
      queue = ch.queue(ENV['MTS_MQ_QUEUE_REPLY'], durable: true)

      consumer = TicketCancellationConsumer.new(ch, queue)

      consumer.on_delivery do |_delivery_info, _metadata, payload|
        Rails.logger.debug payload
        ::Mts::ValidationResponseWorker.perform_async(payload)
      end

      queue.subscribe_with(consumer)
    end
  end
end
