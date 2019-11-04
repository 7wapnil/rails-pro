# frozen_string_literal: true

module OddsFeed
  module Radar
    module Producers
      module Recoverable
        protected

        def producer
          raise NotImplementedError, 'Method #producer has to be implemented'
        end

        def requested_at
          raise NotImplementedError,
                'Method #requested_at has to be implemented'
        end

        def accept_message_with_recovery
          return skip_recovery! if ::Radar::Producer.recovery_disabled?

          request_recovery && accept_message
        end

        def skip_recovery!
          producer.skip_recovery!(requested_at: requested_at)
        end

        def request_recovery
          OddsFeed::Radar::Producers::RequestRecovery.call(producer: producer)
        end

        def accept_message
          producer.update(last_subscribed_at: requested_at)
        end
      end
    end
  end
end
