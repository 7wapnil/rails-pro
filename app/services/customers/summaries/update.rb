# frozen_string_literal: true

module Customers
  module Summaries
    class Update < ApplicationService
      INCREMENT_ATTRIBUTES = %i[bonus_payout_amount
                                real_money_payout_amount
                                casino_bonus_payout_amount
                                casino_real_money_payout_amount
                                bonus_deposit_amount
                                real_money_deposit_amount
                                withdraw_amount
                                signups_count].freeze
      NEGATIVE_INCREMENT_ATTRIBUTES = %i[bonus_wager_amount
                                         real_money_wager_amount
                                         casino_bonus_wager_amount
                                         casino_real_money_wager_amount].freeze
      APPEND_ATTRIBUTES = %i[betting_customer_ids
                             casino_customer_ids].freeze

      def initialize(summary, attributes)
        @summary = summary
        @attributes = attributes
      end

      def call
        summary.update!(new_attributes)
      end

      private

      attr_reader :summary, :attributes

      def new_attributes
        attributes
          .symbolize_keys
          .reduce({}, &method(:collect_attribute))
      end

      def collect_attribute(hash, (key, value))
        new_value = collect_new_attribute_value!(key, value)

        hash.merge(key => new_value)
      rescue NotImplementedError => error
        Rails.logger.error(
          message: 'Attribute is not supported for customer summary',
          key: key,
          error_object: error
        )

        hash
      end

      def collect_new_attribute_value!(key, value)
        case key.to_sym
        when *INCREMENT_ATTRIBUTES
          summary.public_send(key) + value
        when *NEGATIVE_INCREMENT_ATTRIBUTES
          summary.public_send(key) + value.abs
        when *APPEND_ATTRIBUTES
          summary.public_send(key).to_a.append(value)
        else
          raise NotImplementedError, "#{key} is not supported"
        end
      end
    end
  end
end
