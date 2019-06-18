# frozen_string_literal: true

class TicketAcceptanceConsumer < Bunny::Consumer
  def handle_cancellation(_params)
    restore_queue
  end

  private

  def restore_queue
    @channel.close
    routing_key = ENV['MTS_MQ_TICKET_CONFIRMATION_RK']

    channel = Mts::Session
              .instance
              .opened_connection
              .create_channel

    queue = channel.queue(ENV['MTS_MQ_QUEUE_CONFIRM'], durable: true)
    queue.bind(ENV['MTS_MQ_USER'] + '-Confirm', routing_key: routing_key)
    channel.close

    Listeners::TicketAcceptanceListener.instance.listen
  end
end
