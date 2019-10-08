# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    class Daemon
      RESTART_DELAY = 3

      class << self
        def start
          Rails.logger.info('Connecting to EveryMatrix mix data feed...')

          EveryMatrix::MixDataFeed::Listener
            .new(connection_state: connection_state)
            .listen

          raise EveryMatrix::ConnectionClosedError, 'HTTP request delivered'
        rescue EveryMatrix::ConnectionClosedError => error
          connection_dead! { log_connection_loss(error) }
          retry
        rescue StandardError => error
          connection_dead! { log_system_error(error) }
          retry
        end

        private

        def connection_state
          @connection_state ||= EveryMatrix::Connection.instance
        end

        def connection_dead!
          kill_connection_state!

          yield

          sleep(RESTART_DELAY)
        end

        def kill_connection_state!
          connection_state.with_lock { connection_state.dead! }
        end

        def log_connection_loss(error)
          Rails.logger.error(
            message: 'Connection to EveryMatrix mix data feed lost',
            reason: error.message,
            error_object: error
          )
        end

        def log_system_error(error)
          message = 'Connection to EveryMatrix mix data feed lost because ' \
                    'of technical issues'

          Rails.logger.error(
            message: message,
            reason: error.message,
            error_object: error
          )
        end
      end
    end
  end
end
