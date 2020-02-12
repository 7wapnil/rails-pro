# frozen_string_literal: true

module Payments
  module Fiat
    module Wirecard
      module Validations
        class CustomerValidationHandler < ApplicationService
          include ::Payments::Methods

          def initialize(transaction)
            @transaction = transaction
          end

          def call
            true
          end
        end
      end
    end
  end
end
