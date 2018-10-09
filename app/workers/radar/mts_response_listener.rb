module Radar
  class MtsResponseListener
    include Sneakers::Worker
    MTS_CONFIRMATION_EXCHANGE_NAME = 'arcanebet_arcanebet-Confirm'.freeze

    from_queue ENV['MTS_MQ_QUEUE_NAME'],
               connection: Mts::SingleSession.instance.session.connection,
               exchange: MTS_CONFIRMATION_EXCHANGE_NAME,
               exchange_options: {
                 type: :topic,
                 exclusive: true
               },
               queue_options: {
                 durable: true,
                 routing_key: ENV['MTS_MQ_ROUTING_KEY']
               },
               ack: true,
               heartbeat: 30,
               amqp_heartbeat: 30

    def work(deserialized_msg)
      Rails.logger.debug deserialized_msg
      ack!
    end
  end
end
