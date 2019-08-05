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
      end
    end
  end
end
