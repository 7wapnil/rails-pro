# frozen_string_literal: true

module Listeners
  class TicketCancellationListener
    include Singleton
    include JobLogger

    BATCH_SIZE = 10

    def listen # rubocop:disable Metrics/MethodLength
      ch = Mts::Session.instance.opened_connection.create_channel
      ch.prefetch(BATCH_SIZE)

      queue = ch.queue(ENV['MTS_MQ_QUEUE_REPLY'], durable: true)

      consumer = TicketCancellationConsumer
                 .new(ch,
                      queue,
                      ENV['MTS_MQ_USER'] + '.reply-consumer',
                      false,
                      true)

      consumer.on_delivery do |delivery_info, _metadata, payload|
        Rails.logger.debug payload
        log_job_message(:debug, message: 'Cancellation ticket received',
                                id: JSON.parse(payload)['result']['ticketId'])
        ::Mts::CancellationResponseWorker.perform_async(payload)

        ch.ack(delivery_info.delivery_tag)
      end

      queue.subscribe_with(consumer)
    end
  end
end
