# frozen_string_literal: true

module Payments
  module Fiat
    module Handlers
      class DepositCallbackHandler < ::ApplicationService
        delegate :origin, to: :entry_request, prefix: true
        delegate :customer_bonus, to: :entry_request_origin

        def initialize(response)
          @response = response
        end

        protected

        attr_reader :response

        def request_id
          raise NotImplementedError, 'Implement #request_id method!'
        end

        def entry_request
          @entry_request ||= ::EntryRequest.find(request_id)
        end

        def fail_related_entities
          customer_bonus&.fail!
          entry_request&.origin&.failed!
        end

        def ga
          GaTracker.new(ENV['GA_TRACKER_ID'], ga_base_options)
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
            value: amount
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
