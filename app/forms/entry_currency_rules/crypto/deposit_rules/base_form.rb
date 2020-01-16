# frozen_string_literal: true

module EntryCurrencyRules
  module Crypto
    module DepositRules
      class BaseForm
        include ActiveModel::Model
        include Currencies::Crypto

        attr_accessor :currency, :params

        def validate
          raise NotImplementedError, "Define ##{__method__}!"
        end
      end
    end
  end
end
