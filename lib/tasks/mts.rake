# frozen_string_literal: true

namespace :mts do
  desc 'creates all necessary queues for MTS'
  namespace :ticket_confirmation do
    desc 'creates queue and bind it to exchange'
    task create: :environment do
      raise 'No queue name provided' unless ENV['MTS_MQ_QUEUE_CONFIRM']

      routing_key = ENV['MTS_MQ_TICKET_CONFIRMATION_RK'] || 'ticket.confirm.dev'

      channel = ::Mts::SingleSession
                .instance
                .session
                .opened_connection
                .create_channel

      status = channel
               .queue(ENV['MTS_MQ_QUEUE_CONFIRM'], durable: true)
               .bind(ENV['MTS_MQ_USER'] + '-Submit',
                     routing_key: routing_key)

      raise 'Failure!' unless status

      puts 'Success!'
    end
  end

  namespace :ticket_cancellation do
    desc 'creates queue and bind it to exchange'
    task create: :environment do
      raise 'No queue name provided' unless ENV['MTS_MQ_QUEUE_REPLY']

      routing_key = ENV['MTS_MQ_TICKET_CANCELLATION_RK'] || 'cancel.confirm.dev'

      channel = ::Mts::SingleSession
                .instance
                .session
                .opened_connection
                .create_channel

      status = channel
               .queue(ENV['MTS_MQ_QUEUE_REPLY'], durable: true)
               .bind(ENV['MTS_MQ_USER'] + '-Reply',
                     routing_key: routing_key)

      raise 'Failure!' unless status

      puts 'Success!'
    end
  end
end
