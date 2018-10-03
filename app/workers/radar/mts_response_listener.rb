module Radar
  class MtsResponseListener
    include Sneakers::Worker
    MTS_CONFIMRATION_EXCHANGE_NAME = 'arcanebet_arcanebet-Confirm'.freeze
    MTS_CONFIRMATION_EXCHANGE_ROUTING_KEY =
      'rk_for_arcanebet_arcanebet-Confirm_ruby_created_queue'.freeze
    MTS_QUEUE_NAME = 'arcanebet_arcanebet-Confirm_ruby_created_queue'.freeze

    from_queue MTS_QUEUE_NAME,
               connection: Mts::SingleSession.instance.session.connection,
               env: nil,
               exchange: MTS_CONFIMRATION_EXCHANGE_NAME,
               exchange_options: {
                 type: :topic,
                 arguments: {
                   routing_key: MTS_CONFIRMATION_EXCHANGE_ROUTING_KEY
                 }
               },
               queue_options: {
                 durable: false
               }

    def work(msg)
      puts "Received #{msg}"
    end
  end
end
