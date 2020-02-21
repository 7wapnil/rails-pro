# frozen_string_literal: true

module Payments
  module Crypto
    module Handlers
      class DepositCallbackHandler < ::ApplicationService
        delegate :origin, to: :entry_request, prefix: true

        def initialize(response)
          @response = response
        end

        protected

        attr_reader :response

        def entry_request
          raise NotImplementedError, 'Implement #entry_request method!'
        end

        def fail_related_entities
          customer_bonus&.fail!
          entry_request&.origin&.failed!
        end

        def ga_client
          GaTracker.new(ENV['GA_TRACKER_ID'], client_id, ga_base_options)
        end

        def client_id
          entry_request.customer.customer_data&.ga_client_id
        end

        def ga_base_options
          {
            user_id: entry_request.customer.id,
            user_ip: entry_request.customer.last_visit_ip.to_s
          }
        end

        def deposit_success(amount)
          {
            category: 'Payment',
            action: 'depositSuccesful',
            label: entry_request.customer.id,
            value: (amount * 100).to_i
          }
        end

        def deposit_failure(_reason)
          {
            category: 'Payment',
            action: 'depositFailed',
            label: entry_request.customer.id
            # NOTE: can't really do that because value should be numeric
            # value: reason
          }
        end
      end
    end
  end
end
